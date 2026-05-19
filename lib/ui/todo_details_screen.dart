import 'package:flutter/material.dart';
import 'package:like/like.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../providers/todo_provider.dart';

class TodoDetailsScreen extends StatefulWidget {
  final TodoModel todo;

  const TodoDetailsScreen({super.key, required this.todo});

  @override
  State<TodoDetailsScreen> createState() => _TodoDetailsScreenState();
}

class _TodoDetailsScreenState extends State<TodoDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch assignee user detail asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Assume user ID is based on todo ID
        final userId = (widget.todo.id % 10) + 1;
        context.read<TodoProvider>().getUserDetail(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. SliverAppBar showcasing LikeCacheImage
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Task #${widget.todo.id} Details'),
              background: const LikeCacheImage(
                imageUrl: 'https://picsum.photos/800/400',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. LikeSelectorSliver - Redraws ONLY when the specific Todo's list changes
          LikeSelectorSliver<TodoProvider, List<TodoModel>>(
            selector: (provider) => provider.todosResponse,
            onSuccess: (todos, isRefreshing, isFromSWR) {
              final item = todos.firstWhere(
                (t) => t.id == widget.todo.id,
                orElse: () => widget.todo,
              );
              return [
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TASK TITLE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isRefreshing) ...[
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
          ),

          // 3. LikeMultiSliverBuilder - Combines Todo list & User detail responses in slivers
          LikeMultiSliverBuilder(
            observes: [
              () => todoProvider.todosResponse,
              () => todoProvider.userDetailResponse,
            ],
            onLoading: () => [
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
            onError: (error) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading assignee: ${error.message}'),
                ),
              ),
            ],
            onSuccess: (results, isRefreshing, isFromSWR) {
              final todos = results[0] as List<TodoModel>;
              final user = results[1] as UserModel;

              final todo = todos.firstWhere(
                (t) => t.id == widget.todo.id,
                orElse: () => widget.todo,
              );

              return [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASSIGNEE DETAIL (Sliver Multi-Builder)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: LikeCacheImage(
                                imageUrl: user.avatarUrl,
                                width: 60,
                                height: 60,
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(user.email),
                            trailing: Icon(
                              todo.completed
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: todo.completed
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  ]),
                ),
              ];
            },
          ),

          // 4. Custom card showing LikeMultiBuilder & LikeSelector & LikeBuilder (Normal Box Widgets)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COLLABORATION CONTROLS (Standard Box Widgets)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. LikeMultiBuilder - Combines state responses
                  LikeMultiBuilder(
                    observes: [
                      () => todoProvider.todosResponse,
                      () => todoProvider.userDetailResponse,
                    ],
                    onLoading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    onError: (error) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${error.message}'),
                    ),
                    onSuccess: (results, isRefreshing, isFromSWR) {
                      final todos = results[0] as List<TodoModel>;
                      final user = results[1] as UserModel;

                      final todo = todos.firstWhere(
                        (t) => t.id == widget.todo.id,
                        orElse: () => widget.todo,
                      );

                      return Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shared Workspace Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                todo.completed
                                    ? 'This task has been resolved and approved by ${user.name}.'
                                    : 'Assignee ${user.name} is currently reviewing the specifications.',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 6. LikeSelector - Selects only user profile to display
                  LikeSelector<TodoProvider, UserModel>(
                    selector: (context, provider) =>
                        provider.userDetailResponse,
                    onSuccess: (user, isRefreshing, isFromSWR) {
                      return ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Direct Contact'),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {},
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 7. LikeBuilder - Highly declarative pattern matching
                  LikeBuilder<UserModel>(
                    observe: () => todoProvider.userDetailResponse,
                    onLoading: () =>
                        const Center(child: CircularProgressIndicator()),
                    onError: (error) => Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.shade50,
                      child: Text('Error: ${error.message}'),
                    ),
                    onSuccess: (user, isRefreshing, isFromSWR) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            'Assignee Profile Verified: ${user.name}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
