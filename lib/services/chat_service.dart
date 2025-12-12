import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // for lookupMimeType
import '../controller/auth_controller.dart';
import '../models/chat_session.dart';
import '../models/parsed_transaction.dart';
import 'http_service.dart';

class ChatService {
  static const String baseUrl = 'https://kubuku-backend-615566548712.asia-southeast2.run.app/api';
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
      final response = await HttpService.post(
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

  /// Voice transcription and parsing
  static Future<Map<String, dynamic>> transcribeAndParseVoice(
    String audioPath, {
    String? sessionId,
  }) async {
    try {
      final userId = getCurrentUserId();
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/voice/transcription/'),
      );

      // Add headers (excluding content-type as it's set by MultipartRequest)
      if (_authController != null && _authController!.token.isNotEmpty) {
        request.headers['Authorization'] = 'Token ${_authController!.token}';
      }

      // Add form fields
      request.fields['user_id'] = userId;
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }

      // Add audio file
      final audioFile = File(audioPath);
      final bytes = await audioFile.readAsBytes();
      
      // Get MIME type for audio
      final mime = lookupMimeType(audioPath) ?? "audio/mp3";
      final normalized = normalizeMime(mime);
      final parts = normalized.split("/");
      final mediaType = MediaType(parts[0], parts[1]);
      
      final multipartFile = http.MultipartFile.fromBytes(
        'file', // Backend expects 'file' field
        bytes,
        filename: 'audio.${parts[1]}',
        contentType: mediaType,
      );
      
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data; // Return full response including transcript and structured_response
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to transcribe voice: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error transcribing voice: $e');
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
      final response = await HttpService.post(
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
      final response = await HttpService.post(
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
      final response = await HttpService.get(
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
      final response = await HttpService.post(
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
      final response = await HttpService.get(
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

  /// Send message to Amartha RAG system
  static Future<String> sendAmarthaRagMessage(String query, {String? sessionId}) async {
    try {
      final url = sessionId != null 
          ? '$baseUrl/rag/chat/$sessionId/' 
          : '$baseUrl/rag/chat/';

      final response = await HttpService.post(
        Uri.parse(url),
        headers: _authHeaders,
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final messages = data['new_messages'] as List<dynamic>;
          // Find the bot response (last message that's from bot)
          final botMessage = messages.lastWhere(
            (msg) => msg['sender'] == 'bot',
            orElse: () => null,
          );
          
          if (botMessage != null) {
            return botMessage['message'] as String;
          } else {
            return 'Maaf, tidak ada respons dari sistem Amartha.';
          }
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to send Amartha RAG message: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending Amartha RAG message: $e');
    }
  }

  /// Send message to Analytics/Financial chatbot
  static Future<String> sendAnalyticsMessage(String message) async {
    try {
      final response = await HttpService.post(
        Uri.parse('$baseUrl/analytics/chat/'),
        headers: _authHeaders,
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['reply'] != null) {
          String reply = data['reply'] as String;
          
          // Apply smart parsing to extract clean text
          return _parseAnalyticsResponse(reply);
        } else {
          throw Exception('No reply field in response');
        }
      } else {
        throw Exception('Failed to send analytics message: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending analytics message: $e');
    }
  }

  /// Smart parser for analytics responses
  static String _parseAnalyticsResponse(String reply) {
    // First, try to parse as JSON
    try {
      final replyJson = json.decode(reply);
      
      if (replyJson is Map<String, dynamic>) {
        return _extractMeaningfulText(replyJson);
      } else if (replyJson is String) {
        return replyJson;
      }
    } catch (e) {
      // If not JSON, return as-is after cleaning
      return _cleanPlainText(reply);
    }
    
    return reply;
  }

  /// Extract meaningful text from JSON response
  static String _extractMeaningfulText(Map<String, dynamic> jsonData) {
    // Pattern 1: Direct output field
    if (jsonData.containsKey('output')) {
      return _cleanPlainText(jsonData['output'].toString());
    }
    
    // Pattern 2: Tool responses (e.g., analyze_credit_health_response)
    for (String key in jsonData.keys) {
      if (key.endsWith('_response') && jsonData[key] is Map<String, dynamic>) {
        final toolResponse = jsonData[key] as Map<String, dynamic>;
        if (toolResponse.containsKey('output')) {
          return _formatAnalyticsOutput(toolResponse['output'].toString());
        }
      }
    }
    
    // Pattern 3: Multiple tool outputs - combine them
    List<String> outputs = [];
    for (String key in jsonData.keys) {
      if (key.endsWith('_response')) {
        final value = jsonData[key];
        if (value is Map<String, dynamic> && value.containsKey('output')) {
          outputs.add(_formatAnalyticsOutput(value['output'].toString()));
        }
      }
    }
    
    if (outputs.isNotEmpty) {
      return outputs.join('\n\n');
    }
    
    // Pattern 4: Fallback - format the entire JSON nicely
    return _formatJsonAsText(jsonData);
  }

  /// Format analytics output for better readability
  static String _formatAnalyticsOutput(String output) {
    // Clean up common formatting issues
    String cleaned = output;
    
    // Remove customer IDs and technical details
    cleaned = cleaned.replaceAll(RegExp(r'Customer [a-f0-9]+:?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'for Customer [a-f0-9]+\s*'), '');
    
    // Format currency better
    cleaned = cleaned.replaceAll('IDR ', 'Rp ');
    cleaned = cleaned.replaceAll(RegExp(r'IDR\s*0\.00'), 'Rp 0');
    
    // Add line breaks before each component (- indicates a new item)
    cleaned = cleaned.replaceAll(' - ', '\n• ');
    
    // Format status and advice with proper line breaks
    if (cleaned.contains('Status:') && cleaned.contains('Advice:')) {
      final parts = cleaned.split('Advice:');
      if (parts.length == 2) {
        String statusPart = parts[0].trim();
        String advicePart = parts[1].trim();
        
        // Format status section with line breaks
        statusPart = statusPart.replaceAll('Status:', '📊 Status:');
        statusPart = statusPart.replaceAll('Weekly Surplus:', '\n💰 Surplus Mingguan:');
        statusPart = statusPart.replaceAll('Next Bill:', '\n📅 Tagihan Berikutnya:');
        statusPart = statusPart.replaceAll('Total Outstanding:', '\n💳 Total Hutang:');
        statusPart = statusPart.replaceAll('Max DPD:', '\n⏰ Keterlambatan Maksimal:');
        
        // Clean up bullet points in status
        statusPart = statusPart.replaceAll('• Status:', '📊 Status:');
        statusPart = statusPart.replaceAll('• Weekly Surplus:', '💰 Surplus Mingguan:');
        statusPart = statusPart.replaceAll('• Next Bill:', '📅 Tagihan Berikutnya:');
        statusPart = statusPart.replaceAll('• Total Outstanding:', '💳 Total Hutang:');
        statusPart = statusPart.replaceAll('• Max DPD:', '⏰ Keterlambatan Maksimal:');
        
        // Format advice section
        advicePart = '💡 Saran: ' + advicePart;
        
        return statusPart + '\n\n' + advicePart;
      }
    }
    
    // Format simple outputs with better spacing
    if (cleaned.toLowerCase().contains('total income')) {
      cleaned = cleaned.replaceAll('Total income for ', '💰 Total pendapatan ');
      cleaned = cleaned.replaceAll('this_week:', 'minggu ini:');
      cleaned = cleaned.replaceAll('this_month:', 'bulan ini:');
      cleaned = cleaned.replaceAll('today:', 'hari ini:');
    }
    
    if (cleaned.toLowerCase().contains('total expense')) {
      cleaned = cleaned.replaceAll('Total expense for ', '💸 Total pengeluaran ');
      cleaned = cleaned.replaceAll('this_week:', 'minggu ini:');
      cleaned = cleaned.replaceAll('this_month:', 'bulan ini:');
      cleaned = cleaned.replaceAll('today:', 'hari ini:');
    }
    
    // Clean up extra spaces and normalize line breaks
    cleaned = cleaned.replaceAll(RegExp(r'\s*\n\s*'), '\n');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return _cleanPlainText(cleaned);
  }

  /// Format JSON as readable text when no specific pattern matches
  static String _formatJsonAsText(Map<String, dynamic> jsonData) {
    List<String> lines = [];
    
    for (String key in jsonData.keys) {
      final value = jsonData[key];
      String formattedKey = _formatKey(key);
      String formattedValue = _formatValue(value);
      
      if (formattedValue.isNotEmpty && formattedValue != 'null') {
        lines.add('$formattedKey: $formattedValue');
      }
    }
    
    return lines.join('\n');
  }

  /// Clean plain text from unwanted characters and formatting
  static String _cleanPlainText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Multiple spaces/tabs to single space (but keep newlines)
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Multiple newlines to double newline max
        .replaceAll('"', '') // Remove quotes
        .replaceAll('{', '') // Remove JSON artifacts
        .replaceAll('}', '')
        .trim();
  }

  // Helper method to format JSON keys for display
  static String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  // Helper method to format JSON values for display
  static String _formatValue(dynamic value) {
    if (value is String) {
      return _cleanPlainText(value);
    } else if (value is Map<String, dynamic>) {
      if (value.containsKey('output')) {
        return _formatAnalyticsOutput(value['output'].toString());
      }
      // Format nested objects
      String result = '';
      for (String key in value.keys) {
        if (result.isNotEmpty) result += ', ';
        result += '${_formatKey(key)}: ${value[key]}';
      }
      return result;
    } else if (value is List) {
      return value.map((item) => _formatValue(item)).join(', ');
    } else {
      return value.toString();
    }
  }

  /// Get cashflow trend data for charts
  static Future<Map<String, dynamic>> getCashflowTrend() async {
    try {
      final response = await HttpService.get(
        Uri.parse('$baseUrl/analytics/cashflow-trend/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get cashflow trend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting cashflow trend: $e');
    }
  }
}