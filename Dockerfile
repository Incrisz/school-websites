FROM nginx:alpine

# Install bash
RUN apk add --no-cache bash

# Create directories for website files
RUN mkdir -p /var/www


# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy nginx config template
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

# Expose ports
EXPOSE 80 443

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
