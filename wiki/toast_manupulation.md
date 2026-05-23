# LIKE Toast System Guide

The `like` package provides a centralized, decoupled toast management system. It allows you to trigger notifications from anywhere in your code (Services, Providers, or UI) without passing a `BuildContext`, while keeping the UI implementation 100% customizable.

---

## 1. The Context-less Architecture

The most powerful feature of this system is that it is **Context-less**. You can call `LikeToast.online()` inside a pure Dart service or a background task without having a `BuildContext` reference.

### How it works:
1.  The `Like` root widget (at the top of your app) automatically registers the `BuildContext` into the `LikeToastManager`.
2.  All methods inside `LikeToast` and `LikeToastManager` use this internal reference.
3.  **Benefit**: You decouple your business logic (Networking/Auth) from your UI layer.

---

## 2. Global Accessor: `LikeToast`

`LikeToast` is the primary syntax-sugar accessor.

```dart
// Call these anywhere:
LikeToast.online();
LikeToast.offline();
```

---

## 3. Replacing the Toast Engine (Adding a New Package)

If you want to use a different toast library (e.g., `bot_toast`, `cherry_toast`, or your own custom system) instead of the default implementation, follow these steps:

### Step 1: Create a Custom Delegate
Implement the `LikeToastDelegate` interface. This maps the package's logical actions (like "show connectivity toast") to your specific library's implementation.

```dart
import 'package:like/like.dart';

class MyThirdPartyDelegate implements LikeToastDelegate {
  @override
  void showConnectivityToast(BuildContext context, bool isOnline) {
    // Replace this with your package's logic
    SomeOtherToastPackage.show(
      title: isOnline ? "Connected" : "Disconnected",
      color: isOnline ? Colors.green : Colors.red,
    );
  }

  @override
  void showToast(BuildContext context, {required String message, String? submessage, ToastificationType type = ToastificationType.info}) {
     // Map your generic toasts here
  }

  // ... Implement other required methods (showResponseToast, etc.)
}
```

### Step 2: Register the Delegate
Pass your new delegate to the `Like` root widget. Once registered, all calls to `LikeToast` will automatically use your new engine.

```dart
Like(
  toastDelegate: MyThirdPartyDelegate(),
  child: const MyApp(),
)
```

---

## 4. Developing Customized Context-less Toasts

To develop your own bespoke toast system from scratch that remains context-less, follow this pattern:

### Step 1: Define the UI
Create a standard Flutter widget for your toast.

```dart
class MyBespokeToast extends StatelessWidget {
  final String title;
  const MyBespokeToast({required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
        child: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
```

### Step 2: Add it to the Registry (Extensions)
Use `LikeToastManager.showCustomToast` to show your widget without needing a context. This method handles the overlay insertion for you.

```dart
extension MyAppToasts on LikeToastType {
  void showBespoke(String text) {
    LikeToastManager.showCustomToast(
      child: MyBespokeToast(title: text),
      alignment: Alignment.bottomCenter,
      animationType: LikeToastAnimation.fade,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}

// Usage anywhere in your app:
LikeToast.showBespoke("Hello World!");
```

---

## 5. Summary Table: Customization Levels

| Level | Goal | Implementation |
| :--- | :--- | :--- |
| **Level 1** | Change UI of specific toasts | Set `onlineWidget` / `offlineWidget` in `LikeToastConfig`. |
| **Level 2** | Change logic of actions | Set `onOnline` / `onOffline` callbacks in `LikeToastManager`. |
| **Level 3** | Add brand new toast types | Create an `extension on LikeToastType` using `showCustomToast`. |
| **Level 4** | Swap the whole library | Create a custom `LikeToastDelegate` and pass it to `Like()`. |

---

## 6. Configuration Reference

### `LikeToastConfig` (UI Registry)
- `online`: Custom widget for online status.
- `offline`: Custom widget for offline status.

### `LikeToastManager` (Global Controls)
- `onOnline`: Logic override for `LikeToast.online()`.
- `onOffline`: Logic override for `LikeToast.offline()`.
- `showCustomToast()`: The engine that powers context-less custom UI.
- `setDelegate()`: Swaps the underlying toast engine.
