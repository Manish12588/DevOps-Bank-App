# app

Application source code for the DevOps Bank App.

## Structure

```
app/
├── backend/              # Node.js/Express REST API
│   ├── Dockerfile        # Multi-stage Docker build (Alpine)
│   ├── package.json      # Dependencies
│   ├── .eslintrc.json    # ESLint config
│   └── server.js         # Express server, JWT auth, API routes
├── frontend/             # Nginx static file server
│   ├── Dockerfile        # Nginx Alpine image
│   ├── nginx.conf        # Reverse proxy config
│   ├── index.html        # Main dashboard SPA
│   ├── login.html        # Login page
│   └── register.html     # Registration page
└── database/
    └── init.sql          # PostgreSQL schema + seed data
```

## Backend API

Base URL: `http://localhost:3000`

### Public endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check (includes DB status) |
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login, returns JWT token |

### Protected endpoints (require `Authorization: Bearer <token>`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/accounts` | List user's accounts |
| POST | `/api/accounts` | Create new account |
| GET | `/api/accounts/:id` | Get account details |
| POST | `/api/accounts/:id/deposit` | Deposit funds |
| POST | `/api/accounts/:id/withdraw` | Withdraw funds |
| POST | `/api/transfer` | Transfer between accounts |
| GET | `/api/transactions` | List all transactions |
| GET | `/api/accounts/:id/transactions` | Account transactions |
| POST | `/api/ai/chat` | Chat with Ollama AI assistant |

## Database Schema

```sql
users        -- id, email, password_hash, full_name, created_at
accounts     -- id, user_id, owner_name, account_type, balance, created_at
transactions -- id, account_id, type, amount, description, balance_after, created_at
```

## Docker Images

| Image | Registry | Tag |
|-------|----------|-----|
| Backend | `manish12588/devops-bank-app-backend` | `latest` + SHA |
| Frontend | `manish12588/devops-bank-app-frontend` | `latest` + SHA |

Images use multi-stage Alpine builds for minimal size.

## 🔮 Future: Testing

> Automated testing is planned for a future iteration:
> - **Unit tests** — Jest for API endpoint testing
> - **Integration tests** — Supertest for database operations
> - **E2E tests** — Playwright for frontend flows
> - **Load tests** — k6 for performance testing
> - Tests will run in CI before Docker build stage
