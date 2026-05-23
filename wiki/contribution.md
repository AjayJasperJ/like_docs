# Contributing to LIKE 🚀

Thank you for contributing to the Link Intelligent Kernel Engine (LIKE). To maintain the high architectural standards of this package, please follow these guidelines.

## 🏗️ Design Philosophy

1.  **Context-Agnostic First**: Avoid requiring `BuildContext` for core logic. Use managers and static delegates (like `LikeToastManager`) to ensure the engine remains testable and decoupled from the UI tree.
2.  **Reactive State**: All data fetching should result in a `LikeStateResponse`. Never return raw domain models directly to the UI layer.
3.  **Resiliency**: Always assume the network is flaky. New features must consider offline behavior, caching, and retry logic.
4.  **Performance**: Use `mapAsync` for heavy JSON transformations to keep the main UI thread at 60/120 FPS.
5.  **4-Tier Separation**: Strictly separate logic into Client (Network), Service (Data Retrieval), Provider (UI State), and UI (Presentation).

## 📐 Architectural Contracts

### The Tiered Flow
- **Service Layer**: Returns `LikeApiResult<T>`.
- **Repository Layer**: Uses `mapAsync` for background parsing.
- **Provider Layer**: Converts results to `LikeStateResponse<T>` using `fetcher`.
- **UI Layer**: Consumes state via `LikeBuilder` or `LikeWhen`.

### The Gold Standard Provider
New providers must implement the following lifecycle hooks to ensure system-wide consistency:
- `initAutoReconnect()` in constructor.
- `syncWith()` for shared data endpoints.
- `onReconnect()` for internet restoration recovery.
- `super.dispose()` to cancel background sync listeners.

## 🛠️ Development Standards

### 1. Code Style
- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
- Run `dart format .` before every commit.
- Ensure `dart analyze` passes with zero warnings or hints.

### 2. Documentation
- Every public class and method **MUST** have a docstring (`///`).
- New configuration flags must be added to `LikeConfig` with a descriptive comment.
- Update `README.md` if you add a new high-level feature or widget.

### 3. Testing
- Aim for 80%+ code coverage for new features.
- Test both the "Happy Path" and "Edge Cases" (Offline, Timeout, 500 Errors).
- Place tests in the `test/` directory following the folder structure of `lib/`.

## 🚀 Workflow

1.  **Sync**: Ensure you are on the latest `main` branch.
2.  **Feature Branch**: Create a descriptive branch (e.g., `feat/add-new-interceptor`).
3.  **Build**: Implement your changes and verify with `dart analyze`.
4.  **Test**: Run `dart test` to ensure no regressions.
5.  **Review**: Submit a Pull Request with a clear description of the "What" and "Why".

---
