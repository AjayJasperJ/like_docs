import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import 'todo_details_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data after the initial build frame.
    // likeWhenNotifier is the "empty" handler — pure state mapping, no auto-toasts.
    // Use it when you want full manual control over side-effects.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final response = await context.read<TodoProvider>().getTodoList();
      await likeWhenNotifier<List<TodoModel>>(
        response: response,
        // Called when the first successful data lands (fresh or SWR).
        onSuccess: (todos) async {
          debugPrint('[likeWhenNotifier] Loaded ${todos.length} todos.');
        },
        // Called on a typed API error (e.g., 4xx / 5xx).
        onError: (error) async {
          debugPrint('[likeWhenNotifier] Error: ${error.message}');
        },
        // Called on an unexpected exception (e.g., no internet, parse failure).
        onException: (message) async {
          debugPrint('[likeWhenNotifier] Exception: $message');
        },
      );
    });
  }

  void _showAddTodoDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter task title...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(dialogContext); // Close dialog

                final todoProvider = context.read<TodoProvider>();
                final response = await todoProvider.addTodo(title);

                if (context.mounted) {
                  // updateNotifier is the "full" handler — built-in toasts, haptics,
                  // and per-state callbacks all handled automatically.
                  //
                  // Flags:
                  //   disableSuccessToast  → show/hide auto-toast on success (default: disabled)
                  //   disableErrorToast    → show/hide auto-toast on error   (default: disabled)
                  //   disableExceptionToast→ show/hide auto-toast on exception (default: disabled)
                  //   enableHaptics        → fires HapticFeedback on success/error/exception
                  //   messageOverrides     → override the toast message per state
                  await updateNotifier<TodoModel>(
                    response: response,
                    context: context,
                    disableSuccessToast: false, // auto-toast on success
                    disableErrorToast: false,   // auto-toast on error
                    enableHaptics: true,        // vibrate on feedback
                    messageOverrides: {
                      LikeState.success: 'Task "$title" created successfully!',
                      LikeState.error: 'Failed to create "$title". Try again.',
                    },
                    onSuccess: (todo) async {
                      // Optional: additional logic after success (e.g. navigation, analytics).
                      debugPrint('[updateNotifier] Created todo #${todo.id}');
                    },
                    onError: (error) async {
                      // Optional: handle typed error (e.g., show a dialog).
                      debugPrint('[updateNotifier] Error: ${error.message}');
                    },
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIKE Zero-Config Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => todoProvider.getTodoList(),
          ),
        ],
      ),
      body: LikeBuilder<List<TodoModel>>(
        // 1. Observe the reactive state getter exposed by our Provider
        observe: () => todoProvider.todosResponse,

        // 2. Handle data success (including SWR and live refreshing indicators)
        onSuccess: (todos, isRefreshing, isFromSWR) {
          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => todoProvider.getTodoList(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodoDetailsScreen(todo: todo),
                          ),
                        );
                      },
                      leading: Icon(
                        todo.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: todo.completed ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.completed ? Colors.grey : Colors.black,
                        ),
                      ),
                      trailing: isFromSWR
                          ? const Icon(Icons.history, color: Colors.orange)
                          : const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                    );
                  },
                ),
              ),
              if (isRefreshing)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },

        // 3. Handle initial loading state
        onLoading: () => const Center(child: CircularProgressIndicator()),

        // 4. Handle offline & network error states elegantly
        onError: (error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  error.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The screen will automatically resynchronize the moment your internet connection is restored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => todoProvider.getTodoList(),
                  icon: const Icon(Icons.sync),
                  label: const Text('Try Reconnecting Now'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
