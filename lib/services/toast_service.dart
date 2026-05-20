import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:toastification/toastification.dart';

// =============================================================================
// LIKE TOAST SERVICE — Reference & Customization Guide
// =============================================================================
//
// LIKE ships a fully integrated, context-free toast system via [LikeToastManager].
//
// The root [Like] widget registers a global context automatically, so you can
// fire toasts from anywhere — providers, repositories, use-cases, callbacks —
// without needing to pass a BuildContext.
//
// ─── HOW TO USE (zero setup) ─────────────────────────────────────────────────
//
//   LikeToastManager.showToast(
//     message: 'Saved!',
//     type: ToastificationType.success,
//   );
//
//   LikeToastManager.showResponseToast(response);   // auto-derives type
//   LikeToastManager.showLoadingToast(title: 'Uploading...');
//   LikeToastManager.dismiss();
//
//   LikeToastManager.showCustomToast(
//     child: MyCustomBannerWidget(),
//     animationType: LikeToastAnimation.scale,
//     alignment: Alignment.bottomCenter,
//   );
//
// ─── CONNECTIVITY TOASTS (auto-managed) ──────────────────────────────────────
//
// The root [Like] widget fires connectivity toasts automatically.
// You can override the default widgets via [LikeToastConfig]:
//
//   Like(
//     toastConfig: LikeToastConfig(
//       online: _OnlineBanner(),
//       offline: _OfflineBanner(),
//     ),
//     child: MyApp(),
//   )
//
// Or disable them entirely:
//   Like(showConnectivityToasts: false, child: MyApp())
//
// ─── GLOBAL SHORTHAND ────────────────────────────────────────────────────────
//
// Like also exposes a global [LikeToast] const accessor you can extend with
// your own app-specific toast shortcuts using Dart extensions:
//
//   LikeToast.online();   // manually fires the online connectivity toast
//   LikeToast.offline();  // manually fires the offline connectivity toast
//
// =============================================================================

// =============================================================================
// CUSTOMIZATION: Custom Delegate
// =============================================================================
//
// To completely replace the default toast UI, implement [LikeToastDelegate]
// and register it on the root [Like] widget via [LikeToastConfig]:
//
//   Like(
//     toastDelegate: AppToastDelegate(),
//     child: MyApp(),
//   )
//
// Or register it imperatively at any time:
//   LikeToastManager.setDelegate(AppToastDelegate());

/// Example custom delegate — replace the default LIKE toasts with your own UI.
class AppToastDelegate extends DefaultLikeToastDelegate {
  // Override only what you need. DefaultLikeToastDelegate handles the rest.

  @override
  void showConnectivityToast(BuildContext context, bool isOnline) {
    // Replace the default flat toast with a branded banner.
    showCustomToast(
      context,
      alignment: Alignment.topCenter,
      animationType: LikeToastAnimation.slide,
      autoCloseDuration: const Duration(seconds: 3),
      child: _ConnectivityBanner(isOnline: isOnline),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  const _ConnectivityBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            isOnline ? 'Back Online' : 'No Connection',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOMIZATION: Extending LikeToastType
// =============================================================================
//
// Add your own app-specific toast shortcuts as extensions on [LikeToastType].
// Access them via the global [LikeToast] const.
//
//   LikeToast.saved();
//   LikeToast.deleted();
//   LikeToast.networkError();

extension AppToasts on LikeToastType {
  /// Shows a 'Changes Saved' success toast.
  void saved([String? detail]) {
    LikeToastManager.showToast(
      message: 'Changes Saved',
      submessage: detail,
      type: ToastificationType.success,
    );
  }

  /// Shows an 'Item Deleted' warning toast.
  void deleted([String? detail]) {
    LikeToastManager.showToast(
      message: 'Item Deleted',
      submessage: detail,
      type: ToastificationType.warning,
    );
  }

  /// Shows a generic network error toast.
  void networkError([String? detail]) {
    LikeToastManager.showToast(
      message: 'Network Error',
      submessage: detail ?? 'Please try again.',
      type: ToastificationType.error,
    );
  }
}

// =============================================================================
// USAGE EXAMPLES (call from anywhere — no context needed)
// =============================================================================
//
//   LikeToastManager.showToast(message: 'Done!', type: ToastificationType.success);
//   LikeToastManager.showResponseToast(myStateResponse);
//   LikeToastManager.showLoadingToast(title: 'Syncing...', message: 'Please wait');
//   LikeToastManager.dismiss();
//
//   LikeToast.saved();
//   LikeToast.deleted('Todo #5 removed');
//   LikeToast.networkError();
//   LikeToast.online();
//   LikeToast.offline();
