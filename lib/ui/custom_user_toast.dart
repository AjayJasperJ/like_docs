import 'package:flutter/material.dart';
import 'package:like/like.dart';

/// **CustomUserToastWidget**
/// 
/// A beautiful, modern, and highly custom toast UI designed to follow
/// a clean, premium visual aesthetic (vibrant colors, glassmorphism, subtle shadows).
/// 
/// Since it lives inside a [Material] overlay, it should always contain
/// its own [Material] widget with transparent background to prevent text styling inheritance issues.
class CustomUserToastWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const CustomUserToastWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          // Subtle colored border for high visual premium contrast
          border: Border.all(color: iconColor.withAlpha(40), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored circular background wrapper for the icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **CustomUserToastExtension**
/// 
/// This extension attaches custom toast methods directly onto the [LikeToastType] enum.
/// 
/// ### Why this is contextless:
/// Under the hood, the root [Like] wrapper registers the global context on startup.
/// Calling `LikeToastManager.showCustomToast()` retrieves that registered context automatically,
/// enabling you to trigger a bespoke overlay from anywhere in your codebase (Repositories,
/// Providers, Services, or pure business logic blocks) without carrying a `BuildContext` parameter.
/// 
/// ### Usage Example:
/// ```dart
/// import 'package:like_docs/ui/custom_user_toast.dart';
/// 
/// // Trigger a custom toast contextlessly:
/// LikeToastType.info.showBespoke(
///   title: "Sync Completed",
///   description: "All database changes synchronized.",
///   icon: Icons.sync_rounded,
///   iconColor: Colors.teal,
///   backgroundColor: const Color(0xFFE8F5E9),
/// );
/// ```
extension CustomUserToastExtension on LikeToastType {
  /// Displays a custom bespoke toast widget contextlessly.
  void showBespoke({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    LikeToastManager.showCustomToast(
      child: CustomUserToastWidget(
        title: title,
        description: description,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
      ),
      alignment: Alignment.bottomCenter,
      animationType: LikeToastAnimation.fade,
      autoCloseDuration: autoCloseDuration,
    );
  }
}

