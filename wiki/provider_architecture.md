# Provider & Resync Guide 🔄

The Provider layer in the `like` ecosystem is responsible for state management, resource lifecycle (cancellation), and automatic synchronization.

---

## 🏆 The Complete "Gold Standard" Provider

This example combines state management, resource cleanup, cross-notifier syncing, and auto-recovery into a single production-grade class.

```dart
class UserProvider extends ChangeNotifier with LikeAutoReconnectMixin {
  final _repository = UserRepository();

  // 1. State Variables & Cancellation Tokens
  LikeStateResponse<User> _userDetail = LikeStateResponse.idle();
  LikeStateResponse<User> get userDetail => _userDetail;
  CancelToken? _userCT;

  UserProvider(String userId) {
    // 2. Initialize the Sync Engine
    initAutoReconnect();

    // 3. Declarative Sync: Auto-refresh if profile updates elsewhere
    syncWith<User>(
      endpoint: '/users/$userId',
      action: () => loadUser(userId),
      state: () => userDetail,
      cancelToken: () => _userCT,
    );
  }

  // 4. Primary Get Method using the 'fetcher' helper
  Future<LikeStateResponse<User>> loadUser(String id, {ARS? ars}) async {
    return await fetcher<User>(
      ars: ars,
      ct: _userCT,
      onRotate: (next) => _userCT = next,
      onUpdate: (state) => _userDetail = state,
      action: (ct, finalArs) => _repository.getUser(id, ars: finalArs, cancelToken: ct),
    );
  }

  // 5. Global Reconnection Recovery Hook
  @override
  bool get shouldRetry => userDetail.isError || userDetail.isException;

  @override
  Future<void> onReconnect() async {
    if (userDetail.data != null) {
      await loadUser(userDetail.data!.id);
    }
  }

  // 6. Utility: Returns cached data or fetches it if missing
  Future<User> ensureUser(String id) async {
    return await loadOrFetch(userDetail, () => loadUser(id));
  }

  // 7. Reset: Return to initial state (e.g., on Logout)
  void reset() {
    cancelTokenNow(_userCT, 'Provider Reset');
    _userDetail = LikeStateResponse.idle();
    notifyListeners();
  }

  // 8. Lifecycle Cleanup
  @override
  void dispose() {
    cancelTokenNow(_userCT, 'Provider Disposed');
    super.dispose(); // CRITICAL: Shuts down sync listeners
  }
}
```

---

## ⚡ Cross-Notifier Synchronization (`syncWith`)

Use this for **Cross-Screen** updates. When data changes in another part of the app (e.g., an Edit screen calls `LikeClient().notifyRefresh('/users/123')`), this provider stays in sync automatically.

---

## 🌐 Global Reconnection Recovery (`onReconnect`)

This is a **Global Recovery Hook** triggered when the device returns online. It ensures the current screen "fixes itself" after a connection drop without user intervention.

---

## 🛡️ Avoiding Collisions (Race Conditions)

The `like` engine is **Safe-by-Design** thanks to **CancelToken Rotation**:
*   If `onReconnect` and `syncWith` trigger simultaneously, the `fetcher` will **automatically cancel** the first request and let the newest one win.
*   **Recommendation**: Do not `syncWith` the same endpoint that your `onReconnect` is already retrying in the same provider to avoid unnecessary request starts.

---

## 🏗️ The `loadOrFetch` Pattern

Returns existing successful data immediately or triggers a fetch if data is missing or in an error state.

```dart
final user = await loadOrFetch(userDetail, () => loadUser(id));
```

---

## 📋 Best Practices & Memory Safety

1.  **Initialize Early**: Always call `initAutoReconnect()` in your constructor.
2.  **CRITICAL: Super Dispose**: You **MUST** call `super.dispose()`. This shuts down the `syncWith` listener. 
3.  **Specific Syncing**: Use `syncWith` for endpoints that represent "Shared Truth" (e.g., Auth state, Profile, Cart).
4.  **Resource Cancellation**: Use `cancelTokenNow()` in your `dispose()` or `reset()` methods to immediately kill pending network requests.
