FROM nginx:alpine

# Install bash
RUN apk add --no-cache bash

# Stage website source content. Domain selection/copying is handled at runtime.
ENV SITE_SOURCE_ROOT=/opt/sites-src
COPY . ${SITE_SOURCE_ROOT}
RUN mkdir -p /var/www

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy nginx config template
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

# Expose ports
EXPOSE 80 

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
