# Nutrition Tracker - Full Stack Monorepo

A mobile-first nutrition and calorie tracking application with web and native mobile support.

## Architecture Overview

```
nutrition-tracker/
├── packages/
│   ├── shared/          # Shared business logic, types, and utilities (30-40% code reuse)
│   ├── web/             # Next.js web application
│   └── mobile/          # React Native iOS/Android app
├── server/              # Rails API backend
└── docs/                # Documentation
```

## Tech Stack

- **Frontend (Web)**: Next.js 14, React 18, TypeScript, TailwindCSS
- **Frontend (Mobile)**: React Native, TypeScript, React Navigation
- **Backend**: Ruby on Rails 7.1+ (API-only mode)
- **Database**: PostgreSQL 14+
- **State Management**: Zustand (shared across web & mobile)
- **API Client**: TanStack Query (React Query)
- **Monorepo**: pnpm workspaces + Turboreporepo

## Features

### Phase 1 (Web MVP)
- [x] User authentication and profiles
- [x] Food database search (USDA integration)
- [x] Meal logging and tracking
- [x] Daily calorie and macro tracking
- [x] Nutrition goals and recommendations
- [x] Historical data and charts

### Phase 2 (Mobile Apps)
- [ ] iOS and Android native apps
- [ ] Offline meal logging
- [ ] Barcode scanning
- [ ] Photo meal logging
- [ ] Push notifications for reminders
- [ ] Biometric authentication

## Getting Started

### Prerequisites

- Node.js 20+ and pnpm 8+
- Ruby 3.2+ and Rails 7.1+
- PostgreSQL 14+
- (Mobile only) Xcode 15+ (iOS) or Android Studio (Android)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/nutrition-tracker.git
cd nutrition-tracker
```

2. **Install dependencies**
```bash
# Install Node dependencies for all packages
pnpm install

# Install Rails dependencies
cd server
bundle install
```

3. **Setup database**
```bash
cd server
rails db:create db:migrate db:seed
```

4. **Environment variables**
```bash
# Copy example env files
cp packages/web/.env.example packages/web/.env.local
cp server/.env.example server/.env

# Edit with your configurations
```

5. **Start development servers**
```bash
# Terminal 1: Rails API (port 3000)
cd server
rails s

# Terminal 2: Web app (port 3001)
cd packages/web
pnpm dev

# Terminal 3 (optional): Mobile app
cd packages/mobile
pnpm ios # or pnpm android
```

## Development

### Running Tests
```bash
# All packages
pnpm test

# Specific package
pnpm --filter @nutrition/shared test
pnpm --filter @nutrition/web test

# Rails tests
cd server
rails test
```

### Code Sharing Strategy

**What's Shared (packages/shared/):**
- TypeScript types and interfaces
- API client functions
- Business logic and calculations
- Validation rules
- Zustand stores
- Utility functions

**What's NOT Shared:**
- UI components (completely different for web/mobile)
- Styling approaches
- Navigation patterns
- Platform-specific features

### Adding a New Feature

Example: Adding "Water Intake Tracking"

1. **Define types** in `packages/shared/src/types/waterIntake.ts`
2. **Create API client** in `packages/shared/src/api/waterIntake.ts`
3. **Create store** in `packages/shared/src/stores/waterIntakeStore.ts`
4. **Add Rails endpoint** in `server/app/controllers/api/v1/water_intakes_controller.rb`
5. **Build web UI** in `packages/web/app/water-intake/`
6. **Build mobile UI** in `packages/mobile/src/screens/WaterIntakeScreen/`

## Project Structure

```
nutrition-tracker/
├── packages/
│   ├── shared/                    # Shared code (30-40% reuse)
│   │   ├── src/
│   │   │   ├── api/              # API client functions
│   │   │   ├── types/            # TypeScript definitions
│   │   │   ├── stores/           # Zustand state management
│   │   │   ├── utils/            # Helper functions
│   │   │   ├── hooks/            # Shared React hooks
│   │   │   └── constants/        # App constants
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── web/                       # Next.js web app
│   │   ├── app/                  # Next.js 14 app directory
│   │   ├── components/           # React components
│   │   ├── public/               # Static assets
│   │   ├── styles/               # Global styles
│   │   ├── package.json
│   │   └── next.config.js
│   │
│   └── mobile/                    # React Native app
│       ├── src/
│       │   ├── screens/          # Screen components
│       │   ├── components/       # Reusable components
│       │   ├── navigation/       # React Navigation setup
│       │   └── assets/           # Images, fonts
│       ├── ios/                  # iOS native code
│       ├── android/              # Android native code
│       └── package.json
│
├── server/                        # Rails API
│   ├── app/
│   │   ├── controllers/
│   │   │   └── api/v1/          # API v1 endpoints
│   │   ├── models/               # ActiveRecord models
│   │   ├── serializers/          # JSON serializers
│   │   └── services/             # Business logic
│   ├── config/
│   │   ├── routes.rb
│   │   └── database.yml
│   ├── db/
│   │   ├── migrate/
│   │   └── seeds.rb
│   └── Gemfile
│
├── docs/                          # Documentation
│   ├── API.md                    # API documentation
│   ├── DATABASE.md               # Database schema
│   └── DEPLOYMENT.md             # Deployment guide
│
├── pnpm-workspace.yaml           # pnpm workspace config
├── turbo.json                    # Turborepo config
└── package.json                  # Root package.json
```

## API Documentation

See [docs/API.md](./docs/API.md) for detailed API documentation.

### Base URL
- Development: `http://localhost:3000/api/v1`
- Production: `https://api.nutritiontracker.com/api/v1`

### Authentication
All requests require JWT token in Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Key Endpoints
- `POST /auth/login` - User authentication
- `GET /foods/search?q=apple` - Search food database
- `POST /meals` - Log a meal
- `GET /meals?date=2024-03-15` - Get meals for date
- `GET /nutrition/summary?date=2024-03-15` - Daily nutrition summary

## Deployment

### Web App (Vercel)
```bash
cd packages/web
vercel deploy --prod
```

### Mobile Apps
- iOS: Use Xcode or EAS Build
- Android: Use Android Studio or EAS Build

### Rails API (Heroku/Render)
```bash
cd server
git push heroku main
heroku run rails db:migrate
```

See [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) for detailed deployment instructions.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](./LICENSE) file for details

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [React Native Documentation](https://reactnative.dev/docs/getting-started)
- [Rails API Documentation](https://guides.rubyonrails.org/api_app.html)
- [USDA FoodData Central](https://fdc.nal.usda.gov/)
