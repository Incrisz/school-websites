# Multi-Domain Schools Website Docker Container

This setup allows you to run multiple static school websites from different repositories in a single Docker container using nginx with domain-based routing.

## Architecture

```
┌─────────────────────────────────────────────┐
│        Docker Container (nginx)              │
├─────────────────────────────────────────────┤
│  Domain: elbethelacademy.com                 │
│  └─ Routes to: /var/www/elbethelacademy.com │
├─────────────────────────────────────────────┤
│  Domain: hilltop.com.ng                      │
│  └─ Routes to: /var/www/hilltop.com.ng      │
├─────────────────────────────────────────────┤
│  Add more domains by updating .env file      │
└─────────────────────────────────────────────┘
```

## Project Structure

```
schools-website/
├── .env                          # Configuration file with domain mappings
├── .dockerignore                 # Files to exclude from Docker build
├── .gitignore                    # Git ignore rules
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose orchestration
├── entrypoint.sh                 # Container startup script
├── nginx/
│   └── nginx.conf.template       # Nginx configuration template
├── elbethelacademy.com/          # Website files (repo 1)
│   ├── index.html
│   ├── about.html
│   └── ...other files
├── hilltop.com.ng/               # Website files (repo 2)
│   ├── index.html
│   ├── about.html
│   └── ...other files
└── logs/                         # Nginx logs (created on first run)
```

## Quick Start

### 1. Update .env file with your domains

Edit `.env` and add your domain names as a comma-separated array (paths are auto-generated as `/var/www/{domain}`):

```env
DOMAINS="elbethelacademy.com, hilltop.com.ng, schoolname.com"
```

**Format:** `domain1, domain2, domain3` (comma-separated with optional spaces)

**Note:** Each domain is automatically mapped to `/var/www/{domain}` inside the container

### 2. Ensure website files are in correct directories

```bash
# Each domain should have its website files
schools-website/
├── elbethelacademy.com/
│   └── index.html
└── hilltop.com.ng/
    └── index.html
```

### 3. Build and start the container

```bash
# Build the Docker image
docker-compose build

# Start the container
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Test the setup

```bash
# Test locally (add to /etc/hosts if needed)
echo "127.0.0.1 elbethelacademy.com hilltop.com.ng" | sudo tee -a /etc/hosts

# Visit in browser or curl
curl -H "Host: elbethelacademy.com" http://localhost
curl -H "Host: hilltop.com.ng" http://localhost
```

## Adding New Domains

### Method 1: Using .env (Recommended)

1. Update `.env` file:
```env
DOMAINS="elbethelacademy.com, hilltop.com.ng, newschool.com"
```

2. Restart the container:
```bash
docker-compose restart
```

### Method 2: Update docker-compose.yml volumes

Add the new website directory as a volume:

```yaml
volumes:
  - ./elbethelacademy.com:/var/www/elbethelacademy.com:ro
  - ./hilltop.com.ng:/var/www/hilltop.com.ng:ro
  - ./newschool.com:/var/www/newschool.com:ro
```

## Advanced Configuration

### Port Mapping

Change HTTP/HTTPS ports in `.env`:

```env
HTTP_PORT=8080
HTTPS_PORT=8443
```

### SSL/HTTPS Setup

For production, add SSL certificates:

1. Mount certificates in `docker-compose.yml`:
```yaml
volumes:
  - ./ssl/certs:/etc/nginx/certs:ro
```

2. Update `entrypoint.sh` to include HTTPS server blocks

### Domain Aliases

The system automatically creates both `domain` and `www.domain` aliases. Both will serve the same content:

```
✓ elbethelacademy.com
✓ www.elbethelacademy.com
```

## Nginx Configuration Features

✅ **Domain-based routing** - Each domain serves from its own directory
✅ **Gzip compression** - Automatic compression for better performance
✅ **SPA support** - Redirects to index.html for single-page applications
✅ **Cache control** - Static assets cached for 1 year
✅ **Security** - Hidden files (.*) are denied
✅ **Per-domain logging** - Each domain has its own access/error logs

## Troubleshooting

### Container fails to start

```bash
# Check logs
docker-compose logs nginx

# Verify .env syntax
echo $DOMAINS

# Validate configuration
docker-compose exec nginx nginx -t
```

### Cannot access domains

1. Check DNS/hosts file points to container IP
2. Verify domain paths exist in `.env`
3. Check volumes are correctly mounted:
```bash
docker-compose exec nginx ls -la /var/www/
```

### Nginx configuration errors

1. Check that DOMAINS format is correct: `domain1, domain2, domain3` (comma-separated)
2. Verify paths exist
3. Check logs: `docker-compose logs nginx`

## Common Tasks

### View all logs

```bash
docker-compose logs -f
```

### View specific domain logs

```bash
docker-compose exec nginx tail -f /var/log/nginx/elbethelacademy.com.access.log
```

### Reload configuration (without restart)

```bash
docker-compose exec nginx nginx -s reload
```

### Access container shell

```bash
docker-compose exec nginx sh
```

### Stop container

```bash
docker-compose down
```

### Stop and remove all data

```bash
docker-compose down -v
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAINS` | See .env | Comma-separated domain names |
| `HTTP_PORT` | 80 | External HTTP port |
| `HTTPS_PORT` | 443 | External HTTPS port |
| `CONTAINER_NAME` | schools-website-nginx | Docker container name |

## File Permissions

Website files should be stored with read-only permissions in the container (`:ro` flag). This prevents accidental modifications and improves security.

## Performance Tips

- Use CDN for static assets
- Enable browser caching (already configured)
- Compress images
- Minimize CSS/JavaScript
- Use HTTP/2 for better performance
- Consider using cloudflare or similar

## Updating Website Files

To update a website:

1. If files are in a git repository, pull the latest changes:
```bash
cd elbethelacademy.com
git pull
```

2. Reload nginx (it will serve the updated files):
```bash
docker-compose exec nginx nginx -s reload
```

No restart needed - nginx will immediately serve the updated files!

## Production Deployment

For production:

1. Use environment-specific docker-compose files
2. Add SSL certificates
3. Use a reverse proxy (nginx, Traefik, etc.)
4. Implement monitoring and logging
5. Set up auto-restart policies
6. Use volume drivers for persistent storage
7. Implement rate limiting

## Support & Documentation

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Docker Documentation](https://docs.docker.com/)
# school-websites
