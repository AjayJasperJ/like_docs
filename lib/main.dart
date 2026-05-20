import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:like_devtool/like_devtool.dart';
import 'package:like_docs/utils/auth_hooks.dart';
import 'package:provider/provider.dart';
import 'services/todo_service.dart';
import 'repositories/todo_repository.dart';
import 'providers/todo_provider.dart';
import 'ui/todo_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: Manually initialize the LIKE service early at startup.
  // This initializes Hive, configures app-level secure device encryption,
  // opens the L2 database boxes (API cache, Etags, Offline queue), and starts tracking.
  // Note: The root 'Like' widget wrapper will automatically perform this 
  // setup if not already initialized, making this manual startup call optional.
  await LikeService.init(config: LikeConfig());
  runApp(const LikeExampleApp());

}

class LikeExampleApp extends StatelessWidget {
  const LikeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Instantiate the generic network layer services and repositories
    final todoService = TodoService();
    final todoRepository = TodoRepository(todoService);

    return MultiProvider(
      providers: [
        // 2. Register the provider using standard ChangeNotifierProvider
        ChangeNotifierProvider(create: (_) => TodoProvider(todoRepository)),
      ],
      // 3. Wrap your root app in the 'Like' widget to initialize the engine.
      // This configures connectivity tracking, local L2 cache databases,
      // and optional security token rotation pipelines globally.
      child: Like(
        baseUrl: 'https://jsonplaceholder.typicode.com',

        // 4. Inject the Developer Tool Overlay dashboard in Debug Mode.
        // It compiles to a zero-overhead No-Op wrapper widget in production builds.
        devTool: (child) => LikeDevTool(child: child),

        // 5. Wire up authenticating interceptor hook delegates.
        // These callbacks are executed automatically by the LIKE client interceptors:

        // Resolves the current JWT access token dynamically to append to requests.
        getToken: AuthHooks.getToken,

        // Triggers silently to request a new access token if a 401 occurs in-flight.
        refreshToken: AuthHooks.refreshToken,

        // Clean-up hook triggered if silent refresh fails or the session expires completely.
        onLogout: AuthHooks.onLogout,

        // 6. Connectivity toast configuration.
        // When true (default), the engine shows toasts automatically on network changes.
        // Set to false to disable all built-in connectivity toasts entirely.
        showConnectivityToasts: true,

        // 7. (Optional) Override the default connectivity toast widgets.
        // By default LIKE shows a flat 'Back Online' / 'No Connection' toast.
        // Pass custom widgets here to replace them with your own branded UI.
        //
        // toastConfig: LikeToastConfig(
        //   online: _OnlineBanner(),    // ← shown when internet restores
        //   offline: _OfflineBanner(),  // ← shown when internet drops
        // ),


        child: MaterialApp(
          title: 'LIKE Zero-Config Demo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
          ),
          home: const TodoListScreen(),
        ),
      ),
    );
  }
}
