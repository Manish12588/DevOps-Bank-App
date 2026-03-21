const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST || 'db',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'bankdb',
  user: process.env.DB_USER || 'bankuser',
  password: process.env.DB_PASSWORD || 'bankpass',
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'error', db: 'disconnected', error: err.message });
  }
});

// Get all accounts
app.get('/api/accounts', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM accounts ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get single account
app.get('/api/accounts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM accounts WHERE id = $1', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Account not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create account
app.post('/api/accounts', async (req, res) => {
  try {
    const { owner_name, account_type, initial_balance } = req.body;
    if (!owner_name || !account_type) {
      return res.status(400).json({ error: 'owner_name and account_type are required' });
    }
    const balance = parseFloat(initial_balance) || 0;
    const result = await pool.query(
      'INSERT INTO accounts (owner_name, account_type, balance) VALUES ($1, $2, $3) RETURNING *',
      [owner_name, account_type, balance]
    );
    // Log transaction if initial balance > 0
    if (balance > 0) {
      await pool.query(
        'INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES ($1, $2, $3, $4, $5)',
        [result.rows[0].id, 'DEPOSIT', balance, 'Initial deposit', balance]
      );
    }
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Deposit
app.post('/api/accounts/:id/deposit', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });

    await client.query('BEGIN');
    const acc = await client.query('SELECT * FROM accounts WHERE id = $1 FOR UPDATE', [id]);
    if (acc.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Account not found' }); }

    const newBalance = parseFloat(acc.rows[0].balance) + amt;
    await client.query('UPDATE accounts SET balance = $1, updated_at = NOW() WHERE id = $2', [newBalance, id]);
    const tx = await client.query(
      'INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [id, 'DEPOSIT', amt, description || 'Deposit', newBalance]
    );
    await client.query('COMMIT');
    res.json({ account_id: id, transaction: tx.rows[0], new_balance: newBalance });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Withdraw
app.post('/api/accounts/:id/withdraw', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });

    await client.query('BEGIN');
    const acc = await client.query('SELECT * FROM accounts WHERE id = $1 FOR UPDATE', [id]);
    if (acc.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Account not found' }); }
    if (parseFloat(acc.rows[0].balance) < amt) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'Insufficient funds' }); }

    const newBalance = parseFloat(acc.rows[0].balance) - amt;
    await client.query('UPDATE accounts SET balance = $1, updated_at = NOW() WHERE id = $2', [newBalance, id]);
    const tx = await client.query(
      'INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [id, 'WITHDRAWAL', amt, description || 'Withdrawal', newBalance]
    );
    await client.query('COMMIT');
    res.json({ account_id: id, transaction: tx.rows[0], new_balance: newBalance });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Transfer
app.post('/api/transfer', async (req, res) => {
  const client = await pool.connect();
  try {
    const { from_account_id, to_account_id, amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });
    if (from_account_id === to_account_id) return res.status(400).json({ error: 'Cannot transfer to same account' });

    await client.query('BEGIN');
    const [from, to] = await Promise.all([
      client.query('SELECT * FROM accounts WHERE id = $1 FOR UPDATE', [from_account_id]),
      client.query('SELECT * FROM accounts WHERE id = $1 FOR UPDATE', [to_account_id])
    ]);
    if (from.rows.length === 0 || to.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Account not found' }); }
    if (parseFloat(from.rows[0].balance) < amt) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'Insufficient funds' }); }

    const fromNew = parseFloat(from.rows[0].balance) - amt;
    const toNew = parseFloat(to.rows[0].balance) + amt;
    const desc = description || `Transfer to/from account`;

    await client.query('UPDATE accounts SET balance = $1, updated_at = NOW() WHERE id = $2', [fromNew, from_account_id]);
    await client.query('UPDATE accounts SET balance = $1, updated_at = NOW() WHERE id = $2', [toNew, to_account_id]);
    await client.query('INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES ($1, $2, $3, $4, $5)', [from_account_id, 'TRANSFER_OUT', amt, desc, fromNew]);
    await client.query('INSERT INTO transactions (account_id, type, amount, description, balance_after) VALUES ($1, $2, $3, $4, $5)', [to_account_id, 'TRANSFER_IN', amt, desc, toNew]);
    await client.query('COMMIT');
    res.json({ success: true, from_balance: fromNew, to_balance: toNew });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
});

// Get transactions for account
app.get('/api/accounts/:id/transactions', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM transactions WHERE account_id = $1 ORDER BY created_at DESC LIMIT 50',
      [id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all transactions
app.get('/api/transactions', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.*, a.owner_name FROM transactions t 
       JOIN accounts a ON t.account_id = a.id 
       ORDER BY t.created_at DESC LIMIT 100`
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Bank API running on port ${PORT}`));
