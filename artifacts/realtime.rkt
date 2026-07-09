#lang racket

;; Optional Artifacts realtime WebSocket ingest (future).
;; REST session polling is the supported live path today.
;; This module exists so hub/session can later merge realtime events
;; without bots depending on Godot.

(require "config.rkt")

(provide realtime-enabled?
         realtime-url
         start-realtime-ingest!
         stop-realtime-ingest!)

(define ingest-thread #f)

(define (realtime-enabled?)
  (define v (getenv "ARTIFACTS_REALTIME"))
  (and v (member v '("1" "true" "TRUE" "yes" "YES")) #t))

(define (realtime-url #:config [config (current-config)])
  (artifacts-config-realtime-url config))

(define (start-realtime-ingest! #:config [config (current-config)]
                                #:on-message [on-message #f])
  (cond
    [(not (realtime-enabled?))
     (printf "Realtime ingest disabled (set ARTIFACTS_REALTIME=1 to enable later).\\n")
     (flush-output)
     #f]
    [ingest-thread
     #t]
    [else
     ;; Placeholder: do not open a live socket until protocol framing is finalized.
     (printf "Realtime ingest stub ready for ~a (not connected yet).\\n"
             (realtime-url #:config config))
     (flush-output)
     (set! ingest-thread #t)
     #t]))

(define (stop-realtime-ingest!)
  (set! ingest-thread #f)
  (void))
