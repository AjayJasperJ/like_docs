<p align="center">
  <img src="https://raw.githubusercontent.com/AjayJasperJ/like_docs/refs/heads/main/assets/banner.png" alt="LIKE — Link Intelligent Kernel Engine" width="100%"/>
</p>

<h1 align="center">LIKE — Link Intelligent Kernel Engine</h1>

<p align="center">
  <a href="https://pub.dev/packages/like"><img src="https://img.shields.io/pub/v/like.svg?label=pub.dev&color=blue" alt="pub.dev"/></a>
  <a href="https://pub.dev/packages/like"><img src="https://img.shields.io/pub/likes/like?label=likes&color=pink" alt="likes"/></a>
  <a href="https://pub.dev/packages/like/score"><img src="https://img.shields.io/pub/points/like?label=pub%20points&color=brightgreen" alt="pub points"/></a>
  <a href="https://pub.dev/packages/like"><img src="https://img.shields.io/pub/popularity/like?label=popularity" alt="popularity"/></a>
  <a href="https://github.com/AjayJasperJ/like_docs/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License"/></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/platform-Flutter-02569B?logo=flutter" alt="Flutter"/></a>
</p>

<p align="center">
  <strong>Enterprise-grade, offline-first networking for Flutter — built on Dio with reactive state, encrypted media cache, smart sync, and zero-boilerplate UI bindings.</strong>
</p>

---

## Why LIKE?

| Capability | Raw Dio / HTTP | LIKE |
|:--|:--|:--|
| **Cache** | Manual or none | L1 RAM → L2 Hive disk → SWR → ETag/304 |
| **State machine** | Hand-rolled booleans | `LikeNotifierState` — loading / refreshing / SWR / error |
| **Cross-screen sync** | Global event buses | Zero-config `LikePipeline` — mutations fan-out automatically |
| **Request cancellation** | `CancelToken` per screen | Auto-rotation & disposal via `fetch` |
| **JSON parsing** | Main thread → jank | Isolate parsing for payloads > 100 KB |
| **Image cache** | Plain disk | Per-device AES-256, per-file IV, LRU pruning |
| **Offline mutations** | Crash or custom queues | Persistent Hive queue, auth-aware replay on reconnect |
| **Duplicate requests** | Wasted bandwidth | In-flight deduplication via `LikeRequestRegistry` |

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                   Reactive UI Layer                   │
│   LikeBuilder · LikeSliverBuilder · LikeSelector     │
│   LikeMultiBuilder · LikeWhen                         │
└────────────────────┬─────────────────────────────────┘
                     │ observes LikeNotifierState<T>
┌────────────────────▼─────────────────────────────────┐
│                  Provider Layer                        │
│  ChangeNotifier + LikeAutoReconnectMixin               │
│  fetch · fetcher · syncWithState · loadOrFetch         │
└────────────────────┬─────────────────────────────────┘
                     │ calls
┌────────────────────▼─────────────────────────────────┐
│               Repository Layer                         │
│  Thin call-sites returning LikeApiResult<T>            │
└────────────────────┬─────────────────────────────────┘
                     │ delegates to
┌────────────────────▼─────────────────────────────────┐
│                 Service Layer                          │
│  LikeService · LikeClient · Interceptor chain         │
└────────┬───────────┬───────────┬────────────┬────────┘
         │           │           │            │
    ┌────▼───┐  ┌────▼───┐  ┌───▼────┐  ┌───▼──────┐
    │ L1 RAM │  │L2 Hive │  │  SWR   │  │ ETag/304 │
    │ Cache  │  │  Cache │  │Revalid.│  │Validation│
    └────────┘  └────────┘  └────────┘  └──────────┘
```

### Cache Flow — L1 · L2 · SWR · ETag

| Layer | Store | Hit Behaviour |
|:--|:--|:--|
| **L1** | In-memory (`LikeRequestRegistry`) | Instant return, no I/O |
| **L2** | Hive box (disk-persistent) | Sub-ms retrieval across restarts |
| **SWR** | L2 data + background refetch | Returns stale data immediately, silently revalidates |
| **ETag / 304** | HTTP conditional request | Saves bandwidth; server confirms freshness |

---

## 1. Initialization

### Root Widget (Recommended)

Wrap your `MaterialApp` once. LIKE bootstraps Hive, connectivity, AES image-cache, auth interceptors, and toast listeners in a single call.

```dart
void main() {
  runApp(
    Like(
      baseUrl: 'https://api.example.com',
      getToken:     () async => 'current_session_token',
      refreshToken: () async => 'new_session_token',
      devTool: (child) => LikeDevTool(child: child), // optional debug overlay
      child: const MyApp(),
    ),
  );
}
```

### Manual Initialization — `LikeService.init()`

Use this when you need fine-grained control (e.g. late splash-screen init).

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  await LikeService.init(
    config: LikeConfig(
      baseUrl: 'https://api.example.com',
      encryptionKey: 'your-optional-app-key', // SHA-256 derived; omit for per-device key
      unpacker: const DefaultLikeUnpacker(
        dataKey:    'data',
        messageKey: 'message',
        statusKey:  'status',
      ),
    ),
  );
});
```

