#lang racket

(provide best-sell-price
         best-buy-price
         order-spread
         profitable-spread?
         order-quantity
         side-depth
         score-spread)

(define (order-price order)
  (hash-ref order 'price +inf.0))

(define (order-quantity order)
  (or (hash-ref order 'quantity #f)
      (hash-ref order 'amount #f)
      1))

(define (best-sell-price sell-orders)
  (and (pair? sell-orders)
       (order-price (argmin order-price sell-orders))))

(define (best-buy-price buy-orders)
  (and (pair? buy-orders)
       (order-price (argmax order-price buy-orders))))

(define (order-spread buy-orders sell-orders)
  (define buy (best-buy-price buy-orders))
  (define sell (best-sell-price sell-orders))
  (and buy sell (- buy sell)))

(define (profitable-spread? buy-orders sell-orders #:minimum-margin [minimum-margin 1])
  (define spread (order-spread buy-orders sell-orders))
  (and spread (>= spread minimum-margin)))

(define (side-depth orders)
  (for/sum ([o orders] #:when (hash? o))
    (define q (order-quantity o))
    (if (number? q) q 0)))

;; Score in [0,1]: spread strength + thin-book bonus when both sides have depth.
(define (score-spread buy-orders sell-orders #:spread-scale [spread-scale 20.0])
  (define spread (order-spread buy-orders sell-orders))
  (and spread
       (> spread 0)
       (let* ([buy-depth (side-depth buy-orders)]
              [sell-depth (side-depth sell-orders)]
              [depth (min buy-depth sell-depth)]
              [spread-part (min 1.0 (/ (abs spread) spread-scale))]
              [depth-part (min 0.25 (/ (log (add1 (max 0 depth))) 10.0))]
              [raw (+ (* 0.85 spread-part) depth-part)])
         (min 1.0 raw))))
