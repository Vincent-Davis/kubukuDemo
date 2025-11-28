import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
  static const String baseUrl = 'http://127.0.0.1:8000/api/auth';
  static const String _tokenKey = 'auth_token';

  AuthController() {
    initialize();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get token => _token;
  User? get currentUser => _currentUser;
  String get username => _currentUser?.username ?? '';
  String get email => _currentUser?.email ?? '';
  String get fullName => _currentUser?.fullName ?? '';

  // Save token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Load token from local storage
  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear token from local storage
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Get headers with authorization token
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Token $_token',
  };

  Future<void> initialize() async {
    final savedToken = await _loadToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      await checkLoginStatus();
    }
  }

  Future<void> checkLoginStatus() async {
    try {
      if (_token.isEmpty) {
        _isLoggedIn = false;
        _currentUser = null;
        notifyListeners();
        return;
      }

      final url = '$baseUrl/profile/';
      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user'] != null) {
          _isLoggedIn = true;
          _currentUser = User.fromJson(data['user']);
        } else {
          _isLoggedIn = false;
          _currentUser = null;
          _token = '';
          await _clearToken();
        }
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
        await _clearToken();
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _token = '';
      await _clearToken();
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

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registerData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['token'] != null) {
        _token = responseData['token'];
        await _saveToken(_token);
        _isLoggedIn = true;
        _currentUser = User.fromJson(responseData['user']);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
      }

      notifyListeners();
      return AuthResponse.fromJson(responseData);
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
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginRequest.toJson()),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        _token = responseData['token'];
        await _saveToken(_token);
        _isLoggedIn = true;
        _currentUser = User.fromJson(responseData['user']);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _token = '';
      }

      notifyListeners();
      return AuthResponse.fromJson(responseData);
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
      final response = await http.post(
        Uri.parse(url),
        headers: _authHeaders,
      );

      _isLoggedIn = false;
      _currentUser = null;
      _token = '';
      await _clearToken();

      notifyListeners();
      
      final responseData = response.statusCode == 200 
        ? json.decode(response.body)
        : {'message': 'Logged out successfully'};
      
      return AuthResponse.fromJson(responseData);
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
      _token = '';
      await _clearToken();

      notifyListeners();
      return AuthResponse(message: 'Logged out successfully', error: null);
    }
  }

  Future<AuthResponse> updateProfile(UserUpdateRequest updateRequest) async {
    try {
      final url = '$baseUrl/profile/update/';
      final response = await http.put(
        Uri.parse(url),
        headers: _authHeaders,
        body: jsonEncode(updateRequest.toJson()),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['user'] != null) {
        _currentUser = User.fromJson(responseData['user']);
      }

      notifyListeners();
      return AuthResponse.fromJson(responseData);
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
    _clearToken();
    notifyListeners();
  }

  /// Static method to get current user ID
  /// This requires a global AuthController instance
  static String? getCurrentUserId(AuthController? authController) {
    return authController?.currentUser?.id.toString();
  }
}
