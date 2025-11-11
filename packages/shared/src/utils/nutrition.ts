// Nutrition calculation utilities - shared across web and mobile
import type { NutritionInfo, User, ActivityLevel, NutritionGoals } from '../types';

/**
 * Calculate total nutrition from multiple nutrition info objects
 */
export function sumNutrition(...nutritionInfos: NutritionInfo[]): NutritionInfo {
  return nutritionInfos.reduce(
    (total, info) => ({
      calories: total.calories + info.calories,
      proteinG: total.proteinG + info.proteinG,
      carbsG: total.carbsG + info.carbsG,
      fatG: total.fatG + info.fatG,
      fiberG: (total.fiberG || 0) + (info.fiberG || 0),
      sugarG: (total.sugarG || 0) + (info.sugarG || 0),
      saturatedFatG: (total.saturatedFatG || 0) + (info.saturatedFatG || 0),
      transFatG: (total.transFatG || 0) + (info.transFatG || 0),
      cholesterolMg: (total.cholesterolMg || 0) + (info.cholesterolMg || 0),
      sodiumMg: (total.sodiumMg || 0) + (info.sodiumMg || 0),
      potassiumMg: (total.potassiumMg || 0) + (info.potassiumMg || 0),
      vitaminAMcg: (total.vitaminAMcg || 0) + (info.vitaminAMcg || 0),
      vitaminCMg: (total.vitaminCMg || 0) + (info.vitaminCMg || 0),
      calciumMg: (total.calciumMg || 0) + (info.calciumMg || 0),
      ironMg: (total.ironMg || 0) + (info.ironMg || 0),
    }),
    {
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      fiberG: 0,
      sugarG: 0,
      saturatedFatG: 0,
      transFatG: 0,
      cholesterolMg: 0,
      sodiumMg: 0,
      potassiumMg: 0,
      vitaminAMcg: 0,
      vitaminCMg: 0,
      calciumMg: 0,
      ironMg: 0,
    }
  );
}

/**
 * Scale nutrition info by servings
 */
export function scaleNutrition(nutrition: NutritionInfo, servings: number): NutritionInfo {
  return {
    calories: Math.round(nutrition.calories * servings),
    proteinG: roundTo(nutrition.proteinG * servings, 1),
    carbsG: roundTo(nutrition.carbsG * servings, 1),
    fatG: roundTo(nutrition.fatG * servings, 1),
    fiberG: nutrition.fiberG ? roundTo(nutrition.fiberG * servings, 1) : undefined,
    sugarG: nutrition.sugarG ? roundTo(nutrition.sugarG * servings, 1) : undefined,
    saturatedFatG: nutrition.saturatedFatG ? roundTo(nutrition.saturatedFatG * servings, 1) : undefined,
    transFatG: nutrition.transFatG ? roundTo(nutrition.transFatG * servings, 1) : undefined,
    cholesterolMg: nutrition.cholesterolMg ? Math.round(nutrition.cholesterolMg * servings) : undefined,
    sodiumMg: nutrition.sodiumMg ? Math.round(nutrition.sodiumMg * servings) : undefined,
    potassiumMg: nutrition.potassiumMg ? Math.round(nutrition.potassiumMg * servings) : undefined,
    vitaminAMcg: nutrition.vitaminAMcg ? roundTo(nutrition.vitaminAMcg * servings, 1) : undefined,
    vitaminCMg: nutrition.vitaminCMg ? roundTo(nutrition.vitaminCMg * servings, 1) : undefined,
    calciumMg: nutrition.calciumMg ? Math.round(nutrition.calciumMg * servings) : undefined,
    ironMg: nutrition.ironMg ? roundTo(nutrition.ironMg * servings, 1) : undefined,
  };
}

/**
 * Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
 */
export function calculateBMR(
  weightKg: number,
  heightCm: number,
  age: number,
  gender: 'male' | 'female' | 'other'
): number {
  // For 'other', use average of male and female
  if (gender === 'male') {
    return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
  } else if (gender === 'female') {
    return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  } else {
    // Average of male and female formulas
    const male = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    const female = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    return (male + female) / 2;
  }
}

/**
 * Get activity multiplier for TDEE calculation
 */
export function getActivityMultiplier(activityLevel: ActivityLevel): number {
  const multipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9,
  };
  return multipliers[activityLevel];
}

/**
 * Calculate Total Daily Energy Expenditure (TDEE)
 */
export function calculateTDEE(
  weightKg: number,
  heightCm: number,
  age: number,
  gender: 'male' | 'female' | 'other',
  activityLevel: ActivityLevel
): number {
  const bmr = calculateBMR(weightKg, heightCm, age, gender);
  const multiplier = getActivityMultiplier(activityLevel);
  return Math.round(bmr * multiplier);
}

/**
 * Calculate recommended macros based on goals
 * Returns grams of protein, carbs, and fat
 */
export function calculateMacros(
  dailyCalories: number,
  proteinPercentage: number = 30,
  carbsPercentage: number = 40,
  fatPercentage: number = 30
): { protein: number; carbs: number; fat: number } {
  // 1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal
  return {
    protein: Math.round((dailyCalories * (proteinPercentage / 100)) / 4),
    carbs: Math.round((dailyCalories * (carbsPercentage / 100)) / 4),
    fat: Math.round((dailyCalories * (fatPercentage / 100)) / 9),
  };
}

/**
 * Calculate suggested nutrition goals for a user
 */
export function calculateRecommendedGoals(user: Partial<User>): NutritionGoals | null {
  if (!user.weightKg || !user.heightCm || !user.dateOfBirth || !user.gender || !user.activityLevel) {
    return null;
  }

  const age = calculateAge(user.dateOfBirth);
  const tdee = calculateTDEE(
    user.weightKg,
    user.heightCm,
    age,
    user.gender,
    user.activityLevel
  );

  const macros = calculateMacros(tdee);

  return {
    dailyCalories: tdee,
    proteinGrams: macros.protein,
    carbsGrams: macros.carbs,
    fatGrams: macros.fat,
    fiberGrams: 25, // General recommendation
    sodiumMg: 2300, // FDA recommendation
  };
}

/**
 * Calculate age from date of birth
 */
export function calculateAge(dateOfBirth: string): number {
  const today = new Date();
  const birthDate = new Date(dateOfBirth);
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  
  return age;
}

/**
 * Calculate percentage of goal achieved
 */
export function calculateGoalProgress(consumed: number, goal: number): number {
  if (goal === 0) return 0;
  return Math.round((consumed / goal) * 100);
}

/**
 * Round number to specified decimal places
 */
export function roundTo(num: number, decimals: number): number {
  const factor = Math.pow(10, decimals);
  return Math.round(num * factor) / factor;
}

/**
 * Format nutrition value for display
 */
export function formatNutritionValue(value: number | undefined, unit: string): string {
  if (value === undefined) return '-';
  return `${roundTo(value, 1)}${unit}`;
}

/**
 * Format date to ISO string (YYYY-MM-DD)
 */
export function formatDateISO(date: Date): string {
  return date.toISOString().split('T')[0];
}

/**
 * Parse ISO date string to Date object
 */
export function parseISODate(dateString: string): Date {
  return new Date(dateString + 'T00:00:00');
}

/**
 * Get date N days from now
 */
export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

/**
 * Check if two dates are the same day
 */
export function isSameDay(date1: Date, date2: Date): boolean {
  return formatDateISO(date1) === formatDateISO(date2);
}
