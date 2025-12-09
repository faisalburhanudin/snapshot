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
COPY cli/package.json ./cli/package.json
COPY packages/sdk/package.json ./packages/sdk/package.json

# Install dependencies and build
RUN yarn install --immutable

# Copy source code
COPY . .

# Build the project
RUN yarn build

# Production dependencies stage
FROM node:20.15.1-bookworm-slim AS prod-deps

# Install build tools needed for native modules
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY cli/package.json ./cli/package.json
COPY packages/sdk/package.json ./packages/sdk/package.json

# Install only production dependencies
ENV NODE_ENV=production
RUN yarn install --immutable

# Final production stage
FROM node:20.15.1-bookworm-slim

# Install only postgresql-client for runtime
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy package metadata
COPY --from=builder /workspace/package.json ./
COPY --from=builder /workspace/cli/package.json ./cli/package.json
COPY --from=builder /workspace/packages/sdk/package.json ./packages/sdk/package.json

# Copy production node_modules
COPY --from=prod-deps /workspace/node_modules ./node_modules
COPY --from=prod-deps /workspace/cli/node_modules ./cli/node_modules
COPY --from=prod-deps /workspace/packages/sdk/node_modules ./packages/sdk/node_modules

# Copy built artifacts
COPY --from=builder /workspace/cli/dist ./cli/dist
COPY --from=builder /workspace/packages/sdk/dist ./packages/sdk/dist

# Set default command
CMD ["/bin/bash"]
