# Code Sharing Example: Meals List

This example demonstrates how the **same business logic** (store) is used in **different UI implementations** for web and mobile.

## Shared Store (Used by Both)

```typescript
// packages/shared/src/stores/mealsStore.ts
// This code is used by BOTH web and mobile - no duplication!

import { create } from 'zustand';
import type { Meal } from '../types';
import { mealsApi } from '../api';

interface MealsState {
  meals: Meal[];
  selectedDate: string;
  isLoading: boolean;
  loadMeals: (date: string) => Promise<void>;
}

export const useMealsStore = create<MealsState>((set) => ({
  meals: [],
  selectedDate: new Date().toISOString().split('T')[0],
  isLoading: false,

  loadMeals: async (date: string) => {
    set({ isLoading: true });
    try {
      const meals = await mealsApi.getMealsByDate(date);
      set({ meals, isLoading: false, selectedDate: date });
    } catch (error) {
      set({ isLoading: false });
    }
  },
}));
```

**This store contains:**
- ✅ State management
- ✅ API calls
- ✅ Business logic
- ✅ Loading states
- ✅ Error handling

**What's shared: ~200 lines of complex logic**

---

## Web Implementation (Next.js/React)

```typescript
// packages/web/app/meals/page.tsx
// Web-specific UI using HTML/CSS

'use client';

import { useEffect } from 'react';
import { useMealsStore } from '@nutrition/shared';

export default function MealsPage() {
  // ✅ Same store as mobile!
  const { meals, selectedDate, isLoading, loadMeals } = useMealsStore();

  useEffect(() => {
    loadMeals(selectedDate);
  }, [selectedDate, loadMeals]);

  if (isLoading) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Today's Meals</h1>
      
      <div className="grid gap-4">
        {meals.map((meal) => (
          <div
            key={meal.id}
            className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow"
          >
            <div className="flex justify-between items-start mb-4">
              <div>
                <h2 className="text-xl font-semibold capitalize">
                  {meal.mealType}
                </h2>
                {meal.name && (
                  <p className="text-gray-600">{meal.name}</p>
                )}
              </div>
              <span className="text-2xl font-bold text-blue-600">
                {meal.totalNutrition.calories} cal
              </span>
            </div>

            <div className="space-y-2">
              {meal.entries.map((entry) => (
                <div
                  key={entry.id}
                  className="flex justify-between text-sm"
                >
                  <span className="text-gray-700">
                    {entry.food.name} ({entry.servings}x)
                  </span>
                  <span className="text-gray-500">
                    {entry.nutrition.calories} cal
                  </span>
                </div>
              ))}
            </div>

            <div className="mt-4 pt-4 border-t grid grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-gray-500">Protein</span>
                <p className="font-semibold">
                  {meal.totalNutrition.proteinG}g
                </p>
              </div>
              <div>
                <span className="text-gray-500">Carbs</span>
                <p className="font-semibold">
                  {meal.totalNutrition.carbsG}g
                </p>
              </div>
              <div>
                <span className="text-gray-500">Fat</span>
                <p className="font-semibold">
                  {meal.totalNutrition.fatG}g
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {meals.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 text-lg">
            No meals logged for today
          </p>
          <button className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Log Your First Meal
          </button>
        </div>
      )}
    </div>
  );
}
```

**Web-specific:**
- ❌ HTML div elements
- ❌ Tailwind CSS classes
- ❌ Next.js routing
- ❌ Browser-specific features

**What's NOT shared: ~100 lines of UI code**

---

## Mobile Implementation (React Native)

