---
name: mobile-react-native
description: |
  React Native patterns: Expo project setup, Expo Router file-based navigation, FlatList
  performance (getItemLayout, removeClippedSubviews), Reanimated on UI thread, AsyncStorage
  alternatives, push notifications, deep linking, New Architecture.
  Use when building React Native apps, optimizing lists, implementing navigation.
allowed-tools: Read, Grep, Glob
---

# React Native Patterns

## When to Use This Skill
- Setting up a new Expo project with routing
- Optimizing FlatList for large datasets
- Implementing animations with Reanimated 3
- Managing app state and storage
- Setting up push notifications and deep linking

## Core Principles

1. **Expo managed workflow first** — only eject when native module is absolutely needed
2. **FlatList not ScrollView** — for lists >50 items, ScrollView renders all at once
3. **Reanimated on UI thread** — animations must not trigger JS bridge
4. **Zustand for client state** — Redux is overkill for most mobile apps
5. **MMKV for storage** — 10× faster than AsyncStorage; use for non-sensitive data

---

## Patterns ✅

### Expo Project Setup with Router

```bash
# Create project with Expo Router (file-based routing)
npx create-expo-app@latest myapp --template tabs

# Directory structure
app/
  (tabs)/
    _layout.tsx         # Tab navigator
    index.tsx           # Home tab
    explore.tsx         # Explore tab
  _layout.tsx           # Root layout (fonts, theme, auth)
  +not-found.tsx        # 404 screen
  auth/
    login.tsx
    register.tsx
components/
  ui/
    ThemedText.tsx
    ThemedView.tsx
```

```tsx
// app/_layout.tsx — root layout with auth guard
import { Stack } from 'expo-router';
import { useAuth } from '@/stores/authStore';
import { Redirect } from 'expo-router';

export default function RootLayout() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) return <SplashScreen />;

  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="auth/login" options={{ title: 'Sign In' }} />
    </Stack>
  );
}

// Auth guard component — redirect to login if not authenticated
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Redirect href="/auth/login" />;
  return <>{children}</>;
}
```

### FlatList Performance Optimization

```tsx
// Optimized FlatList for large datasets

interface OrderItem {
  id: string;
  status: string;
  total: number;
  createdAt: string;
}

const ITEM_HEIGHT = 80;  // Fixed height — enables getItemLayout

export function OrdersList({ orders }: { orders: OrderItem[] }) {
  return (
    <FlatList
      data={orders}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <OrderCard order={item} />}

      // Performance optimizations
      getItemLayout={(_, index) => ({
        length: ITEM_HEIGHT,
        offset: ITEM_HEIGHT * index,
        index,
      })}
      // ↑ Avoids measuring each item — instant scroll to index

      removeClippedSubviews={true}   // Detach off-screen components
      maxToRenderPerBatch={10}        // Render 10 items per batch
      updateCellsBatchingPeriod={50} // Batch updates every 50ms
      windowSize={10}                // Keep 10 screen heights of items in memory
      initialNumToRender={15}        // Render 15 items initially

      // Smooth rendering
      ItemSeparatorComponent={() => <View style={styles.separator} />}
      ListEmptyComponent={<EmptyState />}
      ListFooterComponent={orders.length >= 20 ? <LoadMoreButton /> : null}
    />
  );
}

// OrderCard: always memoize list items
const OrderCard = React.memo(({ order }: { order: OrderItem }) => {
  return (
    <View style={[styles.card, { height: ITEM_HEIGHT }]}>
      <Text>{order.status}</Text>
      <Text>${order.total}</Text>
    </View>
  );
});
// ↑ Prevents re-render when parent re-renders but order data unchanged
```

### Reanimated 3 (UI Thread Animations)

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  runOnJS,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

