# Group Scholar Stipend Ledger

Racket CLI for tracking stipend disbursements and producing cohort/monthly summaries. Designed for Group Scholar ops to log payouts and generate quick reporting snapshots.

## Features
- Log stipend disbursements with cohort, method, source, and notes
- List disbursements with cohort, recipient, and date filtering
- Summaries by month, cohort, recipient, and funding source
- Production PostgreSQL backed storage

## Tech
- Racket
- PostgreSQL

## Setup

This CLI connects to the production database only. Provide a `DATABASE_URL` environment variable.

Example:

```bash
export DATABASE_URL="postgres://USER:PASSWORD@HOST:PORT/DATABASE"
```

## Usage

```bash
racket main.rkt log \
  --recipient "Ariana Patel" \
  --cohort "Cohort 2025" \
  --amount 750 \
  --currency USD \
  --date 2026-02-01 \
  --method ACH \
  --source "General Fund" \
  --notes "Spring stipend"

racket main.rkt list --cohort "Cohort 2025" --from 2025-10-01
racket main.rkt summary
racket main.rkt cohort-summary
racket main.rkt recipient-summary
racket main.rkt source-summary
```

## Database

Schema and seed SQL live in `schema.sql` and `seed.sql`.

## Tests

```bash
racket tests.rkt
```
