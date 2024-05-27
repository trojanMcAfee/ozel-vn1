# Stage 1: Node.js stage for npm dependencies and potential build processes
FROM node:18 AS node-base
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Foundry stage to include Foundry in the final image
FROM ghcr.io/foundry-rs/foundry as foundry-base
WORKDIR /ozel-vn1/contracts

# Copy over the node modules and build artifacts from the Node.js stage
COPY --from=node-base /app .

# Ensure all necessary files are copied
COPY . .

# Set executable permissions for start.sh
RUN chmod +x /ozel-vn1/contracts/start.sh

CMD ["/ozel-vn1/contracts/start.sh"]
