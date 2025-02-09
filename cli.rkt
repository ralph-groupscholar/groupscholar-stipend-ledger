#lang racket

(require racket/cmdline
         racket/string
         racket/vector
         db
         "db.rkt"
         "reports.rkt")

(provide run-cli)

(define (query-disbursements conn filters)
  (define conditions '())
  (define params '())
  (define (add-condition condition value)
    (set! conditions (cons condition conditions))
    (set! params (cons value params)))
  (for ([pair filters])
    (define key (car pair))
    (define value (cdr pair))
    (when (and value (not (string=? value "")))
      (case key
        [(cohort) (add-condition "cohort = ?" value)]
        [(recipient) (add-condition "recipient_name ILIKE ?" (string-append "%" value "%"))]
        [(from) (add-condition "disbursed_at >= ?" value)]
        [(to) (add-condition "disbursed_at <= ?" value)])))
  (define where-clause
    (if (null? conditions)
        ""
        (string-append "WHERE " (string-join (reverse conditions) " AND "))))
  (define sql
    (string-append
     "SELECT recipient_name, cohort, amount_cents, currency, disbursed_at, method, source, notes "
     "FROM gs_stipend_ledger.disbursements "
     where-clause
     " ORDER BY disbursed_at DESC, recipient_name ASC"))
  (apply query-rows conn sql (reverse params)))

(define (insert-disbursement! conn recipient cohort amount-cents currency disbursed-at method source notes)
  (query-exec
   conn
   "INSERT INTO gs_stipend_ledger.disbursements
    (recipient_name, cohort, amount_cents, currency, disbursed_at, method, source, notes)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)"
   recipient cohort amount-cents currency disbursed-at method source notes))

(define (fetch-summary conn group-by)
  (define sql
    (string-append
     "SELECT " group-by ", SUM(amount_cents) "
     "FROM gs_stipend_ledger.disbursements "
     "GROUP BY " group-by " ORDER BY SUM(amount_cents) DESC"))
  (query-rows conn sql))

(define (fetch-monthly-summary conn)
  (define sql
    "SELECT TO_CHAR(disbursed_at, 'YYYY-MM') AS month_key, SUM(amount_cents)
     FROM gs_stipend_ledger.disbursements
     GROUP BY month_key
     ORDER BY month_key DESC")
  (query-rows conn sql))

(define (display-disbursements rows)
  (define formatted
    (for/list ([row rows])
      (define amount (vector-ref row 2))
      (define currency (vector-ref row 3))
      (list (vector-ref row 0)
            (vector-ref row 1)
            (format-money amount currency)
            (vector-ref row 4)
            (vector-ref row 5)
            (vector-ref row 6)
            (or (vector-ref row 7) ""))))
  (if (null? formatted)
      (displayln "No disbursements found.")
      (displayln
       (format-table
        (list "Recipient" "Cohort" "Amount" "Date" "Method" "Source" "Notes")
        formatted))))

(define (display-summary rows label)
  (define formatted
    (for/list ([row rows])
      (list (vector-ref row 0)
            (format-money (vector-ref row 1) "USD"))))
  (if (null? formatted)
      (displayln "No data available.")
      (displayln (format-table (list label "Total") formatted))))

(define (run-cli)
  (define argv (current-command-line-arguments))
  (when (zero? (vector-length argv))
    (displayln "Commands: log, list, summary, cohort-summary, recipient-summary, source-summary")
    (exit 0))
  (define command (vector-ref argv 0))
  (define rest-argv (vector-drop argv 1))

  (case command
    [("log")
     (define recipient "")
     (define cohort "")
     (define amount-cents #f)
     (define currency "USD")
     (define disbursed-at "")
     (define method "")
     (define source "")
     (define notes "")
     (command-line
      #:program "stipend-ledger log"
      #:argv rest-argv
      #:once-each
      ["--recipient" name "Recipient name" (set! recipient name)]
      ["--cohort" name "Cohort" (set! cohort name)]
      ["--amount" amount "Amount in dollars" (set! amount-cents (inexact->exact (round (* 100 (string->number amount)))))]
      ["--currency" code "Currency" (set! currency code)]
      ["--date" date "Disbursed date (YYYY-MM-DD)" (set! disbursed-at date)]
      ["--method" value "Payment method" (set! method value)]
      ["--source" value "Funding source" (set! source value)]
      ["--notes" value "Notes" (set! notes value)])
     (when (or (string=? recipient "") (string=? cohort "") (not amount-cents) (string=? disbursed-at ""))
       (error 'log "recipient, cohort, amount, and date are required"))
     (call-with-connection
      (lambda (conn)
        (insert-disbursement! conn recipient cohort amount-cents currency disbursed-at method source notes)))
     (displayln "Logged stipend disbursement."))
    [("list")
     (define cohort "")
     (define recipient "")
     (define from "")
     (define to "")
     (command-line
      #:program "stipend-ledger list"
      #:argv rest-argv
      #:once-each
      ["--cohort" value "Cohort" (set! cohort value)]
      ["--recipient" value "Recipient contains" (set! recipient value)]
      ["--from" value "From date (YYYY-MM-DD)" (set! from value)]
      ["--to" value "To date (YYYY-MM-DD)" (set! to value)])
     (call-with-connection
      (lambda (conn)
        (display-disbursements
         (query-disbursements
          conn
          (list (cons 'cohort cohort)
                (cons 'recipient recipient)
                (cons 'from from)
                (cons 'to to))))))]
    [("summary")
     (call-with-connection
      (lambda (conn)
        (display-summary (fetch-monthly-summary conn) "Month")))]
    [("cohort-summary")
     (call-with-connection
      (lambda (conn)
        (display-summary (fetch-summary conn "cohort") "Cohort")))]
    [("recipient-summary")
     (call-with-connection
      (lambda (conn)
        (display-summary (fetch-summary conn "recipient_name") "Recipient")))]
    [("source-summary")
     (call-with-connection
      (lambda (conn)
        (display-summary (fetch-summary conn "source") "Source")))]
    [else
     (displayln "Commands: log, list, summary, cohort-summary, recipient-summary, source-summary")]))
