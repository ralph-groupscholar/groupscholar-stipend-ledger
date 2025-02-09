#lang racket

(require rackunit
         "reports.rkt")

(check-equal? (format-money 12500 "USD") "USD 125.00")
(check-equal? (format-money -255 "USD") "-USD 2.55")
(check-equal? (month-key "2026-02-01") "2026-02")

(define table-output
  (format-table
   (list "Name" "Total")
   (list (list "A" "USD 10.00")
         (list "Longer" "USD 5.00"))))

(check-true (string-contains? table-output "Name"))
(check-true (string-contains? table-output "Longer"))
