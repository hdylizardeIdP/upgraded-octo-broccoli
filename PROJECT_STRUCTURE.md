# Project Structure Overview

This document provides a complete overview of the nutrition tracker monorepo structure.

## Repository Structure

```
nutrition-tracker/
├── README.md                          # Main project documentation
├── package.json                       # Root package.json (workspace root)
├── pnpm-workspace.yaml               # pnpm workspace configuration
├── turbo.json                        # Turborepo build configuration
├── .gitignore                        # Git ignore rules
│
├── packages/                         # Frontend packages
│   ├── shared/                       # 🔵 Shared code (30-40% reuse)
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── src/
│   │       ├── index.ts             # Main export file
│   │       ├── types/
│   │       │   └── index.ts         # TypeScript type definitions
│   │       ├── api/
│   │       │   └── index.ts         # API client functions
│   │       ├── stores/
│   │       │   ├── authStore.ts     # Authentication state
│   │       │   └── mealsStore.ts    # Meals state management
│   │       └── utils/
│   │           └── nutrition.ts     # Nutrition calculations
│   │
│   ├── web/                          # Next.js web application
│   │   ├── package.json
│   │   ├── next.config.js
│   │   ├── tsconfig.json
│   │   ├── .env.example
│   │   ├── app/
│   │   │   ├── layout.tsx           # Root layout
│   │   │   └── providers.tsx        # React Query + storage setup
│   │   └── lib/
│   │       └── storage.ts           # localStorage adapter
│   │
│   └── mobile/                       # React Native mobile app
│       ├── package.json
│       ├── App.tsx                  # Main app component
│       ├── tsconfig.json
│       ├── .env.example
│       ├── ios/                     # iOS native code
│       ├── android/                 # Android native code
│       └── src/
│           └── lib/
│               └── storage.ts       # AsyncStorage adapter
│
├── server/                           # Rails API backend
│   ├── Gemfile                      # Ruby dependencies
│   ├── config/
│   │   └── routes.rb                # API routes
│   └── app/
│       ├── controllers/
│       │   └── api/v1/
│       │       └── meals_controller.rb  # Example controller
│       └── serializers/
│           └── meal_serializer.rb   # JSON serializers
│
└── docs/                            # Documentation
    ├── API.md                       # API endpoint documentation
    ├── DATABASE.md                  # Database schema
    ├── QUICKSTART.md                # Setup guide
    └── CODE_SHARING_EXAMPLE.md      # Code reuse examples
```

---

## Package Descriptions

### 📦 Root Package (`/`)
- **Purpose**: Monorepo management and orchestration
- **Key Files**:
  - `package.json` - Defines workspace scripts and devDependencies
  - `pnpm-workspace.yaml` - Configures pnpm workspaces
  - `turbo.json` - Optimizes builds with Turborepo
  - `.gitignore` - Git ignore rules for entire project

### 📦 Shared Package (`/packages/shared`)
**The heart of code reuse - 30-40% of frontend logic**

Contains everything that works identically on web and mobile:

#### Types (`/src/types/`)
- All TypeScript interfaces and types
- User, Food, Meal, NutritionInfo, etc.
- Request/Response types
- 100% shared across platforms

#### API Client (`/src/api/`)
- HTTP request functions
- Authentication handling
- Error handling
- Works with both localStorage (web) and AsyncStorage (mobile)

#### Stores (`/src/stores/`)
- Zustand state management
- Business logic and data transformations
- Works identically on web and mobile
- Examples: authStore, mealsStore

#### Utils (`/src/utils/`)
- Pure functions
- Nutrition calculations (BMR, TDEE, macros)
- Date formatting
- Validation helpers

### 📦 Web Package (`/packages/web`)
**Next.js 14 web application**

- React components using HTML/CSS
- Tailwind for styling
- Next.js routing
- Browser-specific features
- Uses `@nutrition/shared` for logic

**Key Integration Point**: `app/providers.tsx`
- Initializes storage adapter
- Sets up React Query
- Loads user session

### 📦 Mobile Package (`/packages/mobile`)
**React Native iOS/Android app**

- React Native components
- StyleSheet API for styling
- React Navigation
- Native features (camera, push notifications)
- Uses `@nutrition/shared` for logic

**Key Integration Point**: `App.tsx`
- Initializes AsyncStorage adapter
- Sets up React Query
- Loads user session

### 🗄️ Server Package (`/server`)
**Rails 7.1 API backend**

- API-only mode
- PostgreSQL database
- JWT authentication
- JSON serializers
- Background jobs with Sidekiq

**Key Files**:
- `config/routes.rb` - API endpoint definitions
- `app/controllers/api/v1/` - Controller implementations
- `app/models/` - ActiveRecord models
- `app/serializers/` - JSON response formatting

---

## Data Flow

### Request Flow (Both Web and Mobile)
```
UI Component
    ↓ (calls)
Zustand Store (@nutrition/shared)
    ↓ (calls)
API Client (@nutrition/shared)
    ↓ (HTTP request)
Rails API (server/)
    ↓ (queries)
PostgreSQL Database
```

