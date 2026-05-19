class UserModel {
  final int id;
  final String name;
  final String email;
  final String avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 1,
      name: json['name'] as String? ?? 'John Doe',
      email: json['email'] as String? ?? 'john.doe@example.com',
      avatarUrl: json['avatarUrl'] as String? ?? 'https://picsum.photos/200',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
  };
}
