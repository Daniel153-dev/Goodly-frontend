import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/environment.dart';
import '../api/api_constants.dart';

/// Helper pour gérer les URLs de photos en mode hybride (local/production)
class PhotoUrlHelper {
  /// Retourne l'URL complète pour une photo
  /// En local: utilise localhost:8000
  /// En production: utilise l'URL du bucket/cloudflare
  static String getFullPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';
    
    // Si c'est déjà une URL complète, la retourner directement
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }
    
    // Nettoyer le chemin
    String cleanPath = photoPath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    // En développement local (localhost), utiliser l'URL locale
    if (Environment.isDevelopment) {
      // Détecter si c'est localhost (pattern typical pour uploads locaux)
      if (cleanPath.startsWith('uploads/') || 
          cleanPath.startsWith('media/') ||
          cleanPath.contains('/uploads/') ||
          cleanPath.contains('/media/')) {
        // En local mobile, utiliser localhost:8000 (port API Gateway)
        // En local web, utiliser localhost avec le bon port
        if (kIsWeb) {
          return 'http://localhost:8000/$cleanPath';
        } else {
          return 'http://10.0.2.2:8000/$cleanPath'; // Android emulator (port 8000 pour API Gateway)
        }
      }
    }
    
    // En production, utiliser l'URL du bucket Cloudflare
    return '${ApiConstants.baseUrl}/$cleanPath';
  }
  
  /// Retourne true si l'URL est une URL locale (localhost)
  static bool isLocalUrl(String url) {
    return url.contains('localhost') || 
           url.contains('10.0.2.2') ||
           url.contains('127.0.0.1');
  }
  
  /// Retourne l'URL appropriée selon l'environnement
  static String getMediaBaseUrl() {
    if (Environment.isDevelopment) {
      if (kIsWeb) {
        return 'http://localhost:8000';
      } else {
        return 'http://10.0.2.2:8000'; // Android emulator (port 8000 pour API Gateway)
      }
    }
    // En production, les médias sont servis depuis le bucket
    return ApiConstants.baseUrl;
  }
}
