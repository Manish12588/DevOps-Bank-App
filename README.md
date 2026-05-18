# 🏦 DevOps Bank — Docker Four-Tier Learning App

A fully containerized **four-tier banking application** designed to teach Docker and Docker Compose through a real, working project. Features user authentication, JWT-secured APIs, per-user account isolation, and an AI assistant powered by Ollama.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Docker Host (your machine)                 │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  bank-network (bridge)                     │ │
│  │                                                            │ │
│  │  ┌──────────┐   ┌──────────┐   ┌──────────┐  ┌─────────┐ │ │
│  │  │  TIER 1  │   │  TIER 2  │   │  TIER 3  │  │ TIER 4  │ │ │
│  │  │ Frontend │──▶│ Backend  │──▶│ Database │  │ Ollama  │ │ │
│  │  │  Nginx   │   │ Node.js  │   │Postgres  │  │  LLM    │ │ │
│  │  │  :80     │   │  :3000   │   │  :5432   │  │ :11434  │ │ │
│  │  └──────────┘   └──────────┘   └──────────┘  └─────────┘ │ │
│  │        │               │                                   │ │
│  └────────┼───────────────┼───────────────────────────────────┘ │
│           │               │                                     │
│        :8080           :3000                                    │
│     (browser)        (API/curl)                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Tier | Service    | Technology       | Internal Port | Host Port |
|------|------------|------------------|--------------|-----------|
| 1    | `frontend` | Nginx + HTML/JS  | 80           | **8080**  |
| 2    | `backend`  | Node.js/Express  | 3000         | **3000**  |
| 3    | `db`       | PostgreSQL 15    | 5432         | —         |
| 4    | `ollama`   | Ollama LLM       | 11434        | —         |

---

## 📦 Project Structure

```
DevOps-Bank-App/
├── docker-compose.yml        ← Orchestrates all four containers
├── .env                      ← Environment variables (never commit)
├── .env.example              ← Template for .env
├── .gitignore
│
├── frontend/
│   ├── Dockerfile            ← Nginx image serving static files
│   ├── nginx.conf            ← Nginx reverse proxy config
│   ├── index.html            ← Main SPA (dashboard, accounts, operations)
│   ├── login.html            ← Login page
│   └── register.html         ← Registration page
│
├── backend/
│   ├── Dockerfile            ← Node.js image
│   ├── package.json          ← Dependencies incl. bcryptjs, jsonwebtoken
│   └── server.js             ← Express REST API with JWT auth
│
└── database/
    └── init.sql              ← Schema + seed data (runs on first start)
```

---

## 🚀 Quick Start

### Prerequisites

```bash
docker --version        # Docker 24+ recommended
docker compose version  # Docker Compose v2
```

### 1. Clone the repository

```bash
git clone https://github.com/Manish12588/DevOps-Bank-App.git
cd DevOps-Bank-App
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Edit `.env` and set your values:

```env
DOCKERHUB_USER=your-dockerhub-username
DOCKER_TAG=latest
JWT_SECRET=your-random-secret-here   # generate with: openssl rand -hex 32
DB_PASSWORD=bankpass
```

> ⚠️ Never commit `.env` to Git. It's in `.gitignore` by default.

### 3. Start everything

```bash
docker compose up --build
```

> **What this does:**
> - Builds Docker images for `frontend` and `backend` from local Dockerfiles
> - Pulls `postgres:15-alpine` and `ollama/ollama` from Docker Hub
> - Creates a bridge network (`bank-network`)
> - Creates named volumes (`bank-pgdata`, `ollama-data`) for persistence
> - Starts all containers in dependency order:
>   `db` + `ollama` → `backend` → `frontend`

### 4. Open the app

Once you see `Bank API running on port 3000` in the logs:

- **🌐 App:** http://localhost:8080
- **⚙️ API:** http://localhost:3000
- **❤️ Health:** http://localhost:3000/health

### 5. Register and log in

Navigate to http://localhost:8080 — you'll be redirected to the login page.

- Click **"Create one"** to register a new account
- Fill in your name, email, and password (min. 8 characters)
- After registration you'll be automatically redirected to the dashboard

### 6. Stop everything

```bash
# Stop but keep data:
docker compose down

# Stop AND delete all data:
docker compose down -v
```

---

## 🔐 Authentication

The app uses **JWT (JSON Web Token)** based authentication.

### How it works

```
User registers/logs in
        ↓
Backend validates credentials, signs a JWT with JWT_SECRET
        ↓
Token stored in browser localStorage
        ↓
Every API request sends: Authorization: Bearer <token>
        ↓
Backend middleware verifies token on every protected route
        ↓
