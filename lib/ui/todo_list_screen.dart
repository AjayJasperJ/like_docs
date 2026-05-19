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
    // Fetch data after the initial build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TodoProvider>().getTodoList();
      }
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
                  await updateNotifier<TodoModel>(
                    response: response,
                    context: context,
                    disableSuccessToast: false, // Automatically show toast!
                    messageOverrides: {
                      LikeState.success: 'Task "$title" created successfully!',
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
