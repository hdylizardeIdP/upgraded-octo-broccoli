# Quick Start Guide

This guide will help you get the nutrition tracker app running locally in development mode.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required for All Development
- **Node.js 20+** and **pnpm 8+**
  ```bash
  node --version  # Should be 20.x or higher
  pnpm --version  # Should be 8.x or higher
  ```
  
- **PostgreSQL 14+**
  ```bash
  psql --version  # Should be 14.x or higher
  ```

- **Ruby 3.2+** and **Rails 7.1+**
  ```bash
  ruby --version   # Should be 3.2.x or higher
  rails --version  # Should be 7.1.x or higher
  ```

### Required for Mobile Development (Optional for Web-Only)
- **Xcode 15+** (for iOS development on macOS)
- **Android Studio** (for Android development)
- **React Native CLI**
  ```bash
  npm install -g react-native-cli
  ```

---

## Step-by-Step Setup

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone https://github.com/yourusername/nutrition-tracker.git
cd nutrition-tracker

# Install Node.js dependencies for all packages
pnpm install

# Install Ruby dependencies for Rails API
cd server
bundle install
cd ..
```

### 2. Configure Environment Variables

#### Web App (.env.local)
```bash
cd packages/web
cp .env.example .env.local
```

Edit `packages/web/.env.local`:
```env
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1
```

#### Mobile App (.env)
```bash
cd packages/mobile
cp .env.example .env
```

Edit `packages/mobile/.env`:
```env
API_URL=http://localhost:3000/api/v1
# For iOS simulator, use http://localhost:3000
# For Android emulator, use http://10.0.2.2:3000
```

#### Rails API (.env)
```bash
cd server
cp .env.example .env
```

Edit `server/.env`:
```env
DATABASE_URL=postgresql://localhost/nutrition_tracker_development
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_here
JWT_SECRET=your_jwt_secret_here

# Optional: USDA API key for food data
USDA_API_KEY=your_usda_api_key

# Optional: AWS S3 for image uploads
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_BUCKET=nutrition-tracker-uploads
```

Generate secrets:
```bash
# Generate SECRET_KEY_BASE
rails secret

# Generate JWT_SECRET
rails secret
```

### 3. Setup Database

```bash
cd server

# Create databases
rails db:create

# Run migrations
rails db:migrate

# Seed with sample data (optional)
rails db:seed
```

This creates:
- A test user: `test@example.com` / `password123`
- Sample USDA foods in the database

### 4. Start Development Servers

You'll need 3 terminal windows:

#### Terminal 1: Rails API Server
```bash
cd server
rails server
# Runs on http://localhost:3000
```

#### Terminal 2: Next.js Web App
```bash
cd packages/web
pnpm dev
# Runs on http://localhost:3001
```

#### Terminal 3 (Optional): React Native Mobile App
```bash
cd packages/mobile

# For iOS (macOS only)
pnpm ios

# For Android
pnpm android
```

### 5. Verify Everything Works

1. **API Health Check**
   ```bash
   curl http://localhost:3000/health
   # Should return: {"status":"ok"}
   ```

2. **Web App**
   - Open http://localhost:3001
   - You should see the login page
   - Login with: `test@example.com` / `password123`

3. **Mobile App**
   - App should launch in simulator/emulator
   - Login with same test credentials

---

## Development Workflow

### Adding a New Feature

Example: Adding water intake tracking

1. **Add TypeScript types** (shared)
   ```bash
   # Edit: packages/shared/src/types/index.ts
   ```

2. **Create API client functions** (shared)
   ```bash
   # Edit: packages/shared/src/api/index.ts
   ```

3. **Create Zustand store** (shared)
   ```bash
   # Create: packages/shared/src/stores/waterStore.ts
   ```

4. **Add Rails migration**
   ```bash
   cd server
   rails g migration CreateWaterIntakes user:references date:date amount_ml:integer
   rails db:migrate
   ```

5. **Add Rails model and controller**
   ```bash
   # Create: server/app/models/water_intake.rb
   # Create: server/app/controllers/api/v1/water_intakes_controller.rb
   ```

6. **Build web UI**
   ```bash
   # Create: packages/web/app/water/page.tsx
   ```

7. **Build mobile UI**
   ```bash
   # Create: packages/mobile/src/screens/WaterScreen.tsx
   ```

### Testing Your Changes

```bash
# Test shared package
cd packages/shared
pnpm test

# Test web app
cd packages/web
pnpm test

# Test Rails API
cd server
rails test
```

---

## Common Issues and Solutions

### Issue: Port 3000 already in use
**Solution:** 
```bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9
```

### Issue: Database connection error
**Solution:**
```bash
# Check PostgreSQL is running
brew services list  # macOS
sudo service postgresql status  # Linux

# Restart if needed
brew services restart postgresql  # macOS
sudo service postgresql restart  # Linux
```

### Issue: pnpm install fails
**Solution:**
```bash
# Clear pnpm cache
pnpm store prune

# Delete node_modules and lockfile
rm -rf node_modules pnpm-lock.yaml

# Reinstall
pnpm install
```

### Issue: React Native build fails
**Solution:**
```bash
# iOS - clean build
cd packages/mobile/ios
pod deintegrate
pod install
cd ..
pnpm ios

# Android - clean build
cd packages/mobile/android
./gradlew clean
cd ..
pnpm android
```

### Issue: Shared package changes not reflected
**Solution:**
```bash
# From root directory
pnpm build --filter @nutrition/shared

# Or restart dev servers
```

---

## IDE Setup

### VS Code (Recommended)

Install extensions:
- ESLint
- Prettier
- TypeScript and JavaScript Language Features
- Ruby
- React Native Tools

Add to `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

### Debugging

#### Web App
- Use Chrome DevTools
- Or VS Code debugger with launch configuration

#### Mobile App
- Use React Native Debugger
- Or Flipper for advanced debugging

#### Rails API
- Use `binding.pry` for breakpoints
- Or VS Code Ruby debugger

---

## Next Steps

1. **Customize the app** for your needs
2. **Set up CI/CD** (see DEPLOYMENT.md)
3. **Add more features** (meal planning, recipes, etc.)
4. **Integrate external APIs** (barcode scanning, nutrition databases)
5. **Deploy to production** (see DEPLOYMENT.md)

---

## Getting Help

- Check the [API Documentation](./API.md)
- Review the [Database Schema](./DATABASE.md)
- See [Deployment Guide](./DEPLOYMENT.md)
- Open an issue on GitHub

---

## Useful Commands

```bash
# Root directory commands
pnpm dev           # Start all dev servers
pnpm build         # Build all packages
pnpm test          # Run all tests
pnpm lint          # Lint all packages
pnpm clean         # Clean all build artifacts

# Package-specific commands
pnpm --filter @nutrition/shared build
pnpm --filter @nutrition/web dev
pnpm --filter @nutrition/mobile start

# Rails commands
rails routes       # Show all API routes
rails console      # Open Rails console
rails db:reset     # Reset database (drop, create, migrate, seed)
```