> [!IMPORTANT]
> `LikeService.init()` always initialises AES image-cache encryption **before** Hive, so `AppCacheManager` is ready before any file access.

---

## 2. Service Layer

Services return `LikeApiResult<T>` — a pure data wrapper with zero UI coupling.

```dart
class UserService {
  Future<LikeApiResult<User>> getUser(String id) async {
    return LikeClient().get('/users/$id').mapAsync(User.fromJson);
  }

  Future<LikeApiResult<List<Post>>> getUserPosts(String id) async {
    return LikeClient()
        .get('/users/$id/posts')
        .mapAsync((json) => (json as List).map(Post.fromJson).toList());
  }
}
```

---

## 3. Repository Layer

Repositories are thin call-sites that forward to the service and own any query-building logic.

```dart
class UserRepository {
  final _service = UserService();

  Future<LikeApiResult<User>> getUser(String id, {ARS? ars}) =>
      _service.getUser(id);

  Future<LikeApiResult<List<Post>>> getUserPosts(String id, {ARS? ars}) =>
      _service.getUserPosts(id);
}
```

---

## 4. Provider Layer

### Recommended — `LikeNotifierState<T>` + `fetch`

`LikeNotifierState<T>` is a **reactive `ChangeNotifier`**. Any mutation (`.clear()`, etc.) instantly drives all observing `LikeBuilder` widgets without a manual `notifyListeners()` call.

```dart
class UserNotifier extends ChangeNotifier with LikeAutoReconnectMixin {
  final _repo = UserRepository();

  final userState = LikeNotifierState<User>(
    // mapper enables zero-config pipeline sync across all screens
    mapper: (json) => User.fromJson(json as Map<String, dynamic>),
  );

  Future<void> fetchUser(String id, {ARS? ars}) async {
    await fetch<User>(
      state:      userState,
      ars:        ars,
      autoResync: true,
      action:     (ct, actionArs) => _repo.getUser(id, ars: actionArs),
    );
  }

  @override
  void dispose() {
    super.dispose(); // auto-cancels tokens and pipeline listeners
  }
}
```

**Pipeline sync:** when `mapper` is set, `fetch()` binds the endpoint + query to `userState` via Zone injection. Any `POST`/`PUT`/`DELETE` on that endpoint broadcasts a `LikePipeline` event that updates every screen observing the same state — with no extra code at the call site.

### Classic — `fetcher` + manual `CancelToken`

```dart
class PostNotifier extends ChangeNotifier with LikeAutoReconnectMixin {
  final _repo = PostRepository();

  LikeStateResponse<List<Post>> state = LikeStateResponse.idle();
  CancelToken? _ct;

  Future<void> fetchPosts({ARS? ars}) async {
    await fetcher<List<Post>>(
      ct:       _ct,
      onRotate: (next) => _ct = next,
      onUpdate: (s)    => state = s,
      action:   (ct, ars) => _repo.getPosts(ars: ars),
    );
    notifyListeners();
  }
}
```

**State transitions in `fetcher`:**

- `ars.refresh == false` → `LikeStateResponse.loading()` (clean slate)
- `ars.refresh == true` + existing data → `LikeStateResponse.refreshing(currentData)` — sticky data stays visible

---

## 5. Reactive UI

### `LikeBuilder<T>`

Primary widget — subscribes directly to `LikeNotifierState` as a `Listenable`.

```dart
LikeBuilder<User>(
  observe:   () => userNotifier.userState,
  onSuccess: (user, isRefreshing, isFromSWR) => Stack(
    children: [
      UserProfileView(user: user),
      if (isRefreshing) const LinearProgressIndicator(),
    ],
  ),
  onLoading: () => const ShimmerLoader(),
  onError:   (error) => ErrorView(message: error.message),
);
```

**Rendering guarantees (v1.2.1+):**

| State | Renders |
|:--|:--|
| `loading` | Always `onLoading` — no sticky-data leak |
| `refreshing` | `onSuccess(data, isRefreshing: true)` — keeps old data visible |
| `staleWhileRevalidate` | `onSuccess(data, isFromSWR: true)` |
| `success` | `onSuccess(data, false, false)` |
| `error` | `onError` |
| `exception` | `onException` |
| `idle` | `onIdle` |

### `LikeSliverBuilder<T>`

Same semantics as `LikeBuilder` but returns `List<Widget>` slivers for `CustomScrollView`.

