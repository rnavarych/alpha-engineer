# Navigation Patterns

## Expo Router — File-Based Routing

```
app/
  _layout.tsx             # Root layout (providers, fonts, auth guard)
  (tabs)/
    _layout.tsx           # Tab navigator layout
    index.tsx             # / — Home tab
    orders.tsx            # /orders — Orders tab
    profile.tsx           # /profile — Profile tab
  orders/
    [id].tsx              # /orders/:id — Order detail
    new.tsx               # /orders/new — Create order
  auth/
    login.tsx             # /auth/login
    register.tsx          # /auth/register
  (modals)/
    _layout.tsx           # Modal group layout
    settings.tsx          # Modal: settings
  +not-found.tsx          # 404 screen
```

## Root Layout with Auth Guard

```tsx
// app/_layout.tsx
import { Stack, Redirect } from 'expo-router';
import { useAuth } from '@/stores/auth';

export default function RootLayout() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) return <SplashScreen />;

  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="orders/[id]" options={{ title: 'Order Details' }} />
      <Stack.Screen
        name="(modals)/settings"
        options={{ presentation: 'modal', title: 'Settings' }}
      />
      <Stack.Screen name="auth/login" options={{ headerShown: false }} />
    </Stack>
  );
}
```

## Tab Navigator

```tsx
// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs screenOptions={{
      tabBarActiveTintColor: '#007AFF',
      tabBarStyle: { paddingBottom: 8, height: 60 },
    }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="orders"
        options={{
          title: 'Orders',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="receipt" size={size} color={color} />
          ),
          tabBarBadge: 3, // Show badge with count
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="person" size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
```

## Deep Linking

```json
// app.json — URL scheme and universal links
{
  "expo": {
    "scheme": "myapp",
    "ios": {
      "associatedDomains": ["applinks:myapp.com"]
    },
    "android": {
      "intentFilters": [{
        "action": "VIEW",
        "autoVerify": true,
        "data": [{ "scheme": "https", "host": "myapp.com", "pathPrefix": "/orders" }],
        "category": ["BROWSABLE", "DEFAULT"]
      }]
    }
  }
}
```

```tsx
// Handle deep link: myapp://orders/123 or https://myapp.com/orders/123
// Expo Router handles this automatically via file-based routing
// /orders/[id].tsx matches both deep link patterns

// Programmatic navigation
import { router } from 'expo-router';

// Push (adds to stack)
router.push('/orders/123');

// Replace (no back button)
router.replace('/auth/login');

// Back
router.back();

// Navigate with params
router.push({ pathname: '/orders/[id]', params: { id: '123' } });
```

## Auth Flow Pattern

```tsx
// stores/auth.ts — Zustand with MMKV persistence
import { create } from 'zustand';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

export const useAuth = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,

  initialize: async () => {
    const token = storage.getString('access_token');
    if (token) {
      try {
        const user = await fetchCurrentUser(token);
        set({ user, isAuthenticated: true, isLoading: false });
      } catch {
        storage.delete('access_token');
        set({ isLoading: false });
      }
    } else {
      set({ isLoading: false });
    }
  },

  login: async (email, password) => {
    const { user, token } = await api.login(email, password);
    storage.set('access_token', token);
    set({ user, isAuthenticated: true });
  },

  logout: () => {
    storage.delete('access_token');
    set({ user: null, isAuthenticated: false });
    router.replace('/auth/login');
  },
}));

// Protected route wrapper
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Redirect href="/auth/login" />;
  return <>{children}</>;
}
```

## Anti-Patterns
- Nesting navigators too deep — 3+ levels causes back button confusion
- Not using `presentation: 'modal'` for modals — full screen push instead
- Hardcoded route strings everywhere — use typed routes from Expo Router
- Missing deep link configuration — links open browser instead of app

## Quick Reference
```
File-based routing: app/ directory mirrors URL structure
[id].tsx: dynamic route — access via useLocalSearchParams()
_layout.tsx: navigator definition (Stack, Tabs, Drawer)
(group)/: route group — shared layout without URL segment
+not-found.tsx: 404 fallback screen
router.push: add to stack, router.replace: no back button
Deep linking: scheme + associatedDomains + intentFilters
Auth guard: check auth in root _layout.tsx, Redirect if not authenticated
```
