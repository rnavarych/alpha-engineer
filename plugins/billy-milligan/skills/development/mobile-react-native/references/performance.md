# React Native Performance

## FlatList Optimization

```tsx
const ITEM_HEIGHT = 80;

export function OrdersList({ orders }: { orders: OrderItem[] }) {
  const renderItem = useCallback(({ item }: { item: OrderItem }) => (
    <OrderCard order={item} />
  ), []);

  const keyExtractor = useCallback((item: OrderItem) => item.id, []);

  return (
    <FlatList
      data={orders}
      renderItem={renderItem}
      keyExtractor={keyExtractor}

      // Layout optimization — skip measuring each item
      getItemLayout={(_, index) => ({
        length: ITEM_HEIGHT,
        offset: ITEM_HEIGHT * index,
        index,
      })}

      // Memory optimization
      removeClippedSubviews={true}       // Detach off-screen items
      maxToRenderPerBatch={10}           // Items per render batch
      updateCellsBatchingPeriod={50}     // Batch interval (ms)
      windowSize={10}                     // Screens of content to keep
      initialNumToRender={15}            // Initial items

      // UX
      ItemSeparatorComponent={Separator}
      ListEmptyComponent={<EmptyState />}
      ListFooterComponent={<LoadMore />}
    />
  );
}

// ALWAYS memoize list items
const OrderCard = React.memo(({ order }: { order: OrderItem }) => (
  <View style={[styles.card, { height: ITEM_HEIGHT }]}>
    <Text style={styles.status}>{order.status}</Text>
    <Text style={styles.total}>${order.total}</Text>
  </View>
));

// Use StyleSheet.create — not inline objects
const styles = StyleSheet.create({
  card: { padding: 16, borderBottomWidth: 1, borderBottomColor: '#eee' },
  status: { fontSize: 14, color: '#666' },
  total: { fontSize: 18, fontWeight: '600' },
});
```

## MMKV Storage

```typescript
import { MMKV } from 'react-native-mmkv';

// 10x faster than AsyncStorage — synchronous, no bridge
const storage = new MMKV();

// Simple key-value
storage.set('user.name', 'John');
const name = storage.getString('user.name');

// JSON objects
storage.set('user', JSON.stringify(user));
const user = JSON.parse(storage.getString('user') ?? '{}');

// Boolean flags
storage.set('onboarding.completed', true);
const completed = storage.getBoolean('onboarding.completed');

// Delete
storage.delete('user');

// Encrypted instance — for semi-sensitive data
const secureStorage = new MMKV({
  id: 'secure-store',
  encryptionKey: 'your-encryption-key',
});

// For truly sensitive data (tokens, passwords):
// Use expo-secure-store (Keychain on iOS, Keystore on Android)
import * as SecureStore from 'expo-secure-store';
await SecureStore.setItemAsync('access_token', token);
const token = await SecureStore.getItemAsync('access_token');
```

## Hermes Engine

```
Hermes is the default JS engine for React Native:
  - Bytecode precompilation — faster startup (up to 50%)
  - Lower memory usage — optimized garbage collector
  - Improved performance for large apps

Verify Hermes is enabled:
  const isHermes = () => !!global.HermesInternal;

Enable in app.json (Expo):
  {
    "expo": {
      "jsEngine": "hermes"  // Default since SDK 48
    }
  }
```

## Image Optimization

```tsx
import { Image } from 'expo-image';

// expo-image: cached, progressive, blurhash placeholder
<Image
  source={{ uri: 'https://cdn.example.com/product.jpg' }}
  placeholder={{ blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH' }}
  contentFit="cover"
  transition={200}
  style={{ width: 200, height: 200 }}
  cachePolicy="memory-disk"  // Cache in memory and disk
/>

// Prefetch images for lists
Image.prefetch([
  'https://cdn.example.com/1.jpg',
  'https://cdn.example.com/2.jpg',
]);

// Use smaller images — request appropriate size from CDN
const imageUrl = `${CDN_BASE}/product.jpg?w=400&q=80`;
```

## Avoiding Re-renders

```tsx
// 1. React.memo for components that receive same props
const ExpensiveComponent = React.memo(({ data }: Props) => {
  // Only re-renders when data changes (shallow comparison)
  return <View>{/* expensive rendering */}</View>;
});

// 2. useCallback for functions passed as props
const handlePress = useCallback((id: string) => {
  navigation.push('Details', { id });
}, [navigation]);

// 3. useMemo for expensive computations
const sortedOrders = useMemo(
  () => orders.sort((a, b) => b.createdAt - a.createdAt),
  [orders]
);

// 4. Avoid anonymous functions in JSX
// BAD: <Button onPress={() => doThing(id)} />  // New function every render
// GOOD: <Button onPress={handlePress} />        // Stable reference
```

## Anti-Patterns
- ScrollView for long lists — renders ALL items, crashes on 1000+ items
- Inline styles in FlatList — new object every render, triggers re-render
- AsyncStorage for frequent reads — use MMKV (synchronous, 10x faster)
- Large images without caching — use expo-image with blurhash placeholder
- `console.log` in production — slows rendering, use structured logging

## Quick Reference
```
FlatList: getItemLayout + removeClippedSubviews + React.memo items
MMKV: synchronous, 10x AsyncStorage — non-sensitive data
SecureStore: Keychain/Keystore — tokens, passwords
Hermes: default engine, bytecode precompilation, lower memory
expo-image: caching + blurhash + transitions (not <Image>)
React.memo: wrap list items and stable-props components
useCallback: stable function references for props
StyleSheet.create: static styles, no inline objects in render
```
