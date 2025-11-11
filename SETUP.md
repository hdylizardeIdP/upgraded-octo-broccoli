# Development Environment Setup Guide

This guide will help you set up the nutrition tracker application for local development.

## Prerequisites

Ensure you have the following installed:

- **Node.js** 20+ ([Download](https://nodejs.org/))
- **Ruby** 3.2+ ([Install via rbenv](https://github.com/rbenv/rbenv))
- **PostgreSQL** 14+ ([Download](https://www.postgresql.org/download/))
- **pnpm** 8+ (Install via: `npm install -g pnpm`)
- **Redis** 4.0+ (Required for background jobs)

## Quick Start

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd upgraded-octo-broccoli

# Install all dependencies (frontend + backend)
pnpm install

# Install Ruby gems for Rails API
cd server
bundle install
cd ..
```

### 2. Set Up Environment Variables

Create `.env` files from the provided examples:

```bash
# Server (Rails API)
cp server/.env.example server/.env

# Web (Next.js)
cp packages/web/.env.example packages/web/.env.local

# Mobile (React Native)
cp packages/mobile/.env.example packages/mobile/.env
```

### 3. Generate Secret Keys

Generate secure secrets for the Rails server:

```bash
# Generate SECRET_KEY_BASE
openssl rand -hex 64

# Generate JWT_SECRET
openssl rand -hex 64
```

Copy these values into `server/.env`:
- Replace `your_secret_key_base_here` with the first generated secret
- Replace `your_jwt_secret_here` with the second generated secret

### 4. Set Up Database

```bash
# Start PostgreSQL (if not already running)
# On macOS: brew services start postgresql
# On Linux: sudo service postgresql start

# Create the database
cd server
rails db:create
rails db:migrate
rails db:seed  # Optional: load sample data

cd ..
```

### 5. Start Development Servers

Open 3 terminal windows:

**Terminal 1 - Rails API Server:**
```bash
cd server
bundle exec rails server
# Runs on http://localhost:3000
```

**Terminal 2 - Next.js Web App:**
```bash
cd packages/web
pnpm dev
# Runs on http://localhost:3001
```

**Terminal 3 - Redis (for background jobs):**
```bash
redis-server
# Or on macOS: brew services start redis
```

### 6. Run Tests

```bash
# Run all tests
pnpm test

# Run specific package tests
cd packages/shared && pnpm test
cd server && bundle exec rspec
```

## Optional: Background Jobs

To process background jobs (e.g., USDA API sync):

```bash
cd server
bundle exec sidekiq
```

## Optional: USDA API Integration

To enable food database lookups from USDA FoodData Central:

1. Get an API key: https://fdc.nal.usda.gov/api-key-signup.html
2. Add to `server/.env`: `USDA_API_KEY=your_key_here`

## Optional: AWS S3 for Image Uploads

For meal/food image uploads:

1. Create an S3 bucket in AWS
2. Create an IAM user with S3 access
3. Add credentials to `server/.env`:
   ```
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   AWS_REGION=us-east-1
   AWS_S3_BUCKET=your-bucket-name
   ```

## Troubleshooting

### Database Connection Issues

If you see `could not connect to server`:
- Ensure PostgreSQL is running: `pg_isready`
- Check DATABASE_URL in `server/.env`

### Port Already in Use

If port 3000 or 3001 is already in use:
- Change PORT in `server/.env` (default: 3000)
- Update NEXT_PUBLIC_API_URL in `packages/web/.env.local`

### Bundle Install Fails

If gems fail to install:
```bash
cd server
bundle config set --local path 'vendor/bundle'
bundle install
```

### React Native Setup

For mobile development, additional setup is required:

**iOS (macOS only):**
```bash
cd packages/mobile
npx pod-install
```

**Android:**
- Install Android Studio
- Set up Android SDK
- Start an emulator

## Next Steps

- Read the [API Documentation](docs/API.md)
- Review the [Database Schema](docs/DATABASE.md)
- Check out [Code Sharing Examples](docs/CODE_SHARING_EXAMPLE.md)

## Need Help?

Refer to:
- [QUICKSTART.md](docs/QUICKSTART.md) - Detailed setup guide
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Codebase overview
- [README.md](README.md) - Project documentation
