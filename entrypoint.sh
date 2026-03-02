#!/bin/bash

set -e

# Generate nginx configuration from environment variables
generate_nginx_config() {
    local domains="${DOMAINS}"
    local config_file="/etc/nginx/conf.d/default.conf"
    
    cat > "$config_file" << 'EOF'
# Nginx configuration - auto-generated from environment variables

# Upstream definitions and server blocks will be injected here

EOF

    # Parse domains and create server blocks
    # Split by comma and trim whitespace
    IFS=',' read -ra domain_array <<< "$domains"
    for domain in "${domain_array[@]}"; do
        # Trim whitespace
        domain=$(echo "$domain" | xargs)
        
        # Auto-generate path from domain name
        path="/var/www/$domain"
        
        # Validate domain
        if [ -z "$domain" ]; then
            echo "Warning: Invalid domain, skipping..."
            continue
        fi
        
        # Remove www prefix if present for server_name, but keep it for matching
        domain_without_www="${domain#www.}"
        
        cat >> "$config_file" << EOF
server {
    listen 80;
    server_name $domain www.$domain;
    
    # Set root directory for this domain
    root $path;
    
    # Default file to serve
    index index.html;
    
    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/javascript application/json;
    
    # Cache control for static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # SPA routing - redirect non-existent files to index.html
    location / {
        try_files \$uri /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Access and error logs
    access_log /var/log/nginx/$domain.access.log;
    error_log /var/log/nginx/$domain.error.log;
}

EOF
    done
    
    echo "Generated nginx configuration for domains:"
    IFS=',' read -ra domain_array <<< "$domains"
    for domain in "${domain_array[@]}"; do
        domain=$(echo "$domain" | xargs)
        echo "  $domain -> /var/www/$domain"
    done
}

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting schools-website nginx container..."

# Validate that DOMAINS is set
if [ -z "$DOMAINS" ]; then
    log "ERROR: DOMAINS environment variable not set!"
    log "Please set DOMAINS in .env file with format: 'domain1:/path1 domain2:/path2'"
    exit 1
fi

log "Domains configuration: $DOMAINS"

# Generate nginx config
generate_nginx_config

# Test nginx configuration
log "Testing nginx configuration..."
if ! nginx -t; then
    log "ERROR: Nginx configuration test failed!"
    exit 1
fi

log "Nginx configuration is valid"
log "Starting nginx..."

# Start nginx in foreground
exec nginx -g "daemon off;"
