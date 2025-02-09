CREATE SCHEMA IF NOT EXISTS gs_stipend_ledger;

CREATE TABLE IF NOT EXISTS gs_stipend_ledger.disbursements (
  id SERIAL PRIMARY KEY,
  recipient_name TEXT NOT NULL,
  cohort TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  disbursed_at DATE NOT NULL,
  method TEXT NOT NULL,
  source TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS disbursements_disbursed_at_idx
  ON gs_stipend_ledger.disbursements (disbursed_at);

CREATE INDEX IF NOT EXISTS disbursements_cohort_idx
  ON gs_stipend_ledger.disbursements (cohort);

CREATE INDEX IF NOT EXISTS disbursements_recipient_idx
  ON gs_stipend_ledger.disbursements (recipient_name);
