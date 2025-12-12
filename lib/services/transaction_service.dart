import 'dart:convert';
import '../models/transaction.dart';
import '../controller/auth_controller.dart';
import 'http_service.dart';

class TransactionService {
  static const String baseUrl = 'https://kubuku-backend-615566548712.asia-southeast2.run.app/api';
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

  static Future<List<Transaction>> getTransactions() async {
    try {
      final userId = getCurrentUserId();
      final response = await HttpService.get(
        Uri.parse('$baseUrl/transaction/list/?user_id=$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> transactionsJson = data['data'];
          return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  static Future<Transaction> getTransactionDetail(int transactionId) async {
    try {
      final userId = getCurrentUserId();
      final response = await HttpService.get(
        Uri.parse('$baseUrl/transaction/detail/$transactionId/?user_id=$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return Transaction.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load transaction detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transaction detail: $e');
    }
  }

  static Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await HttpService.post(
        Uri.parse('$baseUrl/transaction/create/'),
        headers: _authHeaders,
        body: jsonEncode(transaction.toCreateJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Return the created transaction with the new ID
          return transaction.copyWith(
            id: data['transaction_id'],
            totalAmount: data['total_amount']?.toDouble(),
          );
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  static Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final response = await HttpService.post(
        Uri.parse('$baseUrl/transaction/update/${transaction.id}/'),
        headers: _authHeaders,
        body: jsonEncode(transaction.toUpdateJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return transaction.copyWith(
            totalAmount: data['new_total']?.toDouble() ?? transaction.totalAmount,
          );
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to update transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  static Future<void> deleteTransaction(int transactionId) async {
    try {
      final userId = getCurrentUserId();
      final response = await HttpService.delete(
        Uri.parse('$baseUrl/transaction/delete/$transactionId/'),
        headers: _authHeaders,
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] != 'success') {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to delete transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }
}