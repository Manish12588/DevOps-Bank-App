# ============================================================
# Single Image — Bank App (Frontend + Backend)
# The same image is used for both services in docker-compose.
# The ROLE env var at runtime selects which process to start:
#   ROLE=frontend  →  Nginx serving static files
#   ROLE=backend   →  Node.js API server
# ============================================================

# ── Stage 1: Install Node dependencies ────────────────────────────────────────
FROM node:20-slim AS node-deps
WORKDIR /app
COPY backend/package*.json ./
RUN npm install --omit=dev

# ── Stage 2: Final image (Node + Nginx in one) ────────────────────────────────
FROM node:20-slim

# Install Nginx
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Backend files ─────────────────────────────────────────────────────────────
WORKDIR /app
COPY --from=node-deps /app/node_modules ./node_modules
COPY backend/server.js ./

# ── Frontend files ────────────────────────────────────────────────────────────
COPY frontend/index.html /usr/share/nginx/html/index.html
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/default

# ── Entrypoint: start correct process based on ROLE env var ───────────────────
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 3000

ENTRYPOINT ["/docker-entrypoint.sh"]
