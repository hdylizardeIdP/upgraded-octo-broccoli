// API client that works on both web and mobile
import type {
  User,
  Meal,
  Food,
  DailyNutritionSummary,
  SearchFoodsRequest,
  SearchFoodsResponse,
  CreateMealRequest,
  UpdateMealRequest,
  LoginRequest,
  RegisterRequest,
  AuthResponse,
  ApiError,
} from '../types';

// Configuration
export const API_CONFIG = {
  baseUrl: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1',
  timeout: 30000,
};

// Storage interface (implemented differently on web vs mobile)
export interface StorageAdapter {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
  removeItem(key: string): Promise<void>;
}

let storageAdapter: StorageAdapter;
let authToken: string | null = null;

export function setStorageAdapter(adapter: StorageAdapter) {
  storageAdapter = adapter;
}

export async function setAuthToken(token: string | null) {
  authToken = token;
  if (token) {
    await storageAdapter?.setItem('auth_token', token);
  } else {
    await storageAdapter?.removeItem('auth_token');
  }
}

export async function getAuthToken(): Promise<string | null> {
  if (!authToken && storageAdapter) {
    authToken = await storageAdapter.getItem('auth_token');
  }
  return authToken;
}

// Base fetch wrapper
class ApiClient {
  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${API_CONFIG.baseUrl}${endpoint}`;
    const token = await getAuthToken();

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const config: RequestInit = {
      ...options,
      headers,
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        const error: ApiError = await response.json().catch(() => ({
          message: 'An error occurred',
        }));
        throw error;
      }

      return await response.json();
    } catch (error) {
      if (error instanceof Error) {
        throw {
          message: error.message,
        } as ApiError;
      }
      throw error;
    }
  }

  async get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async patch<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

export const apiClient = new ApiClient();

// Authentication API
export const authApi = {
  login: async (data: LoginRequest): Promise<AuthResponse> => {
    const response = await apiClient.post<AuthResponse>('/auth/login', data);
    await setAuthToken(response.tokens.accessToken);
    return response;
  },

  register: async (data: RegisterRequest): Promise<AuthResponse> => {
    const response = await apiClient.post<AuthResponse>('/auth/register', data);
    await setAuthToken(response.tokens.accessToken);
    return response;
  },

  logout: async (): Promise<void> => {
    await apiClient.post('/auth/logout');
    await setAuthToken(null);
  },

  refreshToken: async (): Promise<AuthResponse> => {
    return apiClient.post<AuthResponse>('/auth/refresh');
  },

  getCurrentUser: async (): Promise<User> => {
    return apiClient.get<User>('/auth/me');
  },
};

// Foods API
export const foodsApi = {
  search: async (params: SearchFoodsRequest): Promise<SearchFoodsResponse> => {
    const queryParams = new URLSearchParams({
      q: params.query,
      limit: String(params.limit || 20),
      offset: String(params.offset || 0),
      include_custom: String(params.includeCustom ?? true),
    });
    
    return apiClient.get<SearchFoodsResponse>(`/foods/search?${queryParams}`);
  },

  getById: async (id: string): Promise<Food> => {
    return apiClient.get<Food>(`/foods/${id}`);
  },

  createCustomFood: async (data: Partial<Food>): Promise<Food> => {
    return apiClient.post<Food>('/foods', data);
  },

  updateCustomFood: async (id: string, data: Partial<Food>): Promise<Food> => {
    return apiClient.put<Food>(`/foods/${id}`, data);
  },

  deleteCustomFood: async (id: string): Promise<void> => {
    return apiClient.delete(`/foods/${id}`);
  },

  scanBarcode: async (barcode: string): Promise<Food | null> => {
    return apiClient.get<Food | null>(`/foods/barcode/${barcode}`);
  },
};

// Meals API
export const mealsApi = {
  getMealsByDate: async (date: string): Promise<Meal[]> => {
    return apiClient.get<Meal[]>(`/meals?date=${date}`);
  },

  getMealById: async (id: string): Promise<Meal> => {
    return apiClient.get<Meal>(`/meals/${id}`);
  },

  createMeal: async (data: CreateMealRequest): Promise<Meal> => {
    return apiClient.post<Meal>('/meals', data);
  },

  updateMeal: async (id: string, data: UpdateMealRequest): Promise<Meal> => {
    return apiClient.put<Meal>(`/meals/${id}`, data);
  },

  deleteMeal: async (id: string): Promise<void> => {
    return apiClient.delete(`/meals/${id}`);
  },

  getDailySummary: async (date: string): Promise<DailyNutritionSummary> => {
    return apiClient.get<DailyNutritionSummary>(`/nutrition/daily?date=${date}`);
  },

  getWeeklySummary: async (startDate: string): Promise<DailyNutritionSummary[]> => {
    return apiClient.get<DailyNutritionSummary[]>(`/nutrition/weekly?start_date=${startDate}`);
  },
};

// User API
export const userApi = {
  getProfile: async (): Promise<User> => {
    return apiClient.get<User>('/users/profile');
  },

  updateProfile: async (data: Partial<User>): Promise<User> => {
    return apiClient.put<User>('/users/profile', data);
  },

  updateGoals: async (goals: Partial<User['goals']>): Promise<User> => {
    return apiClient.put<User>('/users/goals', { goals });
  },
};
