import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../app_module/data/model/user.dart';

class AuthResponse {
  final String message;
  final String? error;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? details;

  AuthResponse({required this.message, this.error, this.data, this.details});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] ?? 'Unknown response',
      error: json['error'],
      data: json['data'],
      details: json['details'],
    );
  }

  bool get isSuccess => error == null;
  bool get isError => error != null;
}

class AuthController extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _token = '';
  User? _currentUser;
  final CookieRequest request;
  static const String baseUrl = 'http://127.0.0.1:8000/api/auth';

  AuthController({required this.request}) {
    initialize();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get token => _token;
  User? get currentUser => _currentUser;
  String get username => _currentUser?.username ?? '';
  String get email => _currentUser?.email ?? '';
  String get fullName => _currentUser?.fullName ?? '';

  Future<void> initialize() async {
    await checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final url = '$baseUrl/profile/';
      final response = await request.get(url);

      if (response['user'] != null) {
        _isLoggedIn = true;
        _currentUser = User.fromJson(response['user']);
        // Token is managed by pbp_django_auth automatically
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _token = '';
    }
    notifyListeners();
  }

  /// Registers a new user with role automatically set to "user"
  Future<AuthResponse> register(UserRegisterRequest registerRequest) async {
    try {
      final url = '$baseUrl/register/';
      // Ensure role is always set to "user" for new registrations
      final registerData = registerRequest.toJson();
      registerData['role'] = 'user';

      final response = await request.postJson(url, jsonEncode(registerData));

      if (response['user'] != null && response['token'] != null) {
        _isLoggedIn = true;
        _currentUser = User.fromJson(response['user']);
        _token = response['token'];
        // pbp_django_auth handles token storage automatically
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
      }

      notifyListeners();
      return AuthResponse.fromJson(response);
    } catch (e) {
      notifyListeners();
      return AuthResponse(
        message: 'Registration failed: ${e.toString()}',
        error: 'Registration failed',
      );
    }
  }

  Future<AuthResponse> login(UserLoginRequest loginRequest) async {
    try {
      final url = '$baseUrl/login/';
      final response = await request.postJson(
        url,
        jsonEncode(loginRequest.toJson()),
      );

      if (response['user'] != null && response['token'] != null) {
        _isLoggedIn = true;
        _currentUser = User.fromJson(response['user']);
        _token = response['token'];
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
      }

      notifyListeners();
      return AuthResponse.fromJson(response);
    } catch (e) {
      notifyListeners();
      return AuthResponse(
        message: 'Login failed: ${e.toString()}',
        error: 'Login failed',
      );
    }
  }

  Future<AuthResponse> logout() async {
    try {
      final url = '$baseUrl/logout/';
      final response = await request.post(url, {});

      _isLoggedIn = false;
      _currentUser = null;
      _token = '';

      notifyListeners();
      return AuthResponse.fromJson(response);
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _token = '';

      notifyListeners();
      return AuthResponse(message: 'Logged out successfully', error: null);
    }
  }

  Future<AuthResponse> updateProfile(UserUpdateRequest updateRequest) async {
    try {
      final url = '$baseUrl/profile/update/';
      final response = await request.postJson(
        url,
        jsonEncode(updateRequest.toJson()),
      );

      if (response['user'] != null) {
        _currentUser = User.fromJson(response['user']);
      }

      notifyListeners();
      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        message: 'Update profile failed: ${e.toString()}',
        error: 'Profile update failed',
      );
    }
  }

  /// Helper method to register a user with automatic role assignment
  Future<AuthResponse> registerUser({
    required String email,
    required String username,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    final registerRequest = UserRegisterRequest.user(
      email: email,
      username: username,
      password: password,
      passwordConfirm: passwordConfirm,
      firstName: firstName,
      lastName: lastName,
    );

    return await register(registerRequest);
  }

  void clearUserData() {
    _isLoggedIn = false;
    _currentUser = null;
    _token = '';
    notifyListeners();
  }
}