```dart
LikeSliverBuilder<List<Todo>>(
  observe:   () => todoNotifier.todosState,
  onSuccess: (todos, isRefreshing, isFromSWR) => [
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => TodoTile(todo: todos[i]),
        childCount: todos.length,
      ),
    ),
  ],
  onLoading: () => [const SliverFillRemaining(child: ShimmerLoader())],
);
```

### `LikeSelector` & `LikeSelectorSliver`

Rebuilds only when a specific slice of state changes — ideal for shared complex models.

```dart
LikeSelector<UserNotifier, User>(
  selector:  (context, notifier) => notifier.userState,
  onSuccess: (user, isRefreshing, isFromSWR) => ProfileCard(user: user),
);
```

### `LikeMultiBuilder` & `LikeMultiSliverBuilder`

Aggregate multiple states into one unified widget.

```dart
LikeMultiBuilder(
  observes: [
    () => userNotifier.userState,
    () => postNotifier.postsState,
  ],
  onSuccess: (results, isRefreshing, isFromSWR) {
    final user  = results[0] as User;
    final posts = results[1] as List<Post>;
    return UserDashboard(user: user, posts: posts);
  },
  onLoading: () => const Center(child: CircularProgressIndicator()),
  onError:   (error) => ErrorView(message: error.message),
);
```

### `LikeWhen<T>`

Pattern-matching shorthand for simple state-to-widget mapping — useful inside `build()` when you already hold a `LikeStateResponse<T>` snapshot.

```dart
LikeWhen<User>(
  state:     userNotifier.userState.value,
  onSuccess: (user) => Text(user.name),
  onLoading: () => const CircularProgressIndicator(),
  onError:   (err) => Text(err.message),
);
```

---

## Update Notifiers

LIKE ships two complementary helpers for reacting to `LikeStateResponse` outcomes **outside** the widget tree — typically inside `onPressed` handlers, form submit callbacks, or post-fetch side-effects.

### `updateNotifier` — Full feedback (toasts + haptics)

Use for primary user-triggered actions where you want automatic UI feedback out of the box.

```dart
await updateNotifier<User>(
  response: userNotifier.userState.value,
  context:  context,

  // Lifecycle callbacks
  onInit:      (state)   async => debugPrint('Starting: $state'),
  onSuccess:   (user)    async => Navigator.pushNamed(context, '/profile'),
  onError:     (error)   async => debugPrint('API error: ${error.message}'),
  onException: (message) async => debugPrint('Exception: $message'),

  // Toast control (all independently toggleable)
  disableLoadingToast:   true,   // silent during load (default)
  disableSuccessToast:   false,  // shows green toast on success
  disableErrorToast:     false,  // shows warning toast on error
  disableExceptionToast: false,  // shows red toast on exception
  disableCancelledToast: true,   // silent on Dio cancel (default)

  // Haptics — light on success, medium on error, heavy on exception
  enableHaptics: true,

  // Override any toast message per-state
  messageOverrides: {
    LikeState.success:   'Profile updated!',
    LikeState.error:     'Could not save changes.',
  },
);
```

**Built-in behaviour by state:**

| State | Toast | Haptic | Callback |
|:--|:--|:--|:--|
| `loading` | Optional loading toast | — | `onInit` |
| `success` | ✅ Green (if enabled) | Light | `onSuccess(data)` |
| `refreshing` / `SWR` | — | — | `onSuccess(data)` |
| `error` | ⚠️ Warning (if enabled) | Medium | `onError(LikeError)` |
| `exception` | ❌ Red (if enabled) | Heavy | `onException(message)` |

---

### `likeWhenNotifier` — Raw control (no toasts, no haptics)

Use when you want full manual control over side-effects — e.g. showing your own bottom sheet, triggering analytics, or navigating without any automatic toast.

```dart
await likeWhenNotifier<List<Todo>>(
  response: todoNotifier.todosState.value,

  onInit:      (state)   async => myLoadingOverlay.show(),
  onSuccess:   (todos)   async {
    myLoadingOverlay.hide();
    setState(() => _todos = todos);
  },
  onError:     (error)   async {
    myLoadingOverlay.hide();
    showCustomErrorSheet(error.message);
  },
  onException: (message) async => logger.error(message),
);
```

**Key differences from `updateNotifier`:**

| | `updateNotifier` | `likeWhenNotifier` |
|:--|:--|:--|
| Toasts | Auto-managed, toggleable | None |
| Haptics | Auto by state | None |
| `refreshing` / `SWR` callback | Fires `onSuccess` | Silent (skipped) |
| Use case | Primary actions | Analytics, navigation, custom UI |

---

## Encrypted Image Cache

### Per-Device AES-256 Encryption

`AppCacheSecurity` generates a cryptographically random 32-byte key on first install and persists it in `SharedPreferences`. A fresh random 16-byte IV is generated **per file** at write time:

