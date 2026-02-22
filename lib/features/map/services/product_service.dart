import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../../../core/api/api_constants.dart';

/// Service pour gérer les produits
class ProductService {
  static const storage = FlutterSecureStorage();

  /// Récupérer le token d'authentification
  static Future<String?> _getToken() async {
    return await storage.read(key: 'access_token');
  }

  /// Récupérer tous les produits d'une boutique
  static Future<List<Product>> getProductsByShop(String shopId) async {
    try {
      final token = await _getToken();
      
      final url = '${ApiConstants.baseUrl}${ApiConstants.getShopProducts}?shop_id=$shopId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur récupération produits: $e');
      return [];
    }
  }

  /// Récupérer un produit par ID
  static Future<Product?> getProduct(String productId) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getProduct(productId)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur récupération produit: $e');
      return null;
    }
  }

  /// Créer un produit
  static Future<Product?> createProduct(Product product) async {
    try {
      final token = await _getToken();
      
      print('createProduct - Token: ${token != null}');
      print('createProduct - Data: ${product.toJson()}');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createProduct}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(product.toJson()),
      );

      print('createProduct - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur création produit: $e');
      return null;
    }
  }

  /// Mettre à jour un produit
  static Future<Product?> updateProduct(String productId, Product product) async {
    try {
      final token = await _getToken();
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProduct}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur mise à jour produit: $e');
      return null;
    }
  }

  /// Supprimer un produit
  static Future<bool> deleteProduct(String productId) async {
    try {
      final token = await _getToken();
      
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteProduct}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur suppression produit: $e');
      return false;
    }
  }

  /// Uploader une image de produit
  static Future<String?> uploadProductImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProductImage}');
      final request = http.MultipartRequest('POST', uri);
      
      final token = await _getToken();
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'product_${DateTime.now().millisecondsSinceEpoch}.webp',
        ),
      );

      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['url'] ?? jsonResponse['image_url'];
      }
      
      return null;
    } catch (e) {
      print('Erreur upload image produit: $e');
      return null;
    }
  }
}
