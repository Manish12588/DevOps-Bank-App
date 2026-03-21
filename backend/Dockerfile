# ── Stage 1: Install dependencies ──────────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only package files first (layer caching: npm install runs only when deps change)
COPY package*.json ./
RUN npm install --omit=dev

# ── Stage 2: Final runtime image ────────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /app

# Create a non-root user for security (best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy installed modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source
COPY server.js ./

# Own files as non-root user
RUN chown -R appuser:appgroup /app
USER appuser

# Document which port the app listens on (informational)
EXPOSE 3000

# Health check so Docker knows when the container is ready
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
