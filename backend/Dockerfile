# ── Stage 1: Install dependencies ─────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ── Stage 2: Production image ─────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

# Security: run as non-root user
RUN addgroup -S wattwise && adduser -S wattwise -G wattwise

# Copy deps from stage 1
COPY --from=deps /app/node_modules ./node_modules
# Copy source
COPY . .

# Don't run as root
USER wattwise

EXPOSE 5000
ENV NODE_ENV=production

CMD ["node", "src/app.js"]