FROM node:18.15.0-bullseye-slim AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm test -- --runInBand && npm prune --omit=dev

FROM node:18.15.0-bullseye-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=8000

COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/package*.json ./
COPY --from=build --chown=node:node /app/index.js ./
COPY --from=build --chown=node:node /app/users ./users
COPY --from=build --chown=node:node /app/shared ./shared

USER node

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:8000/health', response => process.exit(response.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "index.js"]
