#lang racket

;; Optional local WebSocket hub for the Godot visualizer.
;; Bots never depend on Godot. If no client is connected, publishes are no-ops.

(require json
         net/rfc6455
         racket/async-channel
         racket/set)

(provide visualizer-enabled?
         hub-alive?
         start-visualizer-hub!
         stop-visualizer-hub!
         visualizer-publish!
         make-protocol-message
         world-snapshot-message
         bot-decision-message
         market-signal-message
         summarize-maps-for-visualizer)

(define default-port 8787)

(define hub-thread #f)
(define hub-stopper #f)
(define hub-port #f)
(define clients (mutable-set))
(define clients-sema (make-semaphore 1))
(define publish-ch (make-async-channel))

(define (visualizer-enabled?)
  (define v (getenv "ARTIFACTS_VISUALIZER"))
  (cond
    [(not v) #t]
    [(member v '("0" "false" "FALSE" "no" "NO" "off" "OFF")) #f]
    [else #t]))

(define (iso-now)
  (define t (seconds->date (current-seconds) #f))
  (format "~a-~a-~aT~a:~a:~aZ"
          (date-year t)
          (~a (date-month t) #:width 2 #:pad-string "0" #:align 'right)
          (~a (date-day t) #:width 2 #:pad-string "0" #:align 'right)
          (~a (date-hour t) #:width 2 #:pad-string "0" #:align 'right)
          (~a (date-minute t) #:width 2 #:pad-string "0" #:align 'right)
          (~a (date-second t) #:width 2 #:pad-string "0" #:align 'right)))

(define (make-protocol-message type data)
  (hasheq 'type type
          'timestamp (iso-now)
          'data data))

(define (world-snapshot-message #:maps [maps '()]
                                #:characters [characters '()]
                                #:routes [routes '()]
                                #:events [events '()]
                                #:raids [raids '()])
  (make-protocol-message
   "world.snapshot"
   (hasheq 'maps maps
           'characters characters
           'routes routes
           'events events
           'raids raids)))

(define (bot-decision-message character action reason #:target [target #f])
  (define data
    (hasheq 'character character
            'action (if (symbol? action) (symbol->string action) (format "~a" action))
            'reason reason))
  (make-protocol-message
   "bot.decision"
   (if target (hash-set data 'target target) data)))

(define (market-signal-message code spread score #:x [x #f] #:y [y #f] #:layer [layer #f])
  (define data (hasheq 'code code 'spread spread 'score score))
  (define with-pos
    (cond
      [(and x y)
       (hash-set* data
                  'x x
                  'y y
                  'layer (or layer "overworld"))]
      [else data]))
  (make-protocol-message "market.signal" with-pos))

(define (summarize-maps-for-visualizer maps #:limit [limit 400])
  (define items (if (list? maps) maps '()))
  (for/list ([m items]
             [i (in-range limit)]
             #:when (hash? m))
    (define interactions (hash-ref m 'interactions #f))
    (define content (and (hash? interactions) (hash-ref interactions 'content #f)))
    (hasheq 'map_id (hash-ref m 'map_id #f)
            'layer (hash-ref m 'layer "overworld")
            'x (hash-ref m 'x 0)
            'y (hash-ref m 'y 0)
            'skin (hash-ref m 'skin "forest")
            'content_type (if (hash? content) (hash-ref content 'type "terrain") "terrain")
            'content_code (if (hash? content) (hash-ref content 'code "") "")
            'interactions (if interactions interactions #hasheq()))))

(define (with-clients thunk)
  (call-with-semaphore clients-sema thunk))

(define (add-client! c)
  (with-clients (lambda () (set-add! clients c))))

(define (remove-client! c)
  (with-clients (lambda () (set-remove! clients c))))

(define (snapshot-clients)
  (with-clients (lambda () (set->list clients))))

(define (connection-handler c _state)
  (add-client! c)
  (printf "Visualizer client connected (~a total).\n" (length (snapshot-clients)))
  (flush-output)
  (let loop ()
    (define msg (ws-recv c #:payload-type 'text))
    (cond
      [(eof-object? msg)
       (remove-client! c)
       (ws-close! c)
       (printf "Visualizer client disconnected (~a total).\n" (length (snapshot-clients)))
       (flush-output)]
      [else
       ;; Godot may send UI commands later; ignore for now.
       (loop)])))

(define (publisher-loop)
  (let loop ()
    (define payload (async-channel-get publish-ch))
    (unless (eq? payload 'stop)
      (define text (if (string? payload) payload (jsexpr->string payload)))
      (for ([c (snapshot-clients)])
        (with-handlers ([exn:fail?
                         (lambda (_exn)
                           (remove-client! c)
                           (with-handlers ([exn:fail? void])
                             (ws-close! c)))])
          (ws-send! c text)))
      (loop))))

(define (hub-alive?)
  (and hub-thread (thread-running? hub-thread)))

(define (start-visualizer-hub! #:port [port default-port]
                               #:enabled? [enabled? (visualizer-enabled?)])
  (cond
    [(not enabled?)
     (printf "Visualizer hub disabled (ARTIFACTS_VISUALIZER=0).\n")
     (flush-output)
     #f]
    [(hub-alive?)
     (printf "Visualizer hub already running on ~a.\n" (or hub-port port))
     (flush-output)
     #t]
    [else
     ;; Previous hub may have died; clear stale handles before retry.
     (when (or hub-thread hub-stopper)
       (with-handlers ([exn:fail? void])
         (stop-visualizer-hub!)))
     (with-handlers
         ([exn:fail?
           (lambda (exn)
             (printf "Visualizer hub not started: ~a\n" (exn-message exn))
             (printf "Bots continue without Godot.\n")
             (flush-output)
             #f)])
       (set! hub-stopper (ws-serve #:port port connection-handler))
       (set! hub-thread (thread publisher-loop))
       (set! hub-port port)
       (printf "Visualizer hub listening on ws://127.0.0.1:~a (optional).\n" port)
       (flush-output)
       #t)]))

(define (stop-visualizer-hub!)
  (when hub-thread
    (with-handlers ([exn:fail? void])
      (async-channel-put publish-ch 'stop))
    (set! hub-thread #f))
  (when hub-stopper
    (with-handlers ([exn:fail? void])
      (hub-stopper))
    (set! hub-stopper #f))
  (set! hub-port #f)
  (with-clients (lambda () (set-clear! clients)))
  (void))

(define (visualizer-publish! message)
  (when hub-thread
    (async-channel-put publish-ch message)))
