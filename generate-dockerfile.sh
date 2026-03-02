#!/bin/bash

# Script to generate Dockerfile with dynamic COPY commands based on .env
# Generates Dockerfile directly with COPY commands for each domain

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
DOCKERFILE="$SCRIPT_DIR/Dockerfile"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Read DOMAINS from .env
log "Reading domains from .env..."
DOMAINS=$(grep "^DOMAINS=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"')

if [ -z "$DOMAINS" ]; then
    echo "Error: DOMAINS not configured in .env"
    exit 1
fi

log "Found domains: $DOMAINS"

# Generate COPY commands
COPY_COMMANDS=""
IFS=',' read -ra domain_array <<< "$DOMAINS"
for domain in "${domain_array[@]}"; do
    domain=$(echo "$domain" | xargs)
    
    if [ ! -d "$domain" ]; then
        warn "Directory '$domain' not found - please create it"
    else
        log "Found: $domain/"
    fi
    
    COPY_COMMANDS="$COPY_COMMANDS
COPY $domain/ /var/www/$domain/"
done

# Remove leading newline
COPY_COMMANDS=$(echo "$COPY_COMMANDS" | sed '1s/^//')

# Generate Dockerfile
cat > "$DOCKERFILE" << EOF
FROM nginx:alpine

# Install bash
RUN apk add --no-cache bash

# Create directories for website files
RUN mkdir -p /var/www

# Copy website directories
$COPY_COMMANDS

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy nginx config template
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

# Expose ports
EXPOSE 80 443

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
EOF

success "Generated Dockerfile"
log "Ready to build. Domains:"
IFS=',' read -ra domain_array <<< "$DOMAINS"
for domain in "${domain_array[@]}"; do
    domain=$(echo "$domain" | xargs)
    echo "  → $domain"
done
echo ""
echo "Next steps:"
echo "  docker build -t schools-website ."
echo ""
