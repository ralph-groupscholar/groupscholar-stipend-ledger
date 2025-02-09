#lang racket

(require racket/string
         srfi/19)

(provide format-money
         month-key
         format-table
         summarize-rows)

(define (pad-right value width)
  (define len (string-length value))
  (if (>= len width)
      value
      (string-append value (make-string (- width len) #\space))))

(define (format-money amount-cents currency)
  (define sign (if (< amount-cents 0) "-" ""))
  (define abs-cents (abs amount-cents))
  (define dollars (quotient abs-cents 100))
  (define cents (remainder abs-cents 100))
  (format "~a~a ~a.~a"
          sign
          currency
          dollars
          (~r cents #:min-width 2 #:pad-string "0")))

(define (month-key date-str)
  (define parsed (string->date date-str "~Y-~m-~d"))
  (format "~a-~a"
          (date-year parsed)
          (~r (date-month parsed) #:min-width 2 #:pad-string "0")))

(define (format-table headers rows)
  (define widths
    (for/list ([i (in-range (length headers))])
      (apply max
             (string-length (list-ref headers i))
             (for/list ([row rows])
               (string-length (list-ref row i))))))
  (define (format-row row)
    (string-join
     (for/list ([cell row] [width widths])
       (pad-right cell width))
     "  "))
  (string-join
   (append (list (format-row headers)
                 (format-row (for/list ([w widths]) (make-string w #\-))))
           (for/list ([row rows]) (format-row row)))
   "\n"))

(define (summarize-rows rows)
  (define summary (make-hash))
  (for ([row rows])
    (define key (list-ref row 0))
    (define amount (string->number (list-ref row 1)))
    (hash-set! summary key (+ amount (hash-ref summary key 0))))
  (sort (hash->list summary)
        (lambda (a b) (> (cdr a) (cdr b)))))
