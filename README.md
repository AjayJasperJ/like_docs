<p align="center">
  <img src="https://raw.githubusercontent.com/AjayJasperJ/like_docs/refs/heads/main/assets/banner.png" alt="LIKE — Link Intelligent Kernel Engine" width="100%"/>
</p>

<h1 align="center">LIKE Reference & Documentation App</h1>

<p align="center">
  <strong>The official interactive showcase and reference wiki for LIKE (Link Intelligent Kernel Engine) — demonstrating offline-first caching, reactive state sync, and premium UI bindings.</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/platform-Flutter-02569B?logo=flutter&style=flat-square" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/language-Dart-0175C2?logo=dart&style=flat-square" alt="Dart"/></a>
  <a href="wiki/contribution.md"><img src="https://img.shields.io/badge/contribution-welcome-brightgreen?style=flat-square" alt="Contributions Welcome"/></a>
  <a href="https://github.com/AjayJasperJ/like_docs/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License"/></a>
</p>

---

## 📖 Welcome to `like_docs`

This repository serves as the definitive reference suite for the **LIKE Framework**. It is split into two parts:

1. **Epicurean — Showcase Application**: A beautifully designed, high-performance Material 3 recipe explorer application. It demonstrates in-flight request deduplication, L1/L2 disk caching, auto-reconnection synchronization, AES-256 encrypted media storage, and contextual status management.
2. **Deep-Dive Architectural Wiki**: A complete set of technical guides inside `/wiki` explaining package design, auth interception pipelines, toast manipulation, and custom builders.

---

## 🚀 Epicurean App Features

The showcase app **Epicurean** (`https://www.themealdb.com` integration) demonstrates how simple it is to build premium, production-ready interfaces with **LIKE**:

*   🎨 **Modern Material 3 UI & Aesthetics**: Built using highly customized dark/light cards, premium typographies, and sleek category selectors.
*   ⚡ **Offline-First SWR Caching**: View cached recipes instantly on launch. The engine revalidates data in the background and silent-swipes to refresh when the network returns.
*   🔒 **AES-256 Encrypted Media Cache**: Utilizes the custom `LikeCacheImage` widget to decrypt image resources on-the-fly using a secure 256-bit key generated per device.
*   📡 **Live Reconnect Sync & Toasts**: Automatically displays custom animated connectivity toasts when the system shifts online/offline and instantly catches up on pending requests.
*   🛠️ **DevTool Integration**: Plugs into the `LikeDevTool` debugger to inspect API traffic, active mocks, caching databases, and in-flight processes at runtime.

---

## 📂 Repository Tour

Navigating the codebase is straightforward:

```yaml
like_docs/
├── lib/                     # Epicurean Application Code
│   ├── main.dart            # Framework bootstrap & init
│   ├── like_app.dart        # Core Like() configuration & interceptors
│   ├── app.dart             # Provider trees, app theme, & routing
│   ├── models/              # Immutable JSON-serializable structures
│   ├── services/            # API call-sites returning LikeApiResult<T>
│   ├── repositories/        # Core business operations and endpoint routing
│   ├── providers/           # State management with LikeNotifierState
│   ├── ui/                  # Sleek screen layouts and customized toast controls
│   └── utils/               # Secure token and authentication routines
│
├── wiki/                    # Complete Architecture Deep-Dives
│   ├── README.md            # Master LIKE Framework specs & API capabilities
│   ├── README_devtool.md    # DevTools debugger setup & mocking tutorial
│   ├── api_flow_...md       # Standardizing Service-Repository patterns
│   ├── auth_token_...md     # Bearer interceptors & automatic refresh pipelines
│   ├── provider_...md       # Managing multi-screen states with mixed auto-resync
│   ├── reactive_...md       # Detailed guide on builders, slivers, and selectors
│   ├── toast_manup...md     # Custom contextless toasts & sync indicators
│   └── contribution.md      # Testing conventions & PR rules
```

---

## 🏗️ Architectural Flow: From Service to UI

**LIKE** enforces a clean, modular structure. Below is a code walkthrough detailing the implementation pattern of the **Epicurean** Recipe application:

### 1. Root Configuration (`like_app.dart`)
Initialize the engine once at the app root to handle base URLs, secure tokens, custom toast configurations, and the DevTool.

