import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../controller/auth_controller.dart';

class ProductService {
  static const String baseUrl = 'https://kubuku-backend-615566548712.asia-southeast2.run.app//api';
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

  static Future<List<Product>> getProducts() async {
    try {
      final userId = getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl/product/list/?user_id=$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> productsJson = data['data'];
          return productsJson.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  static Future<Product> createProduct(Product product) async {
    try {
      // print('Creating product...');
      final response = await http.post(
        Uri.parse('$baseUrl/product/create/'),
        headers: _authHeaders,
        body: json.encode(product.toCreateJson()),
      );
      // print('response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // print('status code 200');
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // print('Product created successfully');
          // Return the created product with the new ID
          final createdData = data['data'];
          return product.copyWith(
            id: createdData['id'],
          );
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  static Future<Product> updateProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product/update/${product.id}/'),
        headers: _authHeaders,
        body: json.encode(product.toUpdateJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return product;
        } else {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  static Future<void> deleteProduct(int productId) async {
    try {
      final userId = getCurrentUserId();
      final response = await http.delete(
        Uri.parse('$baseUrl/product/delete/$productId/'),
        headers: _authHeaders,
        body: json.encode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] != 'success') {
          throw Exception('API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }
}