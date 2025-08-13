class User {
  final int id;
  final String email;
  final String displayName;
  final String? role;
  final String? username;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.role,
    this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['username'] ?? '',
      role: json['role'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role,
      'username': username,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, role: $role)';
  }
}
