import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controller/auth_controller.dart';
import '../models/chat_session.dart';
import '../models/parsed_transaction.dart';

class ChatService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static AuthController? _authController;

  // Set the AuthController instance
  static void setAuthController(AuthController authController) {
    _authController = authController;
  }

  // Get current user ID from AuthController
  static String getCurrentUserId() {
    final userId = AuthController.getCurrentUserId(_authController);
    if (userId == null) {
      throw Exception('Anda belum login. Silakan login terlebih dahulu.');
    }
    return userId;
  }

  // Get headers with authorization token
  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authController != null && _authController!.token.isNotEmpty)
      'Authorization': 'Token ${_authController!.token}',
  };

  /// Parse message using Gemini API
  static Future<ParsedTransaction> parseTransaction(String message, {String? sessionId}) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl/gemini/parse-transaction/'),
        headers: _authHeaders,
        body: jsonEncode({
          'user_id': userId,
          'message': message,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return ParsedTransaction.fromJson(data['structured_response']);
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to parse transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error parsing transaction: $e');
    }
  }

  /// Send regular chat message (for non-transaction queries)
  static Future<String> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gemini/chat/'),
        headers: _authHeaders,
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          // Try to get structured response first, fallback to raw text
          if (data['structured'] != null && data['structured']['response'] != null) {
            return data['structured']['response'];
          } else {
            return data['cleaned'] ?? data['raw_text'] ?? 'Tidak ada respons dari AI';
          }
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to send chat message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending chat message: $e');
    }
  }

  /// Create a new chat session
  static Future<ChatSession> createChatSession({String? title}) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/session/create/'),
        headers: _authHeaders,
        body: jsonEncode({
          'user_id': userId,
          'title': title ?? 'New Transaction Chat',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return ChatSession.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create chat session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat session: $e');
    }
  }

  /// Get chat sessions for current user
  static Future<List<ChatSession>> getChatSessions() async {
    try {
      final userId = getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/session/list/?user_id=$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> sessionsJson = data['data'];
          return sessionsJson.map((json) => ChatSession.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to get chat sessions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat sessions: $e');
    }
  }

  /// Add message to chat session
  static Future<void> addMessageToSession(String sessionId, String message, String sender) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/message/create/'),
        headers: _authHeaders,
        body: jsonEncode({
          'session_id': sessionId,
          'user_id': userId,
          'message': message,
          'sender': sender,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception('Failed to add message: ${data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error adding message: $e');
    }
  }

  /// Get messages for a chat session
  static Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/session/$sessionId/?user_id=$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> messagesJson = data['data']['messages'];
          return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to get session messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting session messages: $e');
    }
  }
}