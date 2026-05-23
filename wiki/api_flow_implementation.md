# Clean Architecture Roadmap with LIKE 🗺️

This guide outlines the 4-tier architecture recommended for building robust, scalable applications using the `like` networking ecosystem.

---

## 🏛️ The 4-Tier Architecture

| Layer               | File                   | Purpose                                                       |
| :------------------ | :--------------------- | :------------------------------------------------------------ |
| **1. Service**      | `user_service.dart`    | Low-level API calls returning `LikeApiResult<Response>`.      |
| **2. Repository**   | `user_repository.dart` | Data orchestration and **Background Parsing** via `mapAsync`. |
| **3. Provider**     | `user_provider.dart`   | State management (Manual or Automated via Mixin).             |
| **4. Presentation** | `user_screen.dart`     | Reactive UI using `LikeBuilder`.                              |

---

## 🏗️ Step 1: Service Layer (`service.dart`)
The service layer is a thin wrapper around `LikeClient`. It returns `LikeApiResult<Response>`.

```dart
class UserService {
  final _client = LikeClient();

  Future<LikeApiResult<Response>> fetchUsers({
    Map<String, dynamic>? query,
    ARS? ars,
    CancelToken? cancelToken,
  }) async {
    return await _client.get('/users', query: query, ars: ars, cancelToken: cancelToken);
  }
}
```

---

## 📦 Step 2: Repository Layer (`repository.dart`)
The repository transforms raw API results into domain models.
**Constraint**: Every `get` method must accept an optional `{ARS? ars}` and return `Future<LikeApiResult<T>>`.

```dart
class UserRepository {
  final _service = UserService();

  Future<LikeApiResult<User>> getUser(String id, {ARS? ars, CancelToken? cancelToken}) async {
    return await _service.fetchUserDetail(id, ars: ars, cancelToken: cancelToken)
        .mapAsync(User.fromJson);
  }
}
```

---

## 🧪 Step 3: Provider Layer (`provider.dart`)
The provider holds the state. It usually requires two variables per API call: a `LikeStateResponse<T>` and a `CancelToken?`.

### Option A: Manual Implementation (Expanded)
Use this when you need custom logic before or after the API call (e.g., specific validation).

```dart
class UserProvider extends ChangeNotifier with LikeAutoReconnectMixin {
  final _repository = UserRepository();
  
  // 1. State Variables
  LikeStateResponse<User> _userDetail = LikeStateResponse.idle();
  LikeStateResponse<User> get userDetail => _userDetail;
  CancelToken? _userCT;

  Future<LikeStateResponse<User>> loadUser(String? id, {ARS? ars}) async {
    ars ??= const ARS();
    
    // 2. Resource Management: Cancel old and create new token
    _userCT = newCT(_userCT); 

    // 3. Initial State: Only show loading if not a background refresh
    if (!ars.refresh) {
      _userDetail = LikeStateResponse.loading();
      notifyListeners();
    }

    // 4. Input Validation
    if (id == null) {
      _userDetail = LikeStateResponse.missingData('User ID is required');
      notifyListeners();
      return _userDetail;
    }

    // 5. Execution & Auto-State Conversion
    final result = await _repository.getUser(id, ars: ars, cancelToken: _userCT);
    _userDetail = result.toStateResponse();
    
    notifyListeners();
    return _userDetail;
  }
}
```

### Option B: Automatic Implementation (Shrinked)
Use the `fetcher` provided by `LikeAutoReconnectMixin` to eliminate 90% of the boilerplate.

```dart
class UserProvider extends ChangeNotifier with LikeAutoReconnectMixin {
  final _repository = UserRepository();

  LikeStateResponse<User> _userDetail = LikeStateResponse.idle();
  LikeStateResponse<User> get userDetail => _userDetail;
  CancelToken? _userCT;

  Future<void> loadUser(String id, {ARS? ars}) async {
    await fetcher<User>(
      ars: ars,
      ct: _userCT,
      onRotate: (next) => _userCT = next,
      onUpdate: (state) => _userDetail = state,
      action: (ct, finalArs) => _repository.getUser(id, ars: finalArs, cancelToken: ct),
    );
    // notifyListeners() is called automatically by fetcher
  }
}
```

---

## 🎨 Step 4: Presentation Layer (`presentation.dart`)
The UI handles every lifecycle state seamlessly.

```dart
LikeBuilder<User>(
  observe: () => provider.userDetail,
  onSuccess: (user, isRefreshing, isSWR) => UserDetailCard(user),
  onLoading: () => const ShimmerLoader(),
  onIdle: () => const WelcomeScreen(),
  onError: (error) => ErrorView(error),
  onException: (msg) => FatalView(msg),
)
```

---

## 🚀 Architectural Rules

1.  **Repository Return**: Always return `LikeApiResult<T>`.
2.  **Provider Return**: Always return `Future<LikeStateResponse<T>>`.
3.  **State Management**: Use `toStateResponse()` to automatically map Success/Error/Cache states.
4.  **Token Rotation**: Use `newCT()` to ensure multiple rapid clicks don't cause race conditions.
