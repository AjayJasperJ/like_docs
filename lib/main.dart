import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:provider/provider.dart';
import 'services/todo_service.dart';
import 'repositories/todo_repository.dart';
import 'providers/todo_provider.dart';
import 'ui/todo_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      // 3. Wrap your root app in the 'Like' widget to initialize the engine
      child: Like(
        baseUrl: 'https://jsonplaceholder.typicode.com',
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
