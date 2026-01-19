FROM node:20-slim AS base

# ENV NODE_ENV=production
# ENV NEXT_TELEMETRY_DISABLED=1
# ENV PNPM_HOME="/pnpm"
# ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable pnpm

FROM base AS prod-deps
WORKDIR /app
# RUN pnpm store path
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,sharing=shared,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=prod-deps /app/node_modules ./node_modules
COPY . .
RUN --mount=type=cache,id=pnpm,sharing=shared,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

FROM base
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]

