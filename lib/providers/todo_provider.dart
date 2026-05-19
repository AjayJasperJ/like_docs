import 'package:flutter/foundation.dart';
import 'package:like/like.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../repositories/todo_repository.dart';

class TodoProvider with ChangeNotifier, LikeAutoReconnectMixin {
  final TodoRepository _todoRepository;

  // Zero-boilerplate constructor!
  // No initAutoReconnect() or manual lifecycle subscriptions needed.
  TodoProvider(this._todoRepository);

  /// Managed state holding the dynamic UI data.
  final todosState = LikeNotifierState<List<TodoModel>>();

  /// Managed state holding selected user details.
  final userDetailState = LikeNotifierState<UserModel>();

  /// Managed state holding the creation status of a new Todo.
  final createTodoState = LikeNotifierState<TodoModel>();

  /// Safe state getter consumed by the UI.
  LikeStateResponse<List<TodoModel>> get todosResponse => todosState.value;

  /// Safe state getter for user details.
  LikeStateResponse<UserModel> get userDetailResponse => userDetailState.value;

  /// Safe state getter for create todo status.
  LikeStateResponse<TodoModel> get createTodoResponse => createTodoState.value;

  /// Fetches Todos with full SWR, offline synchronization, and reachability recovery.
  Future<LikeStateResponse<List<TodoModel>>> getTodoList({ARS? ars}) async {
    return fetch<List<TodoModel>>(
      state: todosState,
      ars: ars,
      autoResync:
          true, // Automatically registers and syncs once connection returns!
      priority: LikeSyncPriority.normal,
      action: (ct, actionArs) async {
        final result = await _todoRepository.getTodos(ars: actionArs);
        return result.toStateResponse();
      },
    );
  }

  /// Fetches User details with reachability recovery and SWR caching.
  Future<LikeStateResponse<UserModel>> getUserDetail(int id, {ARS? ars}) async {
    return fetch<UserModel>(
      state: userDetailState,
      ars: ars,
      autoResync: true,
      priority: LikeSyncPriority.normal,
      action: (ct, actionArs) async {
        final result = await _todoRepository.getUser(id, ars: actionArs);
        return result.toStateResponse();
      },
    );
  }

  /// Creates a new todo and prepends it to the list of todos if successful.
  Future<LikeStateResponse<TodoModel>> addTodo(String title, {ARS? ars}) async {
    return fetch<TodoModel>(
      state: createTodoState,
      ars: ars,
      autoResync: false,
      priority: LikeSyncPriority.critical,
      action: (ct, actionArs) async {
        final result = await _todoRepository.createTodo(title, ars: actionArs);
        if (result.isSuccess && result.data != null) {
          final currentTodos = todosState.value.data ?? [];
          final newTodoList = [result.data!, ...currentTodos];
          todosState.value = LikeStateResponse<List<TodoModel>>.success(
            newTodoList,
          );
          notifyListeners();
        }
        return result.toStateResponse();
      },
    );
  }
}
