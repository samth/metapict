#lang racket/base
(require racket/contract racket/format racket/match
         "def.rkt" "structs.rkt")

;;;
;;; Domains (subsets of R)
;;;

; A domain interval represents an interval, a subset of the real number line
; of one of the following forms:
;    i)   a<x<b      open-open
;   ii)   a<=x<b   closed-open
;  iii)   a<x<=b     open-closed
;   iv)   a<=x<=b  closed-closed

; A domain consists of a list of intervals.
; The invariant is:
;   I)  the intervals doesn't overlap
;  II)  the intervals are sorted in ascending order


(define/contract (empty-domain-interval? I)
  (-> domain-interval? boolean?)
  (defm (domain-interval ac a b bc) I)
  (and (= a b) (not (and ac bc))))

(define/contract (interval-member? x I)
  (-> real? domain-interval?   boolean?)
  (defm (domain-interval ac a b bc) I)
  (or (< a x b)
      (and ac (= x a))
      (and bc (= x b))))


(module+ test
  'interval-member?
  (and (eq? (interval-member? 2 (domain-interval #f 1 3 #f)) #t)
       (eq? (interval-member? 1 (domain-interval #f 1 3 #f)) #f)
       (eq? (interval-member? 3 (domain-interval #f 1 3 #f)) #f)
       (eq? (interval-member? 1 (domain-interval #t 1 3 #f)) #t)
       (eq? (interval-member? 3 (domain-interval #f 1 3 #t)) #t)))

(define/contract (domain-member? x D)
  (-> real? domain?   boolean?)
  (for/or ([I (in-list (domain-intervals D))])
    (interval-member? x I)))

(module+ test
  'domain-member?
  (and (not (domain-member? 2 (domain (list))))
       (domain-member? 2 (domain (list (domain-interval #f 1 3 #f))))
       (domain-member? 4 (domain (list (domain-interval #f 1 3 #f) (domain-interval #f 3 5 #f))))
       (not (domain-member? 3 (domain
                               (list (domain-interval #f 1 3 #f) (domain-interval #f 3 5 #f)))))))

(define/contract (domain-interval-overlap? I1 I2)
  (-> domain-interval? domain-interval?   boolean?)
  (defm (domain-interval ac a b bc) I1)
  (defm (domain-interval xc x y yc) I2)
  (or (or (< x a y)
          (and ac (or (and xc (= a x))
                      (and yc (= a y)))))
      (or (< x b y)
          (and bc (or (and xc (= a x))
                      (and yc (= a y)))))
      (or (< a x b)
          (and xc (or (and ac (= x a))
                      (and bc (= x b)))))
      (or (< a y b)
          (and yc (or (and ac (= y a))
                      (and bc (= y b)))))
      (and (= a x) (= b y) (not (= a b)))))


(module+ test  'interval-overlap?
         (let ()
           (define o   open-domain-interval)
           (define c closed-domain-interval)
  (and      (domain-interval-overlap? (o 1 3) (o   2 4))
            (domain-interval-overlap? (c 1 3) (c 3 4))
            (domain-interval-overlap? (c 3 4) (c 1 3))
       (not (domain-interval-overlap? (o 1 3) (c 3 4)))
       (not (domain-interval-overlap? (c 1 3) (o   3 4)))
       (not (domain-interval-overlap? (c 3 4) (o   1 3)))
       (not (domain-interval-overlap? (o 3 4) (c 1 3)))
            (domain-interval-overlap? (o 1 10) (o 3 4))
            (domain-interval-overlap? (o 3 4)  (o 1 10) )
       (not (domain-interval-overlap? (o -inf.0 3)      (o  3 +inf.0)))
       (not (domain-interval-overlap? (c -inf.0 3)      (o 3 +inf.0)))
       (not (domain-interval-overlap? (o -inf.0 3)      (c 3 +inf.0)))
       (domain-interval-overlap?      (c -inf.0 3)      (c 3 +inf.0))
       (domain-interval-overlap?      (o -inf.0 +inf.0) (o -inf.0 +inf.0))
       (domain-interval-overlap?      (c 42 42)         (c 42 42)))))

(define (open-domain-interval   a b)        (domain-interval #f a b #f))
(define (closed-domain-interval a b)        (domain-interval #t a b #t))
(define (oc-domain-interval     a b)        (domain-interval #f a b #t))
(define (co-domain-interval     a b)        (domain-interval #t a b #f))
(define (point-domain-interval a)           (closed-domain-interval a a))


(define (domain-interval< I1 I2) ; is all of I1 strictly less than all of I2
  (defm (domain-interval ac a b bc) I1)
  (defm (domain-interval xc x y yc) I2)
  (and (not (domain-interval-overlap? I1 I2))
       (or (< b x)
           (and (= b x) (not (and bc xc))))))

(module+ test
  'domain-interval<
         (let ()
           (define o   open-domain-interval)
           (define c closed-domain-interval)
  (and (domain-interval< (o 1 2) (o   2 3))
       (domain-interval< (o 1 2) (c 2 3))
       (domain-interval< (c 1 2) (o 2 3))
       (not (domain-interval< (c 1 2) (c 2 3))))))

(define (domain-interval-union I1 I2)
  (defm (domain-interval ac a b bc) I1)
  (defm (domain-interval xc x y yc) I2)
  (unless (domain-interval-overlap? I1 I2)
    (error 'domain-interval-union (~a "expected overlapping intervals, got: " I1 " and " I2)))
  (define maximum (max b y))
  (define minimum (min a x))
  (domain-interval (or ac xc) minimum maximum (or bc yc)))

(define/contract (two-intervals->domain I1 I2)
  (-> domain-interval? domain-interval?   domain?)
  (defm (domain-interval ac a b bc) I1)
  (defm (domain-interval xc x y yc) I2)
  (cond
    [(empty-domain-interval? I1) I2]
    [(empty-domain-interval? I2)  I1]
    [(domain-interval< I1 I2)         (domain (list I1 I2))]
    [(domain-interval< I2 I1)         (domain (list I2 I1))]
    [(domain-interval-overlap? I1 I2)  (domain (list (domain-interval-union I1 I2)))]
    [else (error 'two-intervals->domain (~a "got: "  I1 " and " I2))]))


(define an-empty-domain-interval (open-domain-interval 0 0))

(define/contract (domain-intervals->domain is)
  (-> (listof domain-interval?)  domain?)
  (match is
    [(list)        (domain (list an-empty-domain-interval))]
    [(list I)      (domain (list I))]
    [(list I1 I2)  (two-intervals->domain I1 I2)]
    [(cons I1 Is)  (two-intervals->domain I1 (domain-intervals->domain Is))]
    [_ (error 'domain-intervals->domain (~a "got: " is))]))

#;(define (insert-domain-interval-into-intervals i js)
    (match js
      [(list)       (list i)]
      [(cons j js)  (cond [(domain-interval-overlap? i j)
                           (cons (domain-interval-union i j) js)]
                          [(domain-interval< i j)
                           (cons i (cons j js))]
                          [else
                           (cons j (insert-domin-interval-into-intervals i js))])]))

(define/contract (merge-domain-intervals is* js*)
  (-> (listof domain-interval?) (listof domain-interval?)    (listof domain-interval?))
  (define merge merge-domain-intervals)
  ; the lists are sorted
  (match* (is* js*)
    [('() js)  js*]
    [(is '())  is*]
    [( (cons i is) (cons j js) )
     (cond [(domain-interval< i j)         (cons i (merge is js*))]
           [(domain-interval< j i)         (cons j (merge is* js))]
           [(domain-interval-overlap? i j) (cons (domain-interval-union i j)
                                                 (merge is js))])]))

(define (domain-union d1 d2)
  (defm (domain is) d1)
  (defm (domain js) d2)
  (domain (merge-domain-intervals is js)))

(define (interval a b [ac #f] [bc #f])
  (unless (<= a b)
    (error 'interval (~a "expected a<=b, got: " a " and " b)))
  (domain (list (domain-interval ac a b bc))))


(define (closed a b) (interval a b #t #t))
(define (open a b)   (interval a b #f #f))
(define reals        (open -inf.0 +inf.0))