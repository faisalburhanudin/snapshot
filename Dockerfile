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

# Build the project and create standalone binary
RUN yarn build && \
    cd cli && \
    yarn build:binary

# Production stage - minimal runtime
FROM debian:bookworm-slim

# Install only postgresql-client for runtime
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy only the standalone binary
COPY --from=builder /workspace/cli/bin/cli /usr/local/bin/snaplet

# Set default command
CMD ["/bin/bash"]
