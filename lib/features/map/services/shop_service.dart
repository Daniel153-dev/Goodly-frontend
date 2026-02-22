import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/shop.dart';
import '../../../core/api/api_constants.dart';

/// Service pour gérer les boutiques
class ShopService {
  static const storage = FlutterSecureStorage();

  /// Récupère le token d'authentification
  static Future<String?> _getToken() async {
    return await storage.read(key: 'access_token');
  }
  /// Récupérer toutes les boutiques
  static Future<List<Shop>> getAllShops() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        print('Erreur: Aucun token trouvé');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllShops}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Shop.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur récupération boutiques: $e');
      return [];
    }
  }

  /// Récupérer la boutique de l'utilisateur actuel
  static Future<Shop?> getMyShop() async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.myShop}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Shop.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur récupération ma boutique: $e');
      return null;
    }
  }

  /// Créer une boutique
  static Future<Shop?> createShop(Shop shop) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        print('Erreur: Token non disponible pour createShop');
        return null;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createShop}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(shop.toJson()),
      );

      print('createShop - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Shop.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur création boutique: $e');
      return null;
    }
  }

  /// Mettre à jour une boutique
  static Future<Shop?> updateShop(String shopId, Shop shop) async {
    try {
      final token = await _getToken();
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateShop}/$shopId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(shop.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Shop.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Erreur mise à jour boutique: $e');
      return null;
    }
  }

  /// Récupérer les boutiques proches
  static Future<List<Shop>> getNearbyShops(double latitude, double longitude, {double radiusKm = 50}) async {
    try {
      final token = await _getToken();
      
      final url = '${ApiConstants.baseUrl}${ApiConstants.nearbyShops}?lat=$latitude&lng=$longitude&radius=$radiusKm';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Shop.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur récupération boutiques proches: $e');
      return [];
    }
  }

  /// Récupérer les boutiques par pays
  static Future<List<Shop>> getShopsByCountry(String pays) async {
    try {
      final token = await _getToken();
      
      final url = '${ApiConstants.baseUrl}${ApiConstants.shopsByCountry}/$pays';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Shop.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur récupération boutiques par pays: $e');
      return [];
    }
  }
}
