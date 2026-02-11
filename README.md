# ditio.org Deployment

Deployment automation for the [ditio.org](https://ditio.org) website using Docker Compose.
**This is not final and lacks several important features.** In particular:
- HTTPS secure traffic
- Redis caching layer

_Note:_ Environment variables added or renamed in the frontend/backend MUST be reflected here prior to deployment. Always make sure to run the staging environment with success and updating environment before deploying.

## Overview

This repository contains the deployment configuration for the ditio.org website, managed by Ditio Linjeforeningen. The deployment uses Docker Compose to orchestrate a multi-container application consisting of:

- **Frontend**: Vite/React-based web interface served by nginx alpine
- **Backend**: Spring Boot API service
- **PostgreSQL**: Database for persistent storage
- **Nginx**: Reverse proxy for routing traffic

## Architecture

The application is deployed as a containerized stack with the following components:

```
                    ┌─────────┐
                    │  Nginx  │ (Port 80)
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

- Docker 28 or later
- Docker Compose
- [Nix](https://nixos.org/) (optional, for development environment)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ditio-Linjeforeningen/ditio.org-deployment.git
   cd ditio.org-deployment
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` to configure your deployment:
   - `POSTGRES_USER`: PostgreSQL username
   - `POSTGRES_PASSWORD`: PostgreSQL password
   - `POSTGRES_DB`: PostgreSQL database name
   - `SPRING_DATASOURCE_URL`: JDBC connection URL for the backend
   - `BACKEND_URL`: Internal backend URL (used by frontend)
   - `FRONTEND_TAG`: Docker image tag for the frontend (e.g., `candidate`, `dev`, or specific version)
   - `BACKEND_TAG`: Docker image tag for the backend (e.g., `candidate`, `dev`, or specific version)

3. **Start the application**
   ```bash
   docker compose up -d
   ```

4. **Access the application**
   - Open your browser and navigate to `http://localhost`
   - API endpoints are available at `http://localhost/api`

## Configuration

### Environment Variables

The deployment requires a `.env` file with the following variables:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/postgres
BACKEND_URL=http://backend
FRONTEND_TAG=candidate
BACKEND_TAG=candidate
```

### Docker Images

The deployment uses the following Docker images:

- **Frontend**: `ditiocorporate/ditio.org-frontend:${FRONTEND_TAG}`
- **Backend**: `ditiocorporate/ditio.org-backend:${BACKEND_TAG}`
- **PostgreSQL**: `postgres:18`
- **Nginx**: `nginx:1.29.5`

### Nginx Configuration

The Nginx reverse proxy is configured to:
- Route `/api/*` requests to the backend service
- Route all other requests to the frontend service
- Set appropriate proxy headers for proper request forwarding

See [`nginx.conf`](nginx.conf) for the full configuration.

## Services

### Frontend
- **Image**: `ditiocorporate/ditio.org-frontend`
- **Port**: 80 (internal)
- **Description**: Next.js web application

### Backend
- **Image**: `ditiocorporate/ditio.org-backend`
- **Port**: 8080 (internal)
- **Description**: Spring Boot REST API
- **Dependencies**: PostgreSQL (waits for database health check)

### PostgreSQL
- **Image**: `postgres:18`
- **Port**: 5432 (internal)
- **Description**: Relational database
- **Volume**: Persistent data stored in `postgres_data` volume
- **Health Check**: Validates database readiness using `pg_isready`

### Nginx
- **Image**: `nginx:1.29.5`
- **Port**: 80 (exposed to host)
- **Description**: Reverse proxy and load balancer
- **Configuration**: Mounted from `./nginx.conf`

## Development

### Using Nix

This repository includes a Nix flake for reproducible development environments.

```bash
# Enter the development shell
nix develop

# Docker 28 will be available
docker --version
```

The flake is configured for `x86_64-linux` systems and includes Docker 28 as a dependency.

## Deployment Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes database data)
docker compose down -v

# Restart a specific service
docker compose restart backend

# Pull latest images
docker compose pull

# Rebuild and restart
docker compose up -d --build
```

## Volumes

- **postgres_data**: Persists PostgreSQL database files

## Networking

All services communicate on a default Docker Compose network. Services are accessible by their service name:
- `postgres:5432` (from backend)
- `backend:8080` (from nginx)
- `frontend:80` (from nginx)

## Health Checks

The PostgreSQL service includes a health check that:
- Runs every 10 seconds
- Times out after 5 seconds
- Retries up to 5 times
- Uses `pg_isready` to verify database availability

The backend service depends on this health check and will restart if PostgreSQL becomes unhealthy.

## Troubleshooting

### Services won't start
```bash
# Check service logs
docker compose logs

# Check service status
docker compose ps
```

### Database connection issues
```bash
# Verify PostgreSQL is healthy
docker compose ps postgres

# Check backend environment variables
docker compose exec backend env | grep POSTGRES
```

### Nginx routing issues
```bash
# Test backend connectivity
curl http://localhost/api/health

# View nginx logs
docker compose logs nginx
```

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Test your changes locally
4. Submit a pull request

## License

This project is maintained by [Ditio Linjeforeningen](https://github.com/Ditio-Linjeforeningen).

## Support

For issues or questions, please open an issue on GitHub or contact the Ditio Linjeforeningen team.