```typescript
// packages/mobile/src/screens/MealsScreen.tsx
// Mobile-specific UI using React Native components

import React, { useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  ActivityIndicator,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { useMealsStore } from '@nutrition/shared';

export function MealsScreen() {
  // ✅ Exact same store as web!
  const { meals, selectedDate, isLoading, loadMeals } = useMealsStore();

  useEffect(() => {
    loadMeals(selectedDate);
  }, [selectedDate, loadMeals]);

  if (isLoading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#2563eb" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Today's Meals</Text>

      {meals.map((meal) => (
        <View key={meal.id} style={styles.mealCard}>
          <View style={styles.mealHeader}>
            <View>
              <Text style={styles.mealType}>{meal.mealType}</Text>
              {meal.name && (
                <Text style={styles.mealName}>{meal.name}</Text>
              )}
            </View>
            <Text style={styles.calories}>
              {meal.totalNutrition.calories} cal
            </Text>
          </View>

          <View style={styles.entriesContainer}>
            {meal.entries.map((entry) => (
              <View key={entry.id} style={styles.entryRow}>
                <Text style={styles.entryFood}>
                  {entry.food.name} ({entry.servings}x)
                </Text>
                <Text style={styles.entryCalories}>
                  {entry.nutrition.calories} cal
                </Text>
              </View>
            ))}
          </View>

          <View style={styles.macrosContainer}>
            <View style={styles.macroItem}>
              <Text style={styles.macroLabel}>Protein</Text>
              <Text style={styles.macroValue}>
                {meal.totalNutrition.proteinG}g
              </Text>
            </View>
            <View style={styles.macroItem}>
              <Text style={styles.macroLabel}>Carbs</Text>
              <Text style={styles.macroValue}>
                {meal.totalNutrition.carbsG}g
              </Text>
            </View>
            <View style={styles.macroItem}>
              <Text style={styles.macroLabel}>Fat</Text>
              <Text style={styles.macroValue}>
                {meal.totalNutrition.fatG}g
              </Text>
            </View>
          </View>
        </View>
      ))}

      {meals.length === 0 && (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>
            No meals logged for today
          </Text>
          <TouchableOpacity style={styles.button}>
            <Text style={styles.buttonText}>
              Log Your First Meal
            </Text>
          </TouchableOpacity>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginHorizontal: 16,
    marginTop: 24,
    marginBottom: 16,
  },
  mealCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginHorizontal: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  mealHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  mealType: {
    fontSize: 20,
    fontWeight: '600',
    textTransform: 'capitalize',
  },
  mealName: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  calories: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2563eb',
  },
  entriesContainer: {
    marginBottom: 16,
  },
  entryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  entryFood: {
    fontSize: 14,
    color: '#333',
  },
  entryCalories: {
    fontSize: 14,
    color: '#666',
  },
  macrosContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    borderTopWidth: 1,
    borderTopColor: '#e5e5e5',
    paddingTop: 16,
  },
  macroItem: {
    alignItems: 'center',
  },
  macroLabel: {
    fontSize: 12,
    color: '#666',
  },
  macroValue: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 4,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 48,
  },
  emptyText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 16,
  },
  button: {
    backgroundColor: '#2563eb',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
});
```

**Mobile-specific:**
- ❌ React Native components (View, Text, ScrollView)
- ❌ StyleSheet API
- ❌ React Navigation
- ❌ Native gestures and animations

**What's NOT shared: ~150 lines of UI code**

---

## Summary

### What Gets Reused (30-40% of total codebase)

✅ **Shared Store** - 100% reused
- State management logic
- API calls
- Data transformations
- Loading/error states

✅ **Type Definitions** - 100% reused
- TypeScript interfaces
- Type safety across platforms

✅ **API Client** - 100% reused
- HTTP requests
- Authentication handling
- Response parsing

✅ **Business Logic** - 100% reused
- Nutrition calculations
- Date formatting
- Validation rules

### What Gets Rewritten (60-70% of total codebase)

❌ **UI Components** - Platform-specific
- Web: HTML + CSS
- Mobile: React Native components

❌ **Styling** - Completely different
- Web: Tailwind CSS
- Mobile: StyleSheet API

❌ **Navigation** - Different libraries
- Web: Next.js routing
- Mobile: React Navigation

❌ **Platform Features** - Native APIs
- Camera, push notifications, biometrics

---

## The Value Proposition

**Without code sharing:**
- Write meals logic once for web: 200 lines
- Write meals logic again for mobile: 200 lines
- **Total: 400 lines** + maintenance nightmare

**With monorepo + shared package:**
- Write meals logic once (shared): 200 lines
- Write web UI: 100 lines
- Write mobile UI: 150 lines
- **Total: 450 lines** but shared logic is battle-tested

**Savings:**
- 30-40% less code
- Single source of truth for business logic
- Changes propagate to both platforms
- Consistent behavior across web and mobile
- Easier testing and maintenance

---

## Key Takeaway

You're **NOT** writing the app once and running it everywhere. You're **extracting the brains** (stores, API, utils, types) and **rewriting the face** (UI) for each platform.

This is the sweet spot for React + TypeScript + React Native:
- Shared language and patterns
- Meaningful code reuse where it matters
- Platform-optimized UIs
- Leverage of your existing React skills
