import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration de l'environnement pour GOODLY
///
/// Utilisé pour centraliser la configuration selon l'environnement (development/production)
/// Les valeurs sont définies au build via --dart-define
class Environment {
  /// Nom de l'environnement actuel
  /// Valeurs possibles: 'development', 'production'
  static const String name = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// URL de l'API backend.
  /// Pour le web, retourne une chaîne vide pour utiliser des chemins relatifs.
  /// Pour le mobile, utilise la valeur définie au build.
  static String get apiUrl {
    // Sur le web, l'URL absolue est nécessaire car le frontend et le backend sont sur des domaines différents.
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://goodly.abrdns.com', // Garder une valeur par défaut pour le développement local ou si non spécifié
    );
    // Sur mobile, l'URL absolue est nécessaire.
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://goodly.abrdns.com',
    );
  }

  /// Mode debug activé/désactivé
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );

  /// Clé publique Stripe
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51RpHMHDUKHeEZYpIwvWy7yaWCYVCLTtWacmQO8LC1Ars8Ebby2EgaBFzX4a9iyv8rJ5SdrbEbhhcAtgCBOYXuDb100tqdVgU3L',
  );

  // Helpers pour vérifier l'environnement

  /// Retourne true si on est en production
  static bool get isProduction => name == 'production';

  /// Retourne true si on est en développement
  static bool get isDevelopment => name == 'development';

  /// Retourne true si le mode debug est activé
  static bool get isDebug => debugMode;

  /// Affiche les informations de configuration (pour debugging)
  static void printConfig() {
    print('=== GOODLY Environment Configuration ===');
    print('Environment: $name');
    print('API URL: $apiUrl');
    print('Debug Mode: $debugMode');
    print('Stripe Key: ${stripePublishableKey.substring(0, 20)}...');
    print('Is Production: $isProduction');
    print('Is Development: $isDevelopment');
    print('=======================================');
  }
}
