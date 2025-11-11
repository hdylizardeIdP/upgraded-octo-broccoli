# Rails API Documentation

## Overview

The Rails API serves as the backend for both web and mobile nutrition tracking clients. It's built in API-only mode with JSON responses.

## Base URL

- Development: `http://localhost:3000/api/v1`
- Production: `https://api.nutritiontracker.com/api/v1`

## Authentication

All endpoints (except `/auth/login` and `/auth/register`) require JWT authentication.

### Headers
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Token Refresh
Tokens expire after 24 hours. Use the refresh endpoint before expiry.

## API Endpoints

### Authentication

#### POST /auth/register
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "name": "John Doe"
}
```

**Response:** `201 Created`
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2024-03-15T10:00:00Z"
  },
  "tokens": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 86400
  }
}
```

#### POST /auth/login
Authenticate existing user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** `200 OK` (same format as register)

#### POST /auth/logout
Invalidate current session.

**Response:** `200 OK`
```json
{
  "message": "Logged out successfully"
}
```

#### POST /auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK` (returns new tokens)

#### GET /auth/me
Get current authenticated user.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "heightCm": 175,
  "weightKg": 75,
  "activityLevel": "moderate",
  "goals": {
    "dailyCalories": 2200,
    "proteinGrams": 165,
    "carbsGrams": 220,
    "fatGrams": 73
  }
}
```

---

### Foods

#### GET /foods/search
Search food database (USDA + custom foods).

**Query Parameters:**
- `q` (required): Search query
- `limit` (optional): Results per page (default: 20, max: 100)
- `offset` (optional): Pagination offset (default: 0)
- `include_custom` (optional): Include user's custom foods (default: true)

**Example:** `GET /foods/search?q=apple&limit=10`

**Response:** `200 OK`
```json
{
  "foods": [
    {
      "id": "uuid",
      "fdcId": 171688,
      "name": "Apple, raw",
      "brand": null,
      "servingSize": 182,
      "servingUnit": "g",
      "nutrition": {
        "calories": 95,
        "proteinG": 0.5,
        "carbsG": 25,
        "fatG": 0.3,
        "fiberG": 4.4,
        "sugarG": 19
      },
      "isCustom": false
    }
  ],
  "total": 156,
  "limit": 10,
  "offset": 0
}
```

#### GET /foods/:id
Get specific food by ID.

**Response:** `200 OK` (single food object)

#### POST /foods
Create custom food.

**Request:**
```json
{
  "name": "My Custom Protein Shake",
  "brand": "Homemade",
  "servingSize": 350,
  "servingUnit": "ml",
  "nutrition": {
    "calories": 250,
    "proteinG": 30,
    "carbsG": 20,
    "fatG": 5
  }
}
```

**Response:** `201 Created` (returns created food)

#### PUT /foods/:id
Update custom food (user can only update their own).

#### DELETE /foods/:id
Delete custom food.

**Response:** `204 No Content`

#### GET /foods/barcode/:barcode
Look up food by barcode.

**Example:** `GET /foods/barcode/012000161155`

**Response:** `200 OK` (food object) or `404 Not Found`

---

### Meals

#### GET /meals
Get meals for a specific date.

**Query Parameters:**
- `date` (required): ISO date string (YYYY-MM-DD)

**Example:** `GET /meals?date=2024-03-15`

**Response:** `200 OK`
```json
[
  {
    "id": "uuid",
    "userId": "uuid",
    "date": "2024-03-15",
    "mealType": "breakfast",
    "name": "Morning Breakfast",
    "entries": [
      {
        "id": "uuid",
        "foodId": "uuid",
        "food": {
          "id": "uuid",
          "name": "Oatmeal",
          "servingSize": 40,
          "servingUnit": "g",
          "nutrition": { /* ... */ }
        },
        "servings": 1.5,
        "nutrition": {
          "calories": 225,
          "proteinG": 7.5,
          "carbsG": 40.5,
          "fatG": 4.5
        }
      }
    ],
    "totalNutrition": {
      "calories": 450,
      "proteinG": 20,
      "carbsG": 60,
      "fatG": 10
    },
    "notes": "Added honey",
    "createdAt": "2024-03-15T08:30:00Z"
  }
]
```

#### GET /meals/:id
Get specific meal by ID.

**Response:** `200 OK` (single meal object)

#### POST /meals
Create a new meal.

**Request:**
```json
{
  "date": "2024-03-15",
  "mealType": "lunch",
  "name": "Office Lunch",
  "entries": [
    {
      "foodId": "uuid",
      "servings": 1
    },
    {
      "foodId": "uuid",
      "servings": 2
    }
  ],
  "notes": "Ate at desk"
}
```

**Response:** `201 Created` (returns created meal with calculated nutrition)

#### PUT /meals/:id
Update existing meal.

**Request:** Same as POST (all fields optional)

**Response:** `200 OK` (returns updated meal)

#### DELETE /meals/:id
Delete a meal.

**Response:** `204 No Content`

---

### Nutrition Summaries

#### GET /nutrition/daily
Get daily nutrition summary.

**Query Parameters:**
- `date` (required): ISO date string

**Example:** `GET /nutrition/daily?date=2024-03-15`

**Response:** `200 OK`
```json
{
  "date": "2024-03-15",
  "userId": "uuid",
  "meals": [ /* array of meals */ ],
  "totalNutrition": {
    "calories": 2150,
    "proteinG": 160,
    "carbsG": 220,
    "fatG": 70
  },
  "goals": {
    "dailyCalories": 2200,
    "proteinGrams": 165,
    "carbsGrams": 220,
    "fatGrams": 73
  },
  "goalProgress": {
    "calories": { "consumed": 2150, "goal": 2200, "percentage": 98 },
    "protein": { "consumed": 160, "goal": 165, "percentage": 97 },
    "carbs": { "consumed": 220, "goal": 220, "percentage": 100 },
    "fat": { "consumed": 70, "goal": 73, "percentage": 96 }
  }
}
```

#### GET /nutrition/weekly
Get weekly nutrition summaries.

**Query Parameters:**
- `start_date` (required): Start of week (ISO date)

**Example:** `GET /nutrition/weekly?start_date=2024-03-11`

**Response:** `200 OK` (array of 7 daily summaries)

---

### User Profile

#### GET /users/profile
Get user profile.

**Response:** `200 OK` (user object)

#### PUT /users/profile
Update user profile.

**Request:**
```json
{
  "name": "John Smith",
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "heightCm": 180,
  "weightKg": 78,
  "activityLevel": "active"
}
```

**Response:** `200 OK` (updated user object)

#### PUT /users/goals
Update nutrition goals.

**Request:**
```json
{
  "goals": {
    "dailyCalories": 2400,
    "proteinGrams": 180,
    "carbsGrams": 240,
    "fatGrams": 80
  }
}
```

**Response:** `200 OK` (updated user object)

---

## Error Responses

All errors follow this format:

```json
{
  "message": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": {
    "field": ["validation error messages"]
  }
}
```

### Common Status Codes

- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

### Example Error Response

```json
{
  "message": "Validation failed",
  "code": "VALIDATION_ERROR",
  "details": {
    "email": ["is invalid"],
    "password": ["is too short (minimum is 8 characters)"]
  }
}
```

---

## Rate Limiting

- Authenticated requests: 1000 requests per hour
- Unauthenticated requests: 100 requests per hour

Rate limit headers:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1678896000
```

---

## Pagination

List endpoints support pagination with:
- `limit`: Results per page (default varies by endpoint)
- `offset`: Number of results to skip

Paginated responses include:
```json
{
  "data": [ /* results */ ],
  "total": 156,
  "limit": 20,
  "offset": 0,
  "hasMore": true
}
```

---

## CORS

CORS is enabled for configured domains in production.

Development: All origins allowed (`*`)

---

## Webhooks (Future)

Webhook support planned for:
- Meal logged
- Goal achieved
- Weight updated

---

## Data Integration

### USDA FoodData Central

Foods are synced from USDA database nightly.

Custom foods are user-specific and not shared.

### Future Integrations

- Nutritionix API for barcode lookup
- MyFitnessPal import
- Apple Health / Google Fit sync
