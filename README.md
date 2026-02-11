# ditio.org Deployment

Deployment automation for the [ditio.org](https://ditio.org) website using Docker Compose and NixOS.

> **⚠️ Work in Progress**  
> This deployment configuration is under active development and currently lacks:
> - HTTPS/TLS support
> - Redis caching layer
> - Production-grade security hardening

> **📝 Important Note**  
> Environment variables added or renamed in the frontend/backend repositories MUST be reflected in this deployment configuration before deploying. Always test in staging first.

## Overview

This repository contains the deployment configuration for the ditio.org website, managed by Ditio Linjeforeningen. It supports two deployment methods:

1. **Docker Compose**: Containerized deployment for development and staging
2. **NixOS**: Declarative system configuration for production servers

### Stack Components

- **Frontend**: React-based web interface served by nginx
- **Backend**: Spring Boot API service
- **PostgreSQL**: Database for persistent storage (PostgreSQL 18)
- **Nginx**: Reverse proxy for routing traffic

## Architecture

The application is deployed as a containerized stack with the following components:

```
                    ┌─────────┐
                    │  Nginx  │ (Ports 80/443)
                    └────┬────┘
                         │
            ┌────────────┴────────────┐
            │                         │
       ┌────▼────┐             ┌─────▼─────┐
       │Frontend │             │  Backend  │
       │(Port 80)│             │(Port 8080)│
       └─────────┘             └─────┬─────┘
                                     │
                              ┌──────▼──────┐
                              │ PostgreSQL  │
                              │ (Port 5432) │
                              └─────────────┘
```

## Prerequisites

### For Docker Compose Deployment
- Docker 28 or later
- Docker Compose v2

### For NixOS Deployment
- [Nix](https://nixos.org/) with flakes enabled
- SSH access to target server
- `nixos-anywhere` (included in development shell)

## Quick Start (Docker Compose)

### 1. Clone the repository
```bash
git clone https://github.com/Ditio-Linjeforeningen/ditio.org-deployment.git
cd ditio.org-deployment
```

### 2. Configure environment variables
```bash
cp .env.example .env
```

Edit `.env` with your configuration:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL username | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `changeme` |
| `POSTGRES_DB` | PostgreSQL database name | `postgres` |
| `SPRING_DATASOURCE_URL` | JDBC connection URL | `jdbc:postgresql://postgres:5432/postgres` |
| `BACKEND_URL` | Internal backend URL | `http://backend` |
| `FRONTEND_TAG` | Frontend Docker image tag | `candidate`, `dev`, or version |
| `BACKEND_TAG` | Backend Docker image tag | `candidate`, `dev`, or version |
| `NGINX_CONF_FILE` | Nginx config file to use | `staging.conf` or `production.conf` |

### 3. Start the application
```bash
docker compose up -d
```

### 4. Access the application
- **Website**: http://localhost
- **API**: http://localhost/api

## Docker Images

The deployment uses the following images:

| Component | Image | Tag Variable |
|-----------|-------|--------------|
| Frontend | `ditiocorporate/ditio.org-frontend` | `${FRONTEND_TAG}` |
| Backend | `ditiocorporate/ditio.org-backend` | `${BACKEND_TAG}` |
| PostgreSQL | `postgres:18` | Fixed |
| Nginx | `nginx:1.29.5` | Fixed |

## Services Configuration

### Frontend
- **Image**: `ditiocorporate/ditio.org-frontend:${FRONTEND_TAG}`
- **Port**: 80 (internal only)
- **Description**: React web application served by nginx

### Backend
- **Image**: `ditiocorporate/ditio.org-backend:${BACKEND_TAG}`
- **Port**: 8080 (internal only)
- **Description**: Spring Boot REST API
- **Dependencies**: Waits for PostgreSQL health check before starting

### PostgreSQL
- **Image**: `postgres:18`
- **Port**: 5432 (internal only)
- **Volume**: `postgres_data` - persists database files
- **Health Check**: Uses `pg_isready` to verify availability
  - Interval: 10 seconds
  - Timeout: 5 seconds
  - Retries: 5 attempts

### Nginx
- **Image**: `nginx:1.29.5`
- **Ports**: 
  - 80 (HTTP) - exposed to host
  - 443 (HTTPS) - exposed to host (not yet configured)
- **Configuration**: Loaded from `./nginx-conf/${NGINX_CONF_FILE}`
- **Routing**:
  - `/api/*` → Backend service
  - `/*` → Frontend service

## Docker Compose Commands

```bash
# Start all services
docker compose up -d

# View logs from all services
docker compose logs -f

# View logs from specific service
docker compose logs -f backend

# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes database data)
docker compose down -v

# Restart a specific service
docker compose restart backend

# Pull latest images
docker compose pull

# Update and restart services
docker compose pull && docker compose up -d

# Check service status
docker compose ps
```

## NixOS Deployment

This repository includes a NixOS configuration for declarative server deployment using `nixos-anywhere`.

### Development Shell

Enter the Nix development environment with all required tools:

```bash
nix develop
```

This provides:
- Docker 28
- nixos-anywhere
- Other deployment utilities

### Bootstrap a New Server

Set required environment variables:

```bash
export SERVER_HOST="your-server-ip-or-hostname"
export SSH_BOOTSTRAP_KEY="$(cat ~/.ssh/id_ed25519)"
```

Run the bootstrap script:

```bash
nix run .#nixos-anywhere-bootstrap
```

This will:
1. Configure SSH access
2. Deploy the NixOS configuration to the target server
3. Generate hardware-specific configuration

### NixOS Configuration

The server configuration is defined in `./server/configuration.nix` and uses:
- **disko**: Declarative disk partitioning
- **flake-parts**: Modular flake configuration
- **nixos-facter-modules**: Hardware detection

## Networking

All services communicate on a Docker Compose network. Internal DNS resolution:
- `postgres:5432` - Database (accessible from backend)
- `backend:8080` - API (accessible from nginx)
- `frontend:80` - Web app (accessible from nginx)

## Volumes

| Volume | Purpose |
|--------|---------|
| `postgres_data` | Persists PostgreSQL database files across container restarts |

## Troubleshooting

### Services won't start

```bash
# Check all service logs
docker compose logs

# Check specific service
docker compose logs backend

# Check service status
docker compose ps
```

### Database connection issues

```bash
# Verify PostgreSQL is healthy
docker compose ps postgres

# Check database logs
docker compose logs postgres

# Check backend environment variables
docker compose exec backend env | grep -E "POSTGRES|SPRING"

# Test database connection
docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT version();"
```

### Nginx routing issues

```bash
# View nginx logs
docker compose logs nginx

# Test backend connectivity (if health endpoint exists)
curl http://localhost/api/health

# Check nginx configuration
docker compose exec nginx nginx -t
```

### Image pull issues

```bash
# Login to Docker registry if needed
docker login

# Pull images manually
docker pull ditiocorporate/ditio.org-frontend:candidate
docker pull ditiocorporate/ditio.org-backend:candidate

# Check available tags
docker images | grep ditiocorporate
```

## Project Structure

```
.
├── .env.example              # Environment variables template
├── .github/                  # GitHub Actions workflows
├── compose.yaml              # Docker Compose configuration
├── flake.nix                 # Nix flake configuration
├── flake.lock                # Locked dependency versions
├── hardware-configuration.nix # Server hardware configuration
├── nginx-conf/               # Nginx configuration files
│   ├── staging.conf
│   └── production.conf
├── server/                   # NixOS server configuration
│   └── configuration.nix
└── README.md                 # This file
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** to your GitHub account
2. **Create a feature branch** from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Test your changes** in a local environment
   ```bash
   docker compose up -d
   # Verify everything works
   ```
4. **Commit with clear messages**
   ```bash
   git commit -m "Add: brief description of changes"
   ```
5. **Submit a pull request** with:
   - Clear description of changes
   - Any relevant issue references
   - Testing steps performed

### Development Workflow

- Use staging environment (`FRONTEND_TAG=dev`, `BACKEND_TAG=dev`) for testing
- Update `.env.example` if adding new environment variables
- Document any new configuration options in this README

## Security Considerations

> **⚠️ Important for Production**

This configuration is currently suitable for development and staging. For production:

- [ ] Enable HTTPS with valid SSL/TLS certificates (Let's Encrypt recommended)
- [ ] Change default PostgreSQL credentials
- [ ] Use Docker secrets or external secret management
- [ ] Configure firewall rules
- [ ] Enable PostgreSQL authentication
- [ ] Review and harden nginx configuration
- [ ] Implement rate limiting
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy for `postgres_data` volume

## License

This project is maintained by [Ditio Linjeforeningen](https://github.com/Ditio-Linjeforeningen).

## Support

For issues or questions:
- **GitHub Issues**: [Open an issue](https://github.com/Ditio-Linjeforeningen/ditio.org-deployment/issues)
- **Contact**: Reach out to the Ditio Linjeforeningen team

---

**Last Updated**: February 2026