Token expires after 24 hours → user redirected to login
```

### Security features

- Passwords hashed with **bcrypt** (10 salt rounds) — never stored in plain text
- All `/api/accounts`, `/api/transactions`, `/api/transfer`, `/api/ai` routes are **JWT-protected**
- Each user only sees **their own accounts and transactions** — no cross-user data leakage
- Deposit/withdraw/transfer all verify **account ownership** before executing
- Token expiry auto-redirects to login page

### Default seed user

The database ships with one seed user for testing:

| Email | Password |
|-------|----------|
| `admin@bank.local` | `admin123` |

> Change this password immediately in any non-local environment.

---

## 🎯 Features

- **Registration & Login** — Secure user accounts with bcrypt + JWT
- **Dashboard** — Real-time balance stats scoped to logged-in user
- **Accounts** — View your accounts, click to see transaction history
- **Deposit / Withdraw / Transfer** — Full money operations with ownership validation
- **New Account** — Open Savings, Checking, or Business accounts
- **AI Assistant** — Chat with a local LLM (Ollama) about your accounts
- **Architecture page** — Learn how the tiers connect inside the UI
- **Logout** — Clears token and redirects to login

---

## 🌐 Nginx Reverse Proxy

The frontend Nginx container acts as a reverse proxy — the browser only talks to port 8080, and Nginx forwards API calls to the backend:

```
Browser → localhost:8080/api/*  →  Nginx  →  backend:3000/api/*
Browser → localhost:8080/*.html →  Nginx  →  serves static file
```

This means the backend is **not directly exposed** to the browser — all traffic goes through Nginx.

---

## 🔌 API Reference

All endpoints are available at `http://localhost:3000`.

Protected routes require the header:
```
Authorization: Bearer <your-jwt-token>
```

### Auth (public)

```bash
# Register
POST /api/auth/register
{ "full_name": "Jane Doe", "email": "jane@example.com", "password": "mypassword" }

# Login
POST /api/auth/login
{ "email": "jane@example.com", "password": "mypassword" }

# Both return:
{ "token": "<jwt>", "user": { "id": 1, "email": "...", "full_name": "..." } }
```

### Health (public)

```bash
GET /health
# → { "status": "ok", "db": "connected" }
```

### Accounts 🔒

```bash
# List your accounts
GET /api/accounts

# Get one account (must be yours)
GET /api/accounts/:id

# Create new account
POST /api/accounts
{ "owner_name": "Jane Doe", "account_type": "SAVINGS", "initial_balance": 1000 }
```

### Operations 🔒

```bash
# Deposit
POST /api/accounts/:id/deposit
{ "amount": 500, "description": "Salary" }

# Withdraw
POST /api/accounts/:id/withdraw
{ "amount": 200, "description": "Groceries" }

# Transfer (you must own the source account)
POST /api/transfer
{ "from_account_id": 1, "to_account_id": 2, "amount": 100, "description": "Rent" }

# Get transactions for your account
GET /api/accounts/:id/transactions

# Get all your transactions
GET /api/transactions
```

### AI Assistant 🔒

```bash
POST /api/ai/chat
{ "message": "What is my total balance?" }
# → { "reply": "..." }
```

### Test with curl

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Test User","email":"test@example.com","password":"testpass123"}'

# Login and save token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123"}' | jq -r '.token')

# List your accounts
curl http://localhost:3000/api/accounts \
  -H "Authorization: Bearer $TOKEN" | jq

# Create an account
curl -X POST http://localhost:3000/api/accounts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"owner_name":"Test User","account_type":"SAVINGS","initial_balance":1000}'

# Deposit into account 1
curl -X POST http://localhost:3000/api/accounts/1/deposit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 500, "description": "Test deposit"}'
```

---

## 🗄️ Database Schema

```sql
-- Users (authentication)
users
  id, email, password_hash, full_name, created_at

-- Bank accounts (linked to users)
accounts
  id, user_id, owner_name, account_type, balance, created_at, updated_at

-- Transaction history
transactions
  id, account_id, type, amount, description, balance_after, created_at
```

The `init.sql` runs automatically when the PostgreSQL container starts for the **first time** (empty volume). If you change the schema, run:

```bash
docker compose down -v   # removes the volume
docker compose up --build
```

Or apply changes manually:

```bash
docker exec -i bank-db psql -U bankuser -d bankdb < database/init.sql
```

---

## 🐳 Docker Concepts You'll Learn

### Multi-stage builds (backend Dockerfile)

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

# Stage 2: Lean final image
FROM node:20-alpine
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./
```

### docker-compose.yml concepts

| Concept | Where used | What it does |
|---------|-----------|--------------|
| `build.context` | frontend, backend | Build from local Dockerfile |
| `image` | all | Tag or pull from Docker Hub |
| `environment` | all | Pass env vars into containers |
| `ports` | frontend, backend | Map host port → container port |
| `networks` | all | Put containers on shared network |
| `volumes` | db, ollama | Persist data across restarts |
| `depends_on` | backend, frontend | Start-order with health conditions |
| `healthcheck` | all | Know when a service is truly ready |
| `restart: unless-stopped` | all | Auto-restart on crash |

### Container networking

```
backend → db:5432        (not localhost — service name resolves on bank-network)
backend → ollama:11434   (AI requests stay inside Docker network)
browser → nginx:8080     (only Nginx is exposed externally)
```

### Volumes

```yaml
volumes:
  bank-pgdata:    # PostgreSQL data — survives container restarts
  ollama-data:    # Downloaded AI models — avoids re-downloading
```

---

## 🔍 Useful Docker Commands

```bash
# ── Status ─────────────────────────────────────────────────
docker compose ps                          # All container statuses
docker compose logs -f backend             # Follow backend logs
docker compose logs -f                     # Follow all logs

# ── Shell access ───────────────────────────────────────────
docker exec -it bank-backend sh            # Shell into backend
docker exec -it bank-db psql -U bankuser -d bankdb   # Postgres CLI

# Inside psql:
# \dt                          → list tables
# SELECT * FROM users;
# SELECT * FROM accounts;
# SELECT * FROM transactions;
# \q                           → quit

# ── Rebuild after code changes ────────────────────────────
docker compose up --build backend          # Rebuild only backend
docker compose up --build frontend         # Rebuild only frontend
docker compose up --build                  # Rebuild everything

# ── Cleanup ───────────────────────────────────────────────
docker compose down                        # Stop & remove containers
docker compose down -v                     # Also remove volumes (DELETES DATA)
docker system prune                        # Remove unused images/containers

# ── AI model (pull once after first start) ─────────────────
docker exec -it bank-ollama ollama pull tinyllama
docker exec -it bank-ollama ollama list    # See downloaded models
```

---

## 🛑 Troubleshooting

### Redirected to login but can't log in

The JWT token in your browser may be stale (issued before a backend rebuild with a different secret). Fix:

```javascript
// Run in browser DevTools Console:
localStorage.clear(); window.location.href = '/login.html';
```

Then log in again. To prevent this permanently, set a fixed `JWT_SECRET` in your `.env`.

### Account dropdown is empty after login

You're logged in but have no bank accounts yet. Go to **New Account** in the sidebar and create one first.

### Backend crashes on startup — `Cannot find module 'bcryptjs'`

The `bcryptjs` and `jsonwebtoken` packages are missing from `node_modules`. Fix:

```bash
cd backend
npm install bcryptjs jsonwebtoken
docker compose up --build backend -d
```

### Port already in use

```bash
lsof -i :8080    # find what's using the port
# Change in docker-compose.yml: "9090:80" instead of "8080:80"
```

### Database schema changes not applied

`init.sql` only runs on first volume creation. For schema changes on existing data:

```bash
docker compose down -v && docker compose up --build   # fresh start
# OR apply manually:
docker exec -i bank-db psql -U bankuser -d bankdb < database/init.sql
```

### Backend can't connect to database

```bash
docker compose ps           # check db shows (healthy)
docker compose restart backend
docker compose logs backend
```

---

## ⚙️ CI/CD Pipeline

This project includes GitHub Actions workflows:

### `build-and-push.yml`
Triggered as part of the main pipeline. Builds and pushes Docker images to Docker Hub:
- `manish12588/devops-bank-app-backend:latest` + SHA tag
- `manish12588/devops-bank-app-frontend:latest` + SHA tag

### `deploy.yml`
SSHs into the production EC2 server and:
1. Installs Docker if needed
2. Copies `docker-compose.yml` and `database/init.sql`
3. Creates `.env` with DockerHub credentials and SHA tag
4. Pulls latest images and recreates containers

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_SSH_HOST` | Production server IP |
| `EC2_SSH_USER` | SSH username (e.g. `ubuntu`) |
| `EC2_SSH_PRIVATE_KEY` | SSH private key |
| `JWT_SECRET` | Fixed JWT signing secret |

---

## 🌱 Ideas for Further Learning

1. **Add password reset** — Email-based reset flow with expiring tokens
2. **Add Adminer** — DB admin UI as a 5th container
3. **Add Redis** — Cache sessions or account balances
4. **Docker Secrets** — Store `DB_PASSWORD` and `JWT_SECRET` as Docker secrets
5. **Resource limits** — Add `deploy.resources.limits.memory` to containers
6. **HTTPS** — Add Let's Encrypt via a Traefik or Certbot container
7. **Rate limiting** — Add Nginx rate limiting on `/api/auth/*` routes
8. **Refresh tokens** — Implement token refresh so users stay logged in

---

## 📄 License

MIT — free to use for learning, teaching, and personal projects.