```dart
class LikeApp extends StatelessWidget {
  final Widget child;
  const LikeApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Like(
      baseUrl: 'https://www.themealdb.com',
      devTool: (child) => LikeDevTool(child: child),
      getToken: AuthHooks.getToken,
      refreshToken: AuthHooks.refreshToken,
      showConnectivityToasts: true,
      toastConfig: LikeToastConfig(
        online: const CustomConnectionToast(
          message: 'Connected — Live updates synchronized',
          icon: Icons.wifi_rounded,
          iconColor: Colors.teal,
          backgroundColor: Color(0xFFE8F5E9),
        ),
        offline: const CustomConnectionToast(
          message: 'No Connection — Local cache mode active',
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.orange,
          backgroundColor: Color(0xFFFFF3E0),
        ),
      ),
      child: child,
    );
  }
}
```

### 2. Service Layer (`meal_service.dart`)
Services return pure data wrappers (`LikeApiResult<T>`) isolated from any state logic or UI components.

```dart
class MealService {
  Future<LikeApiResult<List<MealModel>>> searchMeals(String query, {CancelToken? ct}) async {
    return LikeClient()
        .get('/api/json/v1/1/search.php', queryParameters: {'s': query}, ct: ct)
        .mapAsync((json) => mealListMapper(json));
  }
}
```

### 3. State Management (`meal_provider.dart`)
Combine your repositories and trigger reactive state transitions utilizing zero-boilerplate `LikeNotifierState`.

```dart
class MealProvider with ChangeNotifier, LikeAutoReconnectMixin {
  final MealRepository _mealRepository;
  MealProvider(this._mealRepository);

  /// Reactive state holding user search results
  final searchState = LikeNotifierState<List<MealModel>>(
    mapper: (json) => mealListMapper(json), // Auto-syncs across widgets
  );

  LikeStateResponse<List<MealModel>> get searchResponse => searchState.value;

  /// Fetches meals with pull-to-refresh support and SWR revalidation
  Future<LikeStateResponse<List<MealModel>>> searchMeals(String query, {ARS? ars}) async {
    return fetch<List<MealModel>>(
      state: searchState,
      ars: ars,
      autoResync: true,
      action: (ct, actionArs) async {
        final result = await _mealRepository.searchMeals(query, ars: actionArs);
        return result.toStateResponse();
      },
    );
  }
}
```

### 4. Reactive UI Binding (`meal_screen.dart`)
Subscribe directly to state changes and configure visual states (loading, refreshing, success, error) easily. Keep sticky cached data visible while loading fresh background updates.

```dart
LikeBuilder<List<MealModel>>(
  observe: () => mealProvider.searchResponse,
  onSuccess: (meals, isRefreshing, isFromSWR) {
    return Stack(
      children: [
        RefreshIndicator(
          color: Colors.amber,
          onRefresh: () => mealProvider.searchMeals(_query, ars: ARS(refresh: true)),
          child: ListView.builder(
            itemCount: meals.length,
            itemBuilder: (ctx, i) => MealCard(meal: meals[i]),
          ),
        ),
        if (isRefreshing)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(color: Colors.amber),
          ),
      ],
    );
  },
  onLoading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
  onError: (error) => Center(child: Text('Error: ${error.message}')),
)
```

---

## 📚 Reference Wiki Index

For detailed guidelines and enterprise implementation standards, click through to the specific documentation:

| Guide | Description | Key Focus Area |
| :--- | :--- | :--- |
| [📘 **Core API Guide**](wiki/README.md) | Standard implementation rules for the entire package. | L1/L2 Caching, ETag handling, offline queue replays. |
| [🛠️ **DevTool Suite**](wiki/README_devtool.md) | How to inspect state data and mock network calls. | Trait logging, active rules, offline-safe mock payloads. |
| [⛓️ **API Flow Design**](wiki/api_flow_implementation.md) | Standardizing data flow from Service to UI. | Result mappings, network boundary rules, exception bounds. |
| [🔑 **Authentication**](wiki/auth_token_manupulation.md) | Handling tokens and refreshing tokens safely. | Auto-retry interceptors, session invalidation triggers. |
| [🔄 **Provider Design**](wiki/provider_architecture.md) | State management and multi-notifier sync rules. | `LikeNotifierState`, connection handlers, auto-dispose. |
| [🎨 **Reactive UI Widgets**](wiki/reactive_widgets.md) | Binding data to widgets without rendering bugs. | `LikeBuilder`, selector, sliver variants, multiple dependencies. |
| [🔔 **Custom Toasts**](wiki/toast_manupulation.md) | Displaying contextless bespoke alerts. | Toast overlays, progress builders, connection alerts. |

---

## 🛠️ Getting Started Locally

Follow these quick commands to install and test the Epicurean reference application:

```bash
# 1. Clone the repository and navigate to the folder
cd packages/like_docs

# 2. Get dependencies
flutter pub get

# 3. Run the application
flutter run
```

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/AjayJasperJ">AjayJasperJ</a> · MIT License
</p>