```
[16-byte IV] + [AES-CBC ciphertext]
```

Every cached image is independently decryptable. Supply your own key via `LikeConfig.encryptionKey` — LIKE derives a stable 32-byte key from it using SHA-256.

### `LikeCacheImage`

Drop-in widget that strips query tokens for consistent cache hits.

```dart
LikeCacheImage(
  imageUrl:    'https://example.com/avatar.png?token=xyz',
  fit:          BoxFit.cover,
  width:        100,
  height:       100,
  placeholder:  (ctx, url) => const ShimmerLoader(),
  errorWidget:  (ctx, url, err) => const Icon(Icons.broken_image),
);
```

### LRU Pruning Defaults

| Config | Default | Description |
|:--|:--|:--|
| `maxImageCacheMB` | `500.0 MB` | Pruning triggered above this |
| `minImageCacheMB` | `400.0 MB` | Pruning target floor |
| `imageStalePeriod` | `90 days` | Retention threshold |
| `maxImageCacheItems` | `5 000` | Max unique cached images |

---

## Network Mocking System

A persistent, Hive-backed mocking engine for intercepting API calls in dev / staging — no separate mock server needed.

```dart
final mockCtrl = MockController();
await mockCtrl.init();

await mockCtrl.addRule(
  MockRule(
    id:           'mock_profile',
    name:         'Get User Profile',
    pathPattern:  '/users/profile',
    method:       'GET',
    statusCode:   200,
    responseBody: jsonEncode({'status': 200, 'data': {'id': '1', 'name': 'Jane'}}),
  ),
);

await mockCtrl.setEngineEnabled(true);
```

Rules persist across restarts and can be toggled at runtime, making it safe to ship mock data in staging builds without any conditional compilation.

---

## Customizing Response Unpacking

Tell LIKE how your API envelope is structured:

```dart
LikeConfig(
  unpacker: const DefaultLikeUnpacker(
    dataKey:    'data',    // Where the payload lives
    messageKey: 'message', // Error / success message key
    statusKey:  'status',  // Business status-code key
  ),
)
```

> [!IMPORTANT]
> Without `unpacker`, LIKE cannot extract `message` or `status` from custom envelopes, which results in generic "Unknown Error" states.

Custom envelopes (e.g. nested `result.body.payload`) can be handled by implementing the `LikeUnpacker` interface.

---

## Offline Sync Queue

All `POST` / `PUT` / `DELETE` mutations are persisted in a Hive box when the network is unavailable and auto-replayed in chronological order on reconnect.

**Auth-aware replay (v1.2.0+):** Before replaying each queued request, a fresh auth token is fetched via `LikeAuthInterceptor.getToken`. This prevents 401 errors for long-lived offline sessions (tokens typically live 15–60 min).

> [!NOTE]
> `workmanager` is no longer a dependency. Sync is driven entirely by `LikeConnectivityManager` reacting to foreground connectivity changes — making LIKE fully platform-agnostic: Android, iOS, Web, macOS, Windows, Linux.

---

## Zero-Config Pipeline Synchronization

1. A successful `GET` inside `fetch()` binds the endpoint path + query to `LikeNotifierState` via Zone injection.
2. Any write (`POST` / `PUT` / `DELETE`) on that endpoint broadcasts a `LikePipeline` event.
3. Path + query overlap is verified — if matched, every screen observing that state updates instantly.
4. An in-flight race guard suppresses duplicate updates while the state is actively loading or refreshing.

---

## Logging

`LikeLoggerInterceptor` prints structured request/response details — query parameters, headers, and multipart form data — to the developer console. Sensitive headers (e.g. `Authorization`) are masked automatically.

---

## Connect & Contribute

| | |
|:--|:--|
| 📦 **pub.dev** | [pub.dev/packages/like](https://pub.dev/packages/like) |
| 📖 **Docs / Wiki** | [github.com/AjayJasperJ/like_docs](https://github.com/AjayJasperJ/like_docs) |
| 🐛 **Issues** | [github.com/AjayJasperJ/like_docs/issues](https://github.com/AjayJasperJ/like_docs/issues) |
| 💻 **GitHub** | [@AjayJasperJ](https://github.com/AjayJasperJ) |
| 💼 **LinkedIn** | [Ajay Jasper J](https://in.linkedin.com/in/ajay-jasper-j-8563852b4) |
| 📸 **Instagram** | [@ajayjasper.j](https://www.instagram.com/ajayjasper.j) |
| ✉️ **Email** | [ajayjasperj@outlook.com](mailto:ajayjasperj@outlook.com) |

### Contributing

Bug reports, pull requests, and feature discussions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. This project follows standard Dart/Flutter conventions and is covered by a suite of unit tests in `test/`.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/AjayJasperJ">Ajay Jasper J</a> · MIT License
</p>
