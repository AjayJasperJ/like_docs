# Authentication Guide for LIKE 🔐

This guide provides a deep dive into the **Dynamic Authentication Interceptor** in the LIKE networking engine. It covers everything from basic token injection to advanced concurrent refresh synchronization and multi-user routing.

---

## 🚀 1. The Core Lifecycle

The `LikeAuthInterceptor` operates on every request. It doesn't just add headers; it manages the entire session lifecycle automatically.

### The Standard Path
1.  **Request Initiation**: The client checks `Options.extra['withAuth']`. If true (default), it triggers the `getToken()` hook.
2.  **Token Injection**: The token is added as a `Bearer` token in the `Authorization` header.
3.  **Api-Key Injection**: If `getApiKey()` is provided, it is added to the `x-api-key` header.

---

## 🔄 2. Silent Refresh & Concurrency Guard

One of the most complex parts of networking is handling **token expiration**. LIKE handles this silently in the background using a **Concurrency Lock**.

### The Problem: "Refresh Storms"
If a user has 5 concurrent requests running when the token expires, all 5 will return a `401 Unauthorized` at the same time. Without a guard, your app would call the `refreshToken` API 5 times.

### The Solution: Synchronization Lock
LIKE uses an internal `Completer` (`_refreshCompleter`) to synchronize these requests:
1.  The **First** 401 request locks the engine and calls `refreshToken()`.
2.  The **Remaining** 401 requests see the lock and "wait" for the first one to finish.
3.  Once the new token is acquired, **ALL** waiting requests are automatically retried with the new token.

```dart
Like(
  refreshToken: () async {
    // This runs ONCE even if 100 requests fail simultaneously
    final response = await AuthService.refresh();
    return response.token;
  },
  child: const MyApp(),
)
```

---

## 👥 3. Advanced Multi-User & Multi-Server Auth

If your app supports multiple accounts or communicates with multiple servers requiring different auth strategies, you can make the hooks dynamic.

### Dynamic Context-Based Auth
Since hooks are functions, they can access your app's current state (Provider, Bloc, GetX, etc.) to decide which token to return.

```dart
Like(
  getToken: () async {
    final activeAccount = MyAuthStore.activeAccount;
    
    // Choose token based on the target server or active user
    if (activeAccount.isEnterprise) {
      return activeAccount.enterpriseToken;
    }
    return activeAccount.personalToken;
  },
)
```

---

## ⚠️ 4. Failure Handling & Recovery

What happens if the `refreshToken` call itself fails or returns an invalid value?

1.  **Null Return**: If `refreshToken()` returns `null`, the engine assumes the session is dead and triggers `onLogout()`.
2.  **Retry Failure**: If the retried request fails with a 401 *again* immediately after a refresh, it prevents infinite loops and triggers `onLogout(force: true)`.
3.  **Exception**: If an error occurs inside the `refreshToken` function, it is caught, and the user is logged out safely.

```dart
Like(
  onLogout: ({int? statusCode, bool force}) {
    // Standard logout logic
    NotificationService.show("Session Expired");
    AppRouter.clearAndGoToLogin();
  },
)
```

---

## 📊 5. UI Integration (Reactive Auth State)

You can listen to the authentication engine's state to show "Refreshing Session" overlays or disable buttons while a token is being rotated.

```dart
ValueListenableBuilder<bool>(
  valueListenable: LikeAuthInterceptor.isRefreshing,
  builder: (context, refreshing, child) {
    if (refreshing) {
      return const MySyncingOverlay(message: "Updating your session...");
    }
    return child!;
  },
  child: const HomeScreen(),
)
```

---

## 🛠️ 6. Manual Configuration Summary

| Hook | Type | Purpose |
| :--- | :--- | :--- |
| `getToken` | `FutureOr<String?> Function()` | Provides the access token for every request. |
| `getApiKey` | `FutureOr<String?> Function()` | Provides an optional API key. |
| `refreshToken` | `FutureOr<String?> Function()` | Logic to get a new token when a 401 occurs. |
| `onLogout` | `Function({int?, bool})` | Logic to clear local data and navigate to login. |
| `withAuth` | `bool` (per request) | Whether to include auth headers for a specific call. |

---

## 🏗️ 7. Multi-Interceptor Architecture (Extreme Cases)

If you need completely different auth engines for different `LikeClient` instances, you can instantiate the interceptor manually:

```dart
final adminClient = LikeClient(
  interceptors: [
    LikeAuthInterceptor(
      getToken: () => adminToken,
      refreshToken: () => adminRefresh(),
    ),
  ],
);
```

---
*Developed by the LIKE Networking Team.*
