import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // for lookupMimeType
import '../controller/auth_controller.dart';
import '../models/chat_session.dart';
import '../models/parsed_transaction.dart';

class ChatService {
  static const String baseUrl = 'https://kubuku-backend-615566548712.asia-southeast2.run.app//api';
  static AuthController? _authController;

  // Normalize MIME type to ensure consistency
  static String normalizeMime(String mime) {
    if (mime == "image/jpg") return "image/jpeg";
    return mime;
  }

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

  /// Parse message using Gemini API (text only)
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

  /// Parse transaction with image (OCR functionality)
  static Future<ParsedTransaction> parseTransactionWithImage({
    XFile? imageFile,
    String? message,
    String? sessionId,
    Function(String)? onMimeInfo, // Callback untuk menampilkan info MIME
  }) async {
    try {
      if (imageFile == null && (message == null || message.isEmpty)) {
        throw Exception('Harus ada gambar atau pesan text');
      }

      final userId = getCurrentUserId();
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/gemini/parse-transaction/'),
      );

      // Add headers (excluding content-type as it's set by MultipartRequest)
      if (_authController != null && _authController!.token.isNotEmpty) {
        request.headers['Authorization'] = 'Token ${_authController!.token}';
      }

      // Add form fields
      request.fields['user_id'] = userId;
      if (message != null && message.isNotEmpty) {
        request.fields['message'] = message;
      }
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }

      // Add image file if provided
      if (imageFile != null) {
        // Use XFile.readAsBytes() which works on both web and mobile
        final bytes = await imageFile.readAsBytes();
        
        // Get MIME type using lookupMimeType and normalize it
        final mime = lookupMimeType(imageFile.path) ?? "image/jpeg";
        final normalized = normalizeMime(mime);
        final parts = normalized.split("/");
        
        // Send MIME info to UI via callback
        if (onMimeInfo != null) {
          final fileSize = (bytes.length / 1024 / 1024).toStringAsFixed(2);
          onMimeInfo('📷 File: ${imageFile.name}\n📷 MIME: $normalized\n📷 Size: ${fileSize}MB');
        }
        
        // Create MediaType from normalized MIME
        final mediaType = MediaType(parts[0], parts[1]);
        
        // EXPLICIT MIME TYPE - Match exactly what Python backend expects
        final multipartFile = http.MultipartFile.fromBytes(
          'image', // Field name must match backend
          bytes,
          filename: 'image.jpg', // Simple filename with jpg extension
          contentType: mediaType, // Use normalized MediaType
        );
        
        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          return ParsedTransaction.fromJson(data['structured_response']);
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to parse transaction: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error parsing transaction with image: $e');
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
          // For regular chat, prioritize clean natural response over structured JSON
          if (data['cleaned'] != null && data['cleaned'].toString().trim().isNotEmpty) {
            final cleanedResponse = data['cleaned'].toString().trim();
            // Skip if it looks like JSON (starts with { or contains "transaction":)
            if (!cleanedResponse.startsWith('{') && !cleanedResponse.contains('"transaction"')) {
              return cleanedResponse;
            }
          }
          
          // Fallback to raw_text
          if (data['raw_text'] != null && data['raw_text'].toString().trim().isNotEmpty) {
            final rawResponse = data['raw_text'].toString().trim();
            // Skip if it looks like JSON
            if (!rawResponse.startsWith('{') && !rawResponse.contains('"transaction"')) {
              return rawResponse;
            }
          }
          
          // Last fallback - but try to extract just the response text from structured
          if (data['structured'] != null && data['structured']['response'] != null) {
            return data['structured']['response'];
          }
          
          return 'Halo! Ada yang bisa saya bantu dengan bisnis Anda hari ini?';
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