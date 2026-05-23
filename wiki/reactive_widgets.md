# LIKE Reactive & Sliver Widgets Guide

This guide explains how to use the built-in reactive builders in the `like` package to create responsive, high-performance UIs.

---

## 🏗️ 1. Box vs. Sliver: Which to use?

| Widget Category | Layout Type | Use Case |
| :--- | :--- | :--- |
| **Standard Builders** | Box-based | Inside `Column`, `Stack`, or as a full-page content. |
| **Sliver Builders** | Sliver-based | Inside a `CustomScrollView` or `NestedScrollView`. |

---

## 📦 2. Single Source Builders

### `LikeBuilder<T>`
The most commonly used widget. It observes a single `LikeStateResponse` and handles the entire lifecycle.

**Example: Full State Implementation**
```dart
LikeBuilder<List<User>>(
  observe: () => userProvider.users,
  
  // 🟢 SUCCESS: Called when data is ready (or during background refresh)
  onSuccess: (data, isRefreshing, isSWR) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, i) => ListTile(title: Text(data[i].name)),
    );
  },

  // 🟡 LOADING: Called during the VERY FIRST load
  onLoading: () => const Center(child: CircularProgressIndicator()),

  // ⚪ IDLE: Initial state before any request starts
  onIdle: () => const Center(child: Text("Waiting to load users...")),

  // 🔴 ERROR: Logical failure (e.g., 404, 400)
  onError: (error) => MyErrorWidget(
    title: "Request Failed",
    message: error.message,
  ),

  // 🟣 EXCEPTION: Fatal failure (e.g., Timeout, No Internet)
  onException: (message) => MyFatalErrorWidget(message: message),

  // ⚡ LISTENER: Side-effects (Toasts, Navigation, Haptics)
  listener: (response) {
    if (response.isSuccess) LikeToast.success("Data Synced");
  },
)
```

---

## 🔗 3. Sliver Source Builders

### `LikeSliverBuilder<T>`
Exactly like `LikeBuilder`, but every handler must return a **Sliver**.

```dart
CustomScrollView(
  slivers: [
    LikeSliverBuilder<List<Product>>(
      observe: () => productProvider.products,
      onSuccess: (data, _, __) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => ProductCard(data[i]),
          childCount: data.length,
        ),
      ),
      onLoading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      onIdle: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      onError: (error) => SliverToBoxAdapter(child: ErrorCard(error)),
      onException: (msg) => SliverToBoxAdapter(child: FatalCard(msg)),
    ),
  ],
)
```

---

## 🔗 4. Multi-Source Builders

Wait for **multiple** API calls to resolve before showing the UI.

```dart
LikeMultiBuilder(
  observes: [
    () => authProvider.profile,
    () => statsProvider.activity,
  ],
  onSuccess: (results, isRefreshing, _) {
    final profile = results[0] as Profile;
    final activity = results[1] as List<Activity>;
    return Column(children: [ProfileCard(profile), ActivityList(activity)]);
  },
  onLoading: () => const Center(child: CircularProgressIndicator()),
  onIdle: () => const Text("Select an account to view stats"),
  onError: (error) => Text("Error loading data: ${error.message}"),
  onException: (msg) => Text("Connection Fatal: $msg"),
)
```

---

## 🎯 5. Performance Selectors

Selectors only rebuild when the **specific property** you select changes.

```dart
LikeSelector<UserProvider, List<User>>(
  selector: (context, provider) => provider.users,
  onSuccess: (users, _, __) => MyUserList(users),
  onLoading: () => const MySkeletonLoader(),
  onIdle: () => const Text("Search for users"),
  onError: (err) => Text(err.message),
  onException: (msg) => Text(msg),
)
```

---

## 💡 6. Logic Summary

### "Sticky" UI Behavior
- When the state changes from `Success` -> `Refreshing` (Pull-to-refresh), the widget **does not** switch to `onLoading`.
- Instead, it stays in `onSuccess` and provides `isRefreshing: true`. 
- This prevents the UI from "flickering" or showing a blank screen during updates.

### Error vs. Exception
- **`onError`**: The server responded, but with an error (e.g., `401`, `404`, `500`). Access the `LikeError` object for codes and localized messages.
- **`onException`**: The server could not be reached or the system failed (e.g., `No Internet`, `Timeout`, `SocketException`).
