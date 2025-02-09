#lang racket

(require db
         net/url
         racket/string)

(provide call-with-connection
         database-url->params)

(define (database-url->params db-url)
  (define url (string->url db-url))
  (define host (url-host url))
  (define port (or (url-port url) 5432))
  (define user (url-user url))
  (define pass (url-pass url))
  (define path (url-path url))
  (define database
    (if (null? path)
        ""
        (string-join (map path/param-path path) "/")))
  (when (or (not host) (string=? host ""))
    (error 'database-url->params "DATABASE_URL missing host"))
  (when (or (not database) (string=? database ""))
    (error 'database-url->params "DATABASE_URL missing database"))
  (values host port user pass database))

(define (connect)
  (define db-url (or (getenv "DATABASE_URL") ""))
  (when (string=? db-url "")
    (error 'connect "DATABASE_URL is required"))
  (define-values (host port user pass database) (database-url->params db-url))
  (postgresql-connect #:server host
                      #:port port
                      #:database database
                      #:user user
                      #:password pass
                      #:ssl 'require))

(define (call-with-connection proc)
  (define conn (connect))
  (dynamic-wind
    void
    (lambda () (proc conn))
    (lambda () (disconnect conn))))
