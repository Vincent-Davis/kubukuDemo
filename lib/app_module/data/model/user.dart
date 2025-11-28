class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isPremiumUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isPremiumUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'user',
      isPremiumUser: json['isPremiumUser'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'isPremiumUser': isPremiumUser,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}

class UserRegisterRequest {
  final String email;
  final String username;
  final String password;
  final String passwordConfirm;
  final String? role;
  final String? firstName;
  final String? lastName;

  UserRegisterRequest({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    this.role,
    this.firstName,
    this.lastName,
  });

  // Convenience constructor that automatically sets role to "user"
  UserRegisterRequest.user({
    required this.email,
    required this.username,
    required this.password,
    required this.passwordConfirm,
    this.firstName,
    this.lastName,
  }) : role = 'user';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'username': username,
      'password': password,
      'password_confirm': passwordConfirm,
    };

    if (role != null) data['role'] = role;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;

    return data;
  }

  factory UserRegisterRequest.fromJson(Map<String, dynamic> json) {
    return UserRegisterRequest(
      email: json['email'],
      username: json['username'],
      password: json['password'],
      passwordConfirm: json['password_confirm'],
      role: json['role'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

class UserLoginRequest {
  final String email;
  final String password;

  UserLoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  factory UserLoginRequest.fromJson(Map<String, dynamic> json) {
    return UserLoginRequest(email: json['email'], password: json['password']);
  }
}

class UserUpdateRequest {
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;

  UserUpdateRequest({this.username, this.email, this.firstName, this.lastName});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    return data;
  }

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}
