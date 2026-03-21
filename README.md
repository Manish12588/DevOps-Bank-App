# 🏦 NexaBank — Docker Three-Tier Learning App

A fully containerized **three-tier banking application** designed to teach Docker and Docker Compose through a real, working project.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Host (your machine)             │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              bank-network (bridge)                   │   │
│  │                                                      │   │
│  │  ┌────────────┐    ┌────────────┐   ┌─────────────┐ │   │
│  │  │  TIER 1    │    │  TIER 2    │   │   TIER 3    │ │   │
│  │  │  Frontend  │───▶│  Backend   │──▶│  Database   │ │   │
│  │  │   Nginx    │    │  Node.js   │   │ PostgreSQL  │ │   │
│  │  │  :80       │    │  :3000     │   │  :5432      │ │   │
│  │  └────────────┘    └────────────┘   └─────────────┘ │   │
│  │         │                 │                          │   │
│  └─────────┼─────────────────┼──────────────────────────┘   │
│            │                 │                               │
│         :8080             :3000                              │
│      (browser)          (API/curl)                          │
└─────────────────────────────────────────────────────────────┘
```

| Tier | Service    | Technology      | Internal Port | Host Port |
|------|------------|-----------------|--------------|-----------|
| 1    | `frontend` | Nginx + HTML/JS | 80           | **8080**  |
| 2    | `backend`  | Node.js/Express | 3000         | **3000**  |
| 3    | `db`       | PostgreSQL 15   | 5432         | —         |

---

## 📦 Project Structure

```
bank-app/
├── docker-compose.yml        ← Orchestrates all three containers
├── .env.example              ← Environment variable template
├── .gitignore
│
├── frontend/
│   ├── Dockerfile            ← Nginx image serving static files
│   ├── nginx.conf            ← Nginx server block config
│   └── index.html            ← SPA with dashboard, accounts, operations
│
├── backend/
│   ├── Dockerfile            ← Multi-stage Node.js build
│   ├── package.json
│   └── server.js             ← Express REST API (all business logic)
│
└── database/
    └── init.sql              ← Schema + seed data (runs on first start)
```

---

## 🚀 Quick Start

### Prerequisites

Make sure you have these installed:

```bash
docker --version        # Docker 24+ recommended
docker compose version  # Docker Compose v2 (built into Docker Desktop)
```

### 1. Clone / Download the project

```bash
# If using git:
git clone <your-repo-url>
cd bank-app

# Or just cd into the folder:
cd bank-app
```

### 2. Start everything

```bash
docker compose up --build
```

> **What this does:**
> - Builds Docker images for `frontend` and `backend`
> - Pulls the `postgres:15-alpine` image from Docker Hub
> - Creates a bridge network (`bank-network`)
> - Creates a named volume (`bank-pgdata`) for database persistence
> - Starts all three containers in dependency order:
>   `db` → `backend` → `frontend`

### 3. Open the app

Once you see `bank-backend  | Bank API running on port 3000` in the logs:

- **🌐 App:** http://localhost:8080
- **⚙️ API:** http://localhost:3000
- **❤️ Health:** http://localhost:3000/health

### 4. Stop everything

```bash
# Stop but keep data:
docker compose down

# Stop AND delete database data:
docker compose down -v
```

---

## 🎯 Features

- **Dashboard** — Real-time balance stats across all accounts
- **Accounts** — View all accounts, click to see transaction history
- **Deposit / Withdraw / Transfer** — Full money operations with validation
- **Create Account** — Open new Savings, Checking, or Business accounts
- **Architecture page** — Learn how the tiers connect inside the UI

---

## 🐳 Docker Concepts You'll Learn

### Dockerfile (backend)

The backend uses a **multi-stage build** to keep the final image small:

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

# Stage 2: Final image (no build tools)
FROM node:20-alpine
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./
```

**Why multi-stage?** The `deps` stage has npm/build tools. The final stage copies only what's needed — smaller, more secure image.

### docker-compose.yml

Key concepts used in this file:

| Concept | Where used | What it does |
|---------|-----------|--------------|
| `services` | all | Defines the 3 containers |
| `build.context` | frontend, backend | Which folder to build from |
| `image` | db | Use official image directly |
| `environment` | all | Pass env vars into containers |
| `ports` | frontend, backend | Map host port → container port |
| `networks` | all | Put containers on shared network |
| `volumes` | db | Persist Postgres data |
| `depends_on` | backend, frontend | Start-order control |
| `healthcheck` | all | Know when a service is ready |
| `restart: unless-stopped` | all | Auto-restart on crash |

### Networking

Containers on the same Docker network find each other by **service name**:

```
backend connects to DB using:  host=db  port=5432
```

Not `localhost` — because each container has its own network namespace. `db` resolves to the `db` container's IP on `bank-network`.

### Volumes

```yaml
volumes:
  bank-pgdata:           # Named volume
```

