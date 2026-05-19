import 'package:like/like.dart';

class TodoService {
  /// Fetches raw response from the /todos API endpoint.
  Future<LikeApiResult<Response>> fetchTodos({ARS? ars}) {
    return LikeClient().get('/todos', ars: ars);
  }

  /// Fetches raw response from the /users/{id} API endpoint.
  Future<LikeApiResult<Response>> fetchUser(int id, {ARS? ars}) {
    return LikeClient().get('/users/$id', ars: ars);
  }

  /// Creates a new todo item using a POST request to /todos.
  Future<LikeApiResult<Response>> createTodo(Map<String, dynamic> data) {
    return LikeClient().post('/todos', body: data);
  }
}
