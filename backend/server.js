const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

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

const JWT_SECRET = process.env.JWT_SECRET || 'devops-bank-secret-change-in-production';
const JWT_EXPIRES = '24h';

// ── JWT Auth Middleware ───────────────────────────────────────────────────────
function authRequired(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access denied. Please log in.' });

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Invalid or expired token. Please log in again.' });
  }
}

// ── Health check (public) ─────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'error', db: 'disconnected', error: err.message });
  }
});

// ── Register ──────────────────────────────────────────────────────────────────
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, full_name } = req.body;

    if (!email || !password || !full_name) {
      return res.status(400).json({ error: 'email, password, and full_name are required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES ($1, $2, $3) RETURNING id, email, full_name, created_at',
      [email.toLowerCase(), password_hash, full_name.trim()]
    );

    const user = result.rows[0];
    const token = jwt.sign({ id: user.id, email: user.email, full_name: user.full_name }, JWT_SECRET, { expiresIn: JWT_EXPIRES });

    res.status(201).json({ token, user: { id: user.id, email: user.email, full_name: user.full_name } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Login ─────────────────────────────────────────────────────────────────────
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }

    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email.toLowerCase()]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign({ id: user.id, email: user.email, full_name: user.full_name }, JWT_SECRET, { expiresIn: JWT_EXPIRES });

    res.json({ token, user: { id: user.id, email: user.email, full_name: user.full_name } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Get current user (protected) ──────────────────────────────────────────────
app.get('/api/auth/me', authRequired, async (req, res) => {
  const result = await pool.query('SELECT id, email, full_name, created_at FROM users WHERE id = $1', [req.user.id]);
  res.json(result.rows[0]);
});

// ── All routes below this point require auth ──────────────────────────────────
app.use('/api/accounts', authRequired);
app.use('/api/transfer', authRequired);
app.use('/api/transactions', authRequired);
app.use('/api/ai', authRequired);

// ── Get all accounts (scoped to logged-in user) ───────────────────────────────
app.get('/api/accounts', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM accounts WHERE user_id = $1 ORDER BY id',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Get single account (ownership check) ─────────────────────────────────────
app.get('/api/accounts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM accounts WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Account not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Create account ────────────────────────────────────────────────────────────
app.post('/api/accounts', async (req, res) => {
  try {
    const { owner_name, account_type, initial_balance } = req.body;
    if (!owner_name || !account_type) {
      return res.status(400).json({ error: 'owner_name and account_type are required' });
    }
    const balance = parseFloat(initial_balance) || 0;
    const result = await pool.query(
      'INSERT INTO accounts (user_id, owner_name, account_type, balance) VALUES ($1, $2, $3, $4) RETURNING *',
      [req.user.id, owner_name, account_type, balance]
    );
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

// ── Deposit (ownership check) ─────────────────────────────────────────────────
app.post('/api/accounts/:id/deposit', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });

    await client.query('BEGIN');
    const acc = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [id, req.user.id]
    );
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

// ── Withdraw (ownership check) ────────────────────────────────────────────────
app.post('/api/accounts/:id/withdraw', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });

    await client.query('BEGIN');
    const acc = await client.query(
      'SELECT * FROM accounts WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [id, req.user.id]
    );
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

// ── Transfer (ownership check on source account) ──────────────────────────────
app.post('/api/transfer', async (req, res) => {
  const client = await pool.connect();
  try {
    const { from_account_id, to_account_id, amount, description } = req.body;
    const amt = parseFloat(amount);
    if (!amt || amt <= 0) return res.status(400).json({ error: 'Amount must be positive' });
    if (from_account_id === to_account_id) return res.status(400).json({ error: 'Cannot transfer to same account' });

    await client.query('BEGIN');
    const [from, to] = await Promise.all([
      // Must own the source account
      client.query('SELECT * FROM accounts WHERE id = $1 AND user_id = $2 FOR UPDATE', [from_account_id, req.user.id]),
      // Destination can be any account (allows transfers between users)
      client.query('SELECT * FROM accounts WHERE id = $1 FOR UPDATE', [to_account_id])
    ]);
    if (from.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Source account not found or not yours' }); }
    if (to.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Destination account not found' }); }
    if (parseFloat(from.rows[0].balance) < amt) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'Insufficient funds' }); }

    const fromNew = parseFloat(from.rows[0].balance) - amt;
    const toNew = parseFloat(to.rows[0].balance) + amt;
    const desc = description || 'Transfer';

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

// ── Get transactions for account (ownership check) ────────────────────────────
app.get('/api/accounts/:id/transactions', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT t.* FROM transactions t
       JOIN accounts a ON t.account_id = a.id
       WHERE t.account_id = $1 AND a.user_id = $2
       ORDER BY t.created_at DESC LIMIT 50`,
      [id, req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Get all transactions (scoped to logged-in user) ───────────────────────────
app.get('/api/transactions', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.*, a.owner_name FROM transactions t
       JOIN accounts a ON t.account_id = a.id
       WHERE a.user_id = $1
       ORDER BY t.created_at DESC LIMIT 100`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── AI Chat (scoped to logged-in user's accounts only) ────────────────────────
const OLLAMA_URL = `http://${process.env.OLLAMA_HOST || 'ollama'}:11434`;

app.post('/api/ai/chat', async (req, res) => {
  const { message } = req.body;
  if (!message) return res.status(400).json({ error: 'message is required' });

  try {
    const accounts = await pool.query(
      'SELECT owner_name, account_type, balance FROM accounts WHERE user_id = $1',
      [req.user.id]
    );
    const context = accounts.rows
      .map(a => `${a.owner_name}: ${a.account_type} — €${a.balance}`)
      .join('\n');

    const response = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(120000),
      body: JSON.stringify({
        model: process.env.OLLAMA_MODEL || 'tinyllama',
        prompt: `You are a helpful bank assistant. Answer concisely in 2-3 sentences max.
Here are the current accounts:
${context}

Customer question: ${message}
Answer:`,
        stream: false,
        options: { num_predict: 150, temperature: 0.7 }
      })
    });

    if (!response.ok) throw new Error(`Ollama returned ${response.status}`);
    const data = await response.json();
    res.json({ reply: data.response });
  } catch (err) {
    if (err.name === 'TimeoutError') {
      res.status(504).json({ error: 'AI took too long to respond. Try a shorter question.' });
    } else {
      res.status(500).json({ error: 'AI unavailable: ' + err.message });
    }
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Bank API running on port ${PORT}`));