// Animated values run on UI thread — no JS bridge, 60/120fps
export function SwipeableCard({ onDismiss }: { onDismiss: () => void }) {
  const translateX = useSharedValue(0);
  const opacity = useSharedValue(1);

  const swipeGesture = Gesture.Pan()
    .onUpdate((event) => {
      translateX.value = event.translationX;
      opacity.value = 1 - Math.abs(event.translationX) / 300;
    })
    .onEnd((event) => {
      if (Math.abs(event.translationX) > 150) {
        // Dismissed — animate off screen, then call JS callback
        translateX.value = withTiming(event.translationX > 0 ? 500 : -500, {}, (finished) => {
          if (finished) runOnJS(onDismiss)();  // Call JS function from UI thread
        });
      } else {
        // Snap back
        translateX.value = withSpring(0);
        opacity.value = withSpring(1);
      }
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
    opacity: opacity.value,
  }));

  return (
    <GestureDetector gesture={swipeGesture}>
      <Animated.View style={[styles.card, animatedStyle]}>
        {/* card content */}
      </Animated.View>
    </GestureDetector>
  );
}
```

### State Management with Zustand

```tsx
// stores/authStore.ts
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

// MMKV storage adapter for Zustand persist
const mmkvStorage = {
  getItem: (key: string) => storage.getString(key) ?? null,
  setItem: (key: string, value: string) => storage.set(key, value),
  removeItem: (key: string) => storage.delete(key),
};

interface AuthState {
  user: User | null;
  accessToken: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
}

export const useAuth = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      isAuthenticated: false,
      isLoading: false,
      login: async (credentials) => {
        set({ isLoading: true });
        try {
          const { user, accessToken } = await authService.login(credentials);
          set({ user, accessToken, isAuthenticated: true, isLoading: false });
        } catch (err) {
          set({ isLoading: false });
          throw err;
        }
      },
      logout: () => set({ user: null, accessToken: null, isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => mmkvStorage),
      // Only persist non-sensitive data (accessToken is sensitive — consider SecureStore)
      partialize: (state) => ({ user: state.user }),
    }
  )
);
```

---

## Anti-Patterns ❌

### ScrollView for Long Lists
**What it is**: `<ScrollView>{items.map(item => <ItemCard />)}</ScrollView>`
**What breaks**: ScrollView renders ALL items at once. 1000 items = 1000 components mounted simultaneously. Memory spike. Janky scroll. App may crash on low-end devices.
**Fix**: `FlatList` with `keyExtractor` and `getItemLayout` for fixed-height items.

### Inline Styles and Functions in FlatList renderItem
```tsx
// Wrong — new function and object on every render
<FlatList
  renderItem={({ item }) => (
    <View style={{ padding: 16, margin: 8 }}>  {/* New object every render */}
      <Text onPress={() => navigate(item.id)}>  {/* New function every render */}
        {item.title}
      </Text>
    </View>
  )}
/>

// Correct — extract and memoize
const styles = StyleSheet.create({ card: { padding: 16, margin: 8 } });
const renderItem = useCallback(({ item }: { item: Item }) => (
  <ItemCard item={item} />
), []);  // Stable reference
```

### JS Thread Animations (Not Reanimated)
**What it is**: `Animated.Value` from React Native core with `useNativeDriver: false`.
**What breaks**: Animation runs on JS thread. If JS is busy (fetch, parsing), animation stutters. 30fps animations instead of 60/120fps.
**Fix**: Reanimated 3 with `useSharedValue` + `useAnimatedStyle` — runs entirely on UI thread.

---

## Quick Reference

```
Expo managed: start here, only eject when native module required
FlatList vs ScrollView: FlatList for >50 items (virtual rendering)
getItemLayout: required for fixed-height items, enables instant scrollTo
removeClippedSubviews: true for long lists
Reanimated: useSharedValue + useAnimatedStyle — UI thread only
MMKV: 10× faster than AsyncStorage for non-sensitive data
SecureStore: for tokens, passwords (encrypted, keychain-backed)
Zustand: lightweight state management, no Redux boilerplate
React.memo: always wrap FlatList items to prevent unnecessary re-renders
```
