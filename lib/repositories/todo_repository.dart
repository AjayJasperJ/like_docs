import 'package:like/like.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../services/todo_service.dart';

List<TodoModel> todoListMapper(dynamic json) {
  final list = json as List<dynamic>;
  return list
      .map((item) => TodoModel.fromJson(item as Map<String, dynamic>))
      .toList();
}

UserModel userMapper(dynamic json) {
  return UserModel.fromJson(json as Map<String, dynamic>);
}

TodoModel todoMapper(dynamic json) {
  return TodoModel.fromJson(json as Map<String, dynamic>);
}

class TodoRepository {
  final TodoService _todoService;

  TodoRepository(this._todoService);

  /// Fetches raw response from the service and maps it to strongly-typed models inside a background isolate.
  Future<LikeApiResult<List<TodoModel>>> getTodos({ARS? ars}) async {
    return _todoService.fetchTodos(ars: ars).mapAsync(todoListMapper);
  }

  /// Fetches raw user response from the service and maps it to strongly-typed UserModel inside a background isolate.
  Future<LikeApiResult<UserModel>> getUser(int id, {ARS? ars}) async {
    return _todoService.fetchUser(id, ars: ars).mapAsync(userMapper);
  }

  /// Creates a new todo item and maps the response to a TodoModel inside a background isolate.
  Future<LikeApiResult<TodoModel>> createTodo(String title, {ARS? ars}) async {
    final data = {'title': title, 'completed': false, 'userId': 1};
    return _todoService.createTodo(data).mapAsync(todoMapper);
  }
}
