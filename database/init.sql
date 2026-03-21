-- ============================================================
-- Bank Database Schema
-- This script runs automatically when the PostgreSQL container
-- starts for the first time (via docker-entrypoint-initdb.d/)
-- ============================================================

-- Accounts table (Tier 3 → persisted data)
CREATE TABLE IF NOT EXISTS accounts (
    id            SERIAL PRIMARY KEY,
    owner_name    VARCHAR(100) NOT NULL,
    account_type  VARCHAR(20)  NOT NULL CHECK (account_type IN ('SAVINGS', 'CHECKING', 'BUSINESS')),
    balance       NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id             SERIAL PRIMARY KEY,
    account_id     INTEGER NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    type           VARCHAR(20) NOT NULL CHECK (type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER_IN', 'TRANSFER_OUT')),
    amount         NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    description    TEXT,
    balance_after  NUMERIC(15, 2) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast transaction lookups by account
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- ── Seed data ──────────────────────────────────────────────────────────────────
INSERT INTO accounts (owner_name, account_type, balance) VALUES
    ('TestAccount Saving',  'SAVINGS',  1000.00),
    ('TestAccount Checking',      'CHECKING', 1000.50),
    ('TestAccount Business',      'BUSINESS', 10000.00);

-- Seed some transactions to make the UI interesting from the start
INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES
    (1, 'DEPOSIT',    50.00, 'Initial deposit',        50.00),
    (2, 'DEPOSIT',    100.00, 'Initial deposit',        100.00),
    (2, 'WITHDRAWAL',  25.50, 'Rent payment',           25.50),
    (3, 'DEPOSIT',  10000.00, 'Business capital',     10000.00),
    (3, 'WITHDRAWAL',  2000.00, 'Office supplies',       8000.00);
