// Core nutrition types shared across web and mobile

export interface User {
  id: string;
  email: string;
  name: string;
  dateOfBirth?: string;
  gender?: 'male' | 'female' | 'other';
  heightCm?: number;
  weightKg?: number;
  activityLevel?: ActivityLevel;
  goals?: NutritionGoals;
  createdAt: string;
  updatedAt: string;
}

export type ActivityLevel = 
  | 'sedentary'       // Little or no exercise
  | 'light'           // Exercise 1-3 days/week
  | 'moderate'        // Exercise 3-5 days/week
  | 'active'          // Exercise 6-7 days/week
  | 'very_active';    // Hard exercise 6-7 days/week

export interface NutritionGoals {
  dailyCalories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  fiberGrams?: number;
  sodiumMg?: number;
}

export interface Food {
  id: string;
  fdcId?: number;        // USDA FoodData Central ID
  name: string;
  brand?: string;
  servingSize: number;
  servingUnit: ServingUnit;
  nutrition: NutritionInfo;
  barcode?: string;
  imageUrl?: string;
  isCustom: boolean;     // User-created food
  createdAt: string;
  updatedAt: string;
}

export type ServingUnit = 
  | 'g' 
  | 'ml' 
  | 'oz' 
  | 'cup' 
  | 'tbsp' 
  | 'tsp' 
  | 'piece' 
  | 'slice'
  | 'serving';

export interface NutritionInfo {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG?: number;
  sugarG?: number;
  saturatedFatG?: number;
  transFatG?: number;
  cholesterolMg?: number;
  sodiumMg?: number;
  potassiumMg?: number;
  vitaminAMcg?: number;
  vitaminCMg?: number;
  calciumMg?: number;
  ironMg?: number;
}

export interface Meal {
  id: string;
  userId: string;
  date: string;           // ISO date string (YYYY-MM-DD)
  mealType: MealType;
  name?: string;          // Optional meal name
  entries: MealEntry[];
  totalNutrition: NutritionInfo;
  notes?: string;
  imageUrl?: string;
  createdAt: string;
  updatedAt: string;
}

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

export interface MealEntry {
  id: string;
  foodId: string;
  food: Food;
  servings: number;       // Number of servings (can be decimal)
  nutrition: NutritionInfo; // Calculated based on servings
}

export interface DailyNutritionSummary {
  date: string;
  userId: string;
  meals: Meal[];
  totalNutrition: NutritionInfo;
  goals?: NutritionGoals;
  goalProgress: {
    calories: { consumed: number; goal: number; percentage: number };
    protein: { consumed: number; goal: number; percentage: number };
    carbs: { consumed: number; goal: number; percentage: number };
    fat: { consumed: number; goal: number; percentage: number };
  };
}

export interface WaterIntake {
  id: string;
  userId: string;
  date: string;
  amountMl: number;
  time: string;           // ISO timestamp
  createdAt: string;
}

export interface Weight {
  id: string;
  userId: string;
  date: string;
  weightKg: number;
  notes?: string;
  createdAt: string;
}

// API Request/Response types
export interface CreateMealRequest {
  date: string;
  mealType: MealType;
  name?: string;
  entries: CreateMealEntryRequest[];
  notes?: string;
}

export interface CreateMealEntryRequest {
  foodId: string;
  servings: number;
}

export interface UpdateMealRequest {
  name?: string;
  mealType?: MealType;
  entries?: CreateMealEntryRequest[];
  notes?: string;
}

export interface SearchFoodsRequest {
  query: string;
  limit?: number;
  offset?: number;
  includeCustom?: boolean; // Include user's custom foods
}

export interface SearchFoodsResponse {
  foods: Food[];
  total: number;
  limit: number;
  offset: number;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}

export interface AuthResponse {
  user: User;
  tokens: AuthTokens;
}

// Utility types
export interface ApiError {
  message: string;
  code?: string;
  details?: Record<string, any>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
