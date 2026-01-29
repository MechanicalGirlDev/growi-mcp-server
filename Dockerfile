# Build stage
FROM node:22-slim AS builder

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source files
COPY src ./src
COPY tsconfig.json ./
COPY LICENSE ./

# Build the application
RUN pnpm build

# Production stage
FROM node:22-slim AS production

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1000 node_group && \
    useradd --uid 1000 --gid node_group --shell /bin/bash --create-home app_user || true

# Copy built files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# Set environment
ENV NODE_ENV=production

# Switch to non-root user
USER 1000

# Run the MCP server
CMD ["node", "dist/index.js"]
