// packages/web/app/providers.tsx
'use client';

import { useEffect } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { setStorageAdapter, getAuthToken, useAuthStore } from '@nutrition/shared';
import { webStorageAdapter } from '@/lib/storage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      retry: 1,
    },
  },
});

export function Providers({ children }: { children: React.ReactNode }) {
  const refreshUser = useAuthStore((state) => state.refreshUser);

  useEffect(() => {
    // Initialize storage adapter for shared API client
    setStorageAdapter(webStorageAdapter);

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
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}