### Example: Logging a Meal
```typescript
// 1. User clicks "Log Meal" button (web or mobile UI)
// 2. Component calls shared store
useMealsStore.getState().createMeal(mealData)

// 3. Store calls shared API client
mealsApi.createMeal(mealData)

// 4. API client makes HTTP request
POST /api/v1/meals

// 5. Rails controller processes
MealsController#create

// 6. Database stores meal
INSERT INTO meals...

// 7. Response flows back up
// Store updates → UI re-renders
```

---

## Development Commands

### From Root Directory
```bash
# Install all dependencies
pnpm install

# Run all dev servers (web + mobile)
pnpm dev

# Build all packages
pnpm build

# Run all tests
pnpm test

# Lint all packages
pnpm lint

# Clean all build artifacts
pnpm clean
```

### Package-Specific Commands
```bash
# Build shared package
pnpm --filter @nutrition/shared build

# Start web dev server
pnpm --filter @nutrition/web dev

# Start mobile dev server
pnpm --filter @nutrition/mobile start

# Run shared tests
pnpm --filter @nutrition/shared test
```

### Rails Commands
```bash
cd server

# Start Rails server
rails server

# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed database
rails db:seed

# Open Rails console
rails console

# Run tests
rails test
```

---

## Adding New Files

### When to add to `/packages/shared/`
✅ Add if the code:
- Works identically on web and mobile
- Contains business logic
- Is a pure function or utility
- Defines TypeScript types
- Makes API calls
- Manages state with Zustand

❌ Don't add if the code:
- Renders UI components
- Uses platform-specific APIs
- Contains styling
- Uses navigation

### When to add to `/packages/web/`
✅ Add if the code:
- Renders HTML/React components
- Uses browser-specific features
- Implements Next.js pages/layouts
- Contains CSS/Tailwind styling

### When to add to `/packages/mobile/`
✅ Add if the code:
- Renders React Native components
- Uses native mobile features
- Implements React Navigation screens
- Contains mobile-specific styling

### When to add to `/server/`
✅ Add if the code:
- Implements API endpoints
- Defines database models
- Contains background jobs
- Manages authentication

---

## Key Integration Points

### Storage Adapters
**Purpose**: Allow API client to work on both platforms

**Web** (`packages/web/lib/storage.ts`):
```typescript
localStorage.getItem()
localStorage.setItem()
```

**Mobile** (`packages/mobile/src/lib/storage.ts`):
```typescript
AsyncStorage.getItem()
AsyncStorage.setItem()
```

### Providers Setup
**Purpose**: Initialize shared code with platform-specific dependencies

**Web** (`packages/web/app/providers.tsx`):
- Sets web storage adapter
- Initializes React Query
- Loads user session

**Mobile** (`packages/mobile/App.tsx`):
- Sets mobile storage adapter
- Initializes React Query
- Loads user session

---

## Documentation Files

### `/README.md`
Main project documentation with:
- Architecture overview
- Tech stack
- Getting started guide
- Project structure

### `/docs/API.md`
Complete API documentation:
- All endpoints
- Request/response formats
- Authentication
- Error handling

### `/docs/DATABASE.md`
Database documentation:
- Schema definitions
- Migrations guide
- Model relationships
- Query patterns

### `/docs/QUICKSTART.md`
Step-by-step setup guide:
- Prerequisites
- Installation
- Configuration
- Running servers
- Common issues

### `/docs/CODE_SHARING_EXAMPLE.md`
Demonstrates code reuse:
- Same store, different UI
- Web vs Mobile comparison
- What's shared vs what's not

---

## Next Steps

1. **Clone this structure** to your local machine
2. **Follow QUICKSTART.md** to set up development environment
3. **Read API.md** to understand backend endpoints
4. **Study CODE_SHARING_EXAMPLE.md** to see how sharing works
5. **Start building features!**

---

## File Count Summary

- **Total Files Created**: 28
- **Shared Package**: 6 files (types, API, stores, utils)
- **Web Package**: 4 files (setup and config)
- **Mobile Package**: 3 files (setup and config)
- **Server Package**: 4 files (API implementation)
- **Documentation**: 5 files (guides and examples)
- **Root Config**: 6 files (monorepo setup)

---

## Technology Decisions Summary

| Aspect | Choice | Reason |
|--------|--------|--------|
| **Monorepo** | pnpm + Turborepo | Fast installs, optimized builds |
| **Frontend Language** | TypeScript | Type safety across platforms |
| **Web Framework** | Next.js 14 | Modern React, SSR, API routes |
| **Mobile Framework** | React Native | Share logic with web, native performance |
| **State Management** | Zustand | Simple, works everywhere, no boilerplate |
| **API Layer** | Shared fetch client | One implementation for both platforms |
| **Backend** | Rails 7.1 API | Rapid development, conventions, mature |
| **Database** | PostgreSQL | JSON support, full-text search, reliable |
| **Authentication** | JWT | Stateless, works with mobile and web |

---

## Questions?

This structure is ready to:
1. Clone and start developing immediately
2. Scale to production with CI/CD
3. Add more features incrementally
4. Deploy web and mobile independently

All files are production-ready starting points that Claude or any developer can extend!
