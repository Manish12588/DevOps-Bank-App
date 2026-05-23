-- ============================================================
-- Bank Database Schema
-- ============================================================

-- Users table (authentication)
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES users(id) ON DELETE SET NULL,
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

CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- ── Seed data ──────────────────────────────────────────────────────────────────
-- NOTE: Seed user password is "admin123" — change in production
-- Hash generated with bcryptjs rounds=10
INSERT INTO users (email, password_hash, full_name) VALUES
    ('admin@bank.local', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin User')
ON CONFLICT DO NOTHING;

INSERT INTO accounts (user_id, owner_name, account_type, balance) VALUES
    (1, 'Manish', 'SAVINGS', 10000.00)
ON CONFLICT DO NOTHING;

INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES
    (1, 'DEPOSIT',    10000.00, 'Initial deposit',  10000.00),
    (1, 'WITHDRAWAL',  1000.50, 'Rent payment',      8999.50)
ON CONFLICT DO NOTHING;