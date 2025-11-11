# Nutrition Tracker - Docker Setup

This project uses Docker to containerize all services for easy development and deployment.

## Prerequisites

- Docker 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- Docker Compose 2.0+ ([Install Docker Compose](https://docs.docker.com/compose/install/))

## Quick Start

### Production Build

```bash
# Set up environment variables
cp server/.env.example server/.env
# Edit server/.env and set SECRET_KEY_BASE and JWT_SECRET

# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

Services will be available at:
- **API**: http://localhost:3000
- **Web**: http://localhost:3001
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### Development Mode

For local development with hot reloading:

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up --build

# Run database migrations
docker-compose -f docker-compose.dev.yml exec api bundle exec rails db:migrate

# Create a console session
docker-compose -f docker-compose.dev.yml exec api bundle exec rails console

# Run tests
docker-compose -f docker-compose.dev.yml exec api bundle exec rspec
```

## Services

### 1. PostgreSQL Database
- **Image**: postgres:16-alpine
- **Port**: 5432
- **Database**: nutrition_tracker_development
- **User**: postgres
- **Password**: postgres (dev only, change for production!)

### 2. Redis
- **Image**: redis:7-alpine
- **Port**: 6379
- **Purpose**: Sidekiq background jobs, caching

### 3. Rails API
- **Port**: 3000
- **Framework**: Rails 7.1.6 (API-only)
- **Features**: JWT authentication, RESTful API
- **Endpoints**: http://localhost:3000/api/v1

### 4. Sidekiq
- **Purpose**: Background job processing
- **Queue**: USDA API sync, email notifications
- **Dashboard**: (to be configured)

### 5. Next.js Web
- **Port**: 3001
- **Framework**: Next.js 14.2.3
- **URL**: http://localhost:3001

## Docker Commands Cheat Sheet

```bash
# Build all services
docker-compose build

# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service_name]

# Execute command in running container
docker-compose exec api bundle exec rails console
docker-compose exec postgres psql -U postgres nutrition_tracker_development

# Remove all containers and volumes (fresh start)
docker-compose down -v

# Rebuild single service
docker-compose build api
docker-compose up -d api
```

## Environment Variables

Create these files before running:

**server/.env**:
```env
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/nutrition_tracker_development
REDIS_URL=redis://redis:6379/0
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base
JWT_SECRET=your_jwt_secret
```

**packages/web/.env.local** (for local development):
```env
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
```

## Troubleshooting

### Database Connection Issues

```bash
# Check if PostgreSQL is healthy
docker-compose ps

# View PostgreSQL logs
docker-compose logs postgres

# Recreate database
docker-compose exec api bundle exec rails db:drop db:create db:migrate
```

### Port Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Or change ports in docker-compose.yml
```

### Cache Issues

```bash
# Rebuild without cache
docker-compose build --no-cache

# Remove all images and rebuild
docker-compose down --rmi all
docker-compose up --build
```

### Volume Permission Issues

```bash
# Reset volumes
docker-compose down -v
docker-compose up
```

## Production Deployment

For production deployment:

1. **Update environment variables**:
   - Set strong SECRET_KEY_BASE and JWT_SECRET
   - Configure ALLOWED_ORIGINS for CORS
   - Set up AWS S3 credentials
   - Add USDA_API_KEY

2. **Use production docker-compose**:
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

3. **Set up SSL/TLS**:
   - Use a reverse proxy (nginx, Caddy)
   - Configure SSL certificates (Let's Encrypt)

4. **Database backups**:
   ```bash
   docker-compose exec postgres pg_dump -U postgres nutrition_tracker_development > backup.sql
   ```

5. **Monitoring**:
   - Add health check endpoints
   - Configure logging aggregation
   - Set up application monitoring (Sentry, etc.)

## Development Workflow

1. **Make code changes** - Files are mounted as volumes, changes reflect immediately
2. **Restart services if needed** - `docker-compose restart api`
3. **Run migrations** - `docker-compose exec api bundle exec rails db:migrate`
4. **Run tests** - `docker-compose exec api bundle exec rspec`
5. **View logs** - `docker-compose logs -f api`

## Next Steps

- [ ] Configure Sidekiq dashboard
- [ ] Add nginx reverse proxy
- [ ] Set up SSL certificates
- [ ] Configure production secrets
- [ ] Add health check monitoring
- [ ] Set up automated backups
- [ ] Add CI/CD pipeline
