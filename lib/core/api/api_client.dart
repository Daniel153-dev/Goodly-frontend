import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'api_constants.dart';

/// Client API pour GOODLY utilisant Dio
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
          // 'Content-Type': 'application/json' est automatiquement défini par Dio pour les requêtes JSON
          // Pour multipart, il sera défini automatiquement avec les bonnes valeurs
        },
      ),
    );

    // Intercepteur pour ajouter automatiquement le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'accès si disponible
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Gérer le renouvellement du token si 401
          if (error.response?.statusCode == 401) {
            // Tentative de rafraîchir le token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Réessayer la requête
              return handler.resolve(await _retry(error.requestOptions));
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Effectue une requête GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Effectue une requête DELETE
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload de fichiers multipart à partir de XFile (compatible web et mobile)
  Future<Response> uploadFiles(
    String path,
    List<XFile> files, {
    Map<String, dynamic>? data,
    String fieldName = 'files',
  }) async {
    try {
      // Créer FormData directement
      final formData = FormData();
      
      // Ajouter les fichiers
      for (var file in files) {
        final bytes = await file.readAsBytes();
        formData.files.add(MapEntry(
          fieldName,
          MultipartFile.fromBytes(bytes, filename: file.name),
        ));
      }
      
      // Ajouter les données
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }
      
      // Utiliser _dio directement avec timeout augmenté
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Erreur upload: $e');
    }
  }

  /// Rafraîchit le token d'accès
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('DEBUG _refreshToken: refreshToken est null dans secure storage');
        return false;
      }

      print('DEBUG _refreshToken: Tentative de refresh vers /auth/refresh');
      
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      print('DEBUG _refreshToken: Réponse status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        await _storage.write(key: 'access_token', value: newAccessToken);
        
        // Mettre aussi à jour le refresh token si fourni
        if (response.data['refresh_token'] != null) {
          await _storage.write(key: 'refresh_token', value: response.data['refresh_token']);
        }
        
        print('DEBUG _refreshToken: Nouveau token stocké avec succès');
        return true;
      }
      return false;
    } catch (e) {
      print('DEBUG _refreshToken: Erreur = $e');
      return false;
    }
  }

  /// Réessaye une requête après rafraîchissement du token
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Gère les erreurs Dio
  Exception _handleError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Délai d\'attente de connexion dépassé. Vérifiez votre connexion internet.';
        break;
      
      case DioExceptionType.sendTimeout:
        message = 'Délai d\'envoi dépassé. Votre connexion est trop lente pour cet upload. Vérifiez votre Wi-Fi ou réseau 4G/5G.';
        break;
      
      case DioExceptionType.receiveTimeout:
        message = 'Délai de réception dépassé. Votre connexion est instable.';
        break;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map && responseData.containsKey('detail')) {
          message = responseData['detail'];
        } else {
          message = _getStatusCodeMessage(statusCode);
        }
        break;

      case DioExceptionType.cancel:
        message = 'Requête annulée par l\'utilisateur';
        break;

      case DioExceptionType.connectionError:
        message = 'Erreur de connexion. Vérifiez votre connexion internet et que le serveur est accessible.';
        break;

      case DioExceptionType.unknown:
        message = 'Erreur inconnue: ${error.message ?? "Veuillez réessayer"}';
        break;

      default:
        message = 'Une erreur inattendue s\'est produite';
    }

    return Exception(message);
  }

  /// Retourne un message en fonction du code de statut HTTP
  String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Non autorisé. Veuillez vous connecter.';
      case 403:
        return 'Accès refusé';
      case 404:
        return 'Ressource non trouvée';
      case 500:
        return 'Erreur serveur. Réessayez plus tard.';
      case 503:
        return 'Service temporairement indisponible';
      default:
        return 'Erreur réseau (Code: $statusCode)';
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _dio.close();
  }
}
