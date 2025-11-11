// Meals store - shared across web and mobile
import { create } from 'zustand';
import type { Meal, DailyNutritionSummary, CreateMealRequest, UpdateMealRequest } from '../types';
import { mealsApi } from '../api';

interface MealsState {
  meals: Meal[];
  dailySummary: DailyNutritionSummary | null;
  selectedDate: string; // ISO date string
  isLoading: boolean;
  error: string | null;
  
  // Actions
  setSelectedDate: (date: string) => void;
  loadMeals: (date: string) => Promise<void>;
  loadDailySummary: (date: string) => Promise<void>;
  createMeal: (data: CreateMealRequest) => Promise<Meal>;
  updateMeal: (id: string, data: UpdateMealRequest) => Promise<Meal>;
  deleteMeal: (id: string) => Promise<void>;
  clearError: () => void;
}

// Helper to get today's date in ISO format
const getTodayISO = () => new Date().toISOString().split('T')[0];

export const useMealsStore = create<MealsState>((set, get) => ({
  meals: [],
  dailySummary: null,
  selectedDate: getTodayISO(),
  isLoading: false,
  error: null,

  setSelectedDate: (date: string) => {
    set({ selectedDate: date });
    // Auto-load data for new date
    get().loadMeals(date);
    get().loadDailySummary(date);
  },

  loadMeals: async (date: string) => {
    set({ isLoading: true, error: null });
    try {
      const meals = await mealsApi.getMealsByDate(date);
      set({ meals, isLoading: false });
    } catch (error: any) {
      set({
        error: error.message || 'Failed to load meals',
        isLoading: false,
      });
    }
  },

  loadDailySummary: async (date: string) => {
    set({ isLoading: true, error: null });
    try {
      const summary = await mealsApi.getDailySummary(date);
      set({ dailySummary: summary, isLoading: false });
    } catch (error: any) {
      set({
        error: error.message || 'Failed to load daily summary',
        isLoading: false,
      });
    }
  },

  createMeal: async (data: CreateMealRequest) => {
    set({ isLoading: true, error: null });
    try {
      const newMeal = await mealsApi.createMeal(data);
      
      // Add to local state
      set(state => ({
        meals: [...state.meals, newMeal],
        isLoading: false,
      }));
      
      // Refresh summary
      await get().loadDailySummary(data.date);
      
      return newMeal;
    } catch (error: any) {
      set({
        error: error.message || 'Failed to create meal',
        isLoading: false,
      });
      throw error;
    }
  },

  updateMeal: async (id: string, data: UpdateMealRequest) => {
    set({ isLoading: true, error: null });
    try {
      const updatedMeal = await mealsApi.updateMeal(id, data);
      
      // Update local state
      set(state => ({
        meals: state.meals.map(meal => 
          meal.id === id ? updatedMeal : meal
        ),
        isLoading: false,
      }));
      
      // Refresh summary
      await get().loadDailySummary(get().selectedDate);
      
      return updatedMeal;
    } catch (error: any) {
      set({
        error: error.message || 'Failed to update meal',
        isLoading: false,
      });
      throw error;
    }
  },

  deleteMeal: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      await mealsApi.deleteMeal(id);
      
      // Remove from local state
      set(state => ({
        meals: state.meals.filter(meal => meal.id !== id),
        isLoading: false,
      }));
      
      // Refresh summary
      await get().loadDailySummary(get().selectedDate);
    } catch (error: any) {
      set({
        error: error.message || 'Failed to delete meal',
        isLoading: false,
      });
      throw error;
    }
  },

  clearError: () => set({ error: null }),
}));
