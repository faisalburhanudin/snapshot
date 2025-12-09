# Builder stage
FROM node:20.15.1-bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Copy workspace package.json files
COPY cli/package.json ./cli/package.json
COPY packages/sdk/package.json ./packages/sdk/package.json

# Install dependencies
RUN yarn install --immutable

# Copy source code
COPY . .

# Build the project
RUN yarn build

# Production stage
FROM node:20.15.1-bookworm-slim

# Install only runtime dependencies (needed for better-sqlite3)
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY cli/package.json ./cli/package.json
COPY packages/sdk/package.json ./packages/sdk/package.json

# Install only production dependencies
ENV NODE_ENV=production
RUN yarn install --immutable && yarn cache clean

# Copy built artifacts from builder
COPY --from=builder /workspace/cli/dist ./cli/dist
COPY --from=builder /workspace/packages/sdk/dist ./packages/sdk/dist

# Set default command
CMD ["/bin/bash"]
