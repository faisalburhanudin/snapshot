# Base image for CI with pre-built native dependencies
FROM node:20.15.1-bookworm-slim

# Install system dependencies required by better-sqlite3 and postgresql-client
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy package files
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Copy workspace package.json files
COPY cli/package.json ./cli/package.json
COPY packages/sdk/package.json ./packages/sdk/package.json

# Install dependencies (this will compile better-sqlite3 and other native modules)
RUN yarn install --immutable

# The node_modules with compiled binaries are now baked into the image
# Subsequent CI runs can copy source and reuse these compiled dependencies

# Set default command
CMD ["/bin/bash"]
