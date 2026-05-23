import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:like_devtool/like_devtool.dart';
import 'package:like_docs/ui/custom_toasts.dart';
import 'package:like_docs/utils/auth_hooks.dart';

class LikeApp extends StatelessWidget {
  final Widget child;
  const LikeApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Like(
      baseUrl: 'https://www.themealdb.com',
      devTool: (child) => LikeDevTool(child: child),
      getToken: AuthHooks.getToken,
      //if jwt based auth token provided by developer, it is stored and used
      refreshToken: AuthHooks.refreshToken,
      //if jwt based auth token then it execute this function to get token using refresh token
      onLogout: AuthHooks.onLogout,
      //if token validaton failed it execute this logout function
      showConnectivityToasts: true, //enable connection toasts
      toastConfig: LikeToastConfig(
        //failed api recovery toast
        syncProgressBuilder: (title, message, progress) =>
            CustomSyncProgressToast(
              title: title,
              message: message,
              progress: progress,
            ),
        online: const CustomConnectionToast(
          //online toast
          message: 'Connected — Live updates synchronized',
          icon: Icons.wifi_rounded,
          iconColor: Colors.teal,
          backgroundColor: Color(0xFFE8F5E9),
        ),
        offline: const CustomConnectionToast(
          //offline toast
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
