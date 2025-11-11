// packages/mobile/App.tsx
// Main React Native app component

import React, { useEffect } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { NavigationContainer } from '@react-navigation/native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { setStorageAdapter, getAuthToken, useAuthStore } from '@nutrition/shared';
import { mobileStorageAdapter } from './src/lib/storage';
import { RootNavigator } from './src/navigation/RootNavigator';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      retry: 1,
    },
  },
});

function App(): React.JSX.Element {
  const refreshUser = useAuthStore((state) => state.refreshUser);

  useEffect(() => {
    // Initialize storage adapter for shared API client
    setStorageAdapter(mobileStorageAdapter);

    // Check for existing auth token and refresh user
    const initAuth = async () => {
      const token = await getAuthToken();
      if (token) {
        try {
          await refreshUser();
        } catch (error) {
          console.error('Failed to refresh user:', error);
        }
      }
    };

    initAuth();
  }, [refreshUser]);

  return (
    <SafeAreaProvider>
      <QueryClientProvider client={queryClient}>
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>
      </QueryClientProvider>
    </SafeAreaProvider>
  );
}

export default App;