The database files live in `bank-pgdata` on your Docker host. Even if you delete the `bank-db` container, the data survives. Only `docker compose down -v` removes it.

### Healthchecks + depends_on

```yaml
backend:
  depends_on:
    db:
      condition: service_healthy
```

Without this, the backend might start before Postgres is ready and crash. The `service_healthy` condition waits for the `db` healthcheck to pass first.

---

## 🔌 API Reference

All endpoints are available at `http://localhost:3000`.

### Health

```bash
GET /health
# → { "status": "ok", "db": "connected" }
```

### Accounts

```bash
# List all accounts
GET /api/accounts

# Get one account
GET /api/accounts/:id

# Create new account
POST /api/accounts
Content-Type: application/json
{ "owner_name": "Jane Doe", "account_type": "SAVINGS", "initial_balance": 1000 }
```

### Transactions

```bash
# Deposit
POST /api/accounts/:id/deposit
{ "amount": 500, "description": "Salary" }

# Withdraw
POST /api/accounts/:id/withdraw
{ "amount": 200, "description": "Groceries" }

# Transfer between accounts
POST /api/transfer
{ "from_account_id": 1, "to_account_id": 2, "amount": 100, "description": "Rent" }

# Get transactions for account
GET /api/accounts/:id/transactions

# Get all transactions
GET /api/transactions
```

### Test with curl

```bash
# Check health
curl http://localhost:3000/health

# List accounts
curl http://localhost:3000/api/accounts | jq

# Deposit €500 into account 1
curl -X POST http://localhost:3000/api/accounts/1/deposit \
  -H "Content-Type: application/json" \
  -d '{"amount": 500, "description": "Test deposit"}'

# Transfer €100 from account 1 to account 2
curl -X POST http://localhost:3000/api/transfer \
  -H "Content-Type: application/json" \
  -d '{"from_account_id": 1, "to_account_id": 2, "amount": 100}'
```

---

## 🔍 Useful Docker Commands

```bash
# ── Running containers ─────────────────────────────────────
docker compose ps                  # See status of all containers
docker ps                          # All running containers

# ── Logs ──────────────────────────────────────────────────
docker compose logs                # All service logs
docker compose logs backend        # Logs for one service
docker compose logs -f backend     # Follow (tail) logs

# ── Exec into containers ───────────────────────────────────
docker exec -it bank-backend sh    # Shell into backend
docker exec -it bank-db psql -U bankuser -d bankdb  # Postgres CLI

# Inside psql:
# \dt                → list tables
# SELECT * FROM accounts;
# SELECT * FROM transactions;
# \q                 → quit

# ── Images ────────────────────────────────────────────────
docker images                      # List all images
docker image ls                    # Same
docker image inspect bank-app-backend  # Full image metadata

# ── Volumes ───────────────────────────────────────────────
docker volume ls                   # List volumes
docker volume inspect bank-pgdata  # Volume details

# ── Networks ──────────────────────────────────────────────
docker network ls                  # List networks
docker network inspect bank-network  # See connected containers

# ── Rebuild after code changes ────────────────────────────
docker compose up --build backend  # Rebuild only backend
docker compose up --build          # Rebuild everything

# ── Cleanup ───────────────────────────────────────────────
docker compose down                # Stop & remove containers
docker compose down -v             # Also remove volumes (DELETES DATA)
docker system prune                # Remove unused images/containers
```

---

## 🛑 Troubleshooting

### Port already in use

```bash
# Check what's using port 8080 or 3000
lsof -i :8080
lsof -i :3000

# Change ports in docker-compose.yml:
ports:
  - "9090:80"   # use 9090 instead of 8080
```

### Backend can't connect to database

The backend waits for the DB healthcheck, but sometimes needs an extra moment. Try:

```bash
docker compose restart backend
```

Also verify DB is healthy:
```bash
docker compose ps
# db should show "(healthy)"
```

### Database init script not running

The `init.sql` only runs when the volume is **first created**. If you've run the app before with a different schema:

```bash
docker compose down -v    # delete the old volume
docker compose up --build # start fresh
```

### Can't reach API at localhost:3000

Make sure the backend container is running:

```bash
docker compose ps backend
docker compose logs backend
```

---

## 🌱 Ideas for Further Learning

1. **Add a `.env` file** — Move credentials out of `docker-compose.yml` using `env_file:` or variable substitution `${VAR}`
2. **Add Adminer** — A DB admin UI container (add it to `docker-compose.yml`)
3. **Add Redis** — Cache account balances in a 4th container
4. **Docker Secrets** — Store `DB_PASSWORD` as a Docker secret instead of env var
5. **Resource limits** — Add `deploy.resources.limits.memory` to containers
6. **Separate compose files** — `docker-compose.yml` + `docker-compose.override.yml` for dev vs prod
7. **Build your own image** — Replace `postgres:15-alpine` with a custom image that bakes in the schema

---

## 📄 License

MIT — free to use for learning, teaching, and personal projects.
