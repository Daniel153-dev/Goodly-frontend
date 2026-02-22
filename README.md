# GOODLY Flutter App

Application Flutter multi-plateforme (mobile, desktop, web) pour le réseau social GOODLY.

## Installation

### Prérequis

- Flutter SDK 3.0 ou supérieur
- Dart SDK 3.0 ou supérieur
- Android Studio / Xcode (pour mobile)
- Visual Studio (pour Windows desktop)
- Chrome (pour web)

### Installation des dépendances

```bash
flutter pub get
```

## Lancement de l'application

### Mobile (Android/iOS)

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Desktop Windows

```bash
flutter run -d windows
```

### Desktop macOS

```bash
flutter run -d macos
```

### Desktop Linux

```bash
flutter run -d linux

 📋 Pour tester manuellement :

  Si vous préférez lancer manuellement :

  # 1. Vérifier les appareils disponibles
  flutter devices

  # 2. Lancer sur l'appareil de votre choix
  flutter run -d <device-id>

  # Exemples :
  flutter run -d chrome
  flutter run -d edge
  flutter run -d "sdk gphone64 x86 64"  # Émulateur Android

  ⚡ Démarrage rapide :

  1. Backend :
    - Fermez les consoles Python
    - Double-cliquez sur goodly_backend\start_all_services.bat
  2. Frontend :
    - Ouvrez un terminal dans goodly_frontend\goodly_app
    - Exécutez flutter run et choisissez l'appareil

    cd D:\PROJECTS\GOODLY\goodly_frontend\goodly_app
  flutter run
```

## Configuration

### API Backend

Modifier l'URL de l'API dans `lib/core/api/api_constants.dart`:

```dart
static const String baseUrl = 'https://goodly.abrdns.com';  // Développement
// static const String baseUrl = 'https://api.goodly.com';  // Production
```

## Structure du projet

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart       # Client HTTP avec Dio
│   │   └── api_constants.dart    # URLs des endpoints
│   ├── constants/
│   │   └── app_constants.dart    # Constantes de l'app
│   ├── routes/
│   │   └── app_routes.dart       # Configuration GoRouter
│   └── theme/
│       └── app_theme.dart        # Thème Material 3
│
├── features/
│   ├── auth/
│   │   ├── screens/              # Écrans de connexion/inscription
│   │   ├── services/             # Service d'authentification
│   │   └── widgets/              # Widgets spécifiques à l'auth
│   │
│   ├── home/
│   │   ├── screens/              # Page d'accueil
│   │   └── widgets/              # Widgets de la home
│   │
│   ├── publications/
│   │   ├── screens/              # Flux, création, détail
│   │   ├── services/             # Service de publications
│   │   └── widgets/              # Widgets de publications
│   │
│   ├── profile/
│   │   ├── screens/              # Profil, édition
│   │   └── widgets/              # Widgets du profil
│   │
│   └── moderation/
│       ├── screens/              # Dashboard admin
│       └── widgets/              # Widgets de modération
│
└── shared/
    ├── models/
    │   ├── utilisateur.dart      # Modèle Utilisateur
    │   └── publication.dart      # Modèle Publication
    │
    ├── widgets/
    │   ├── custom_button.dart    # Boutons personnalisés
    │   ├── loading_widget.dart   # Indicateurs de chargement
    │   └── error_widget.dart     # Widgets d'erreur
    │
    └── utils/
        ├── validators.dart       # Validation de formulaires
        ├── formatters.dart       # Formatage de texte
        └── helpers.dart          # Fonctions utilitaires
```

## Services disponibles

### AuthService

Service d'authentification et de gestion du profil.

```dart
final authService = AuthService(apiClient);

// Inscription
await authService.inscription(
  nomUtilisateur: 'john_doe',
  email: 'john@example.com',
  motDePasse: 'SecurePass123!',
);

// Connexion
await authService.connexion(
  email: 'john@example.com',
  motDePasse: 'SecurePass123!',
);

// Profil
final utilisateur = await authService.obtenirProfil();

// Upload photo
await authService.uploadPhotoProfil('/path/to/photo.jpg');
await authService.uploadPhotoGalerie('/path/to/photo.jpg', 1);
```

### PublicationsService

Service de gestion des publications.

```dart
final pubsService = PublicationsService(apiClient);

// Créer une publication
await pubsService.creerPublication(
  titre: 'Ma bonne action',
  description: 'Description...',
  typeContenu: 'photo_unique',
  imagesUrls: ['url1.jpg'],
  categorie: 'environnement',
);

// Flux public
final publications = await pubsService.obtenirFluxPublications(
  skip: 0,
  limit: 20,
);

// Ajouter une inspiration
await pubsService.ajouterInspiration(publicationId);
```

## Modèles

### Utilisateur

```dart
class Utilisateur {
  final String idUtilisateur;
  final String nomUtilisateur;
  final String email;
  final String? photoProfil;
  final String? photoGalerie1;
  final String? photoGalerie2;
  final String? photoGalerie3;
  final String? biographie;
  final String role;
  // ...
}
```

### Publication

```dart
class Publication {
  final String idPublication;
  final String idUtilisateur;
  final String titre;
  final String description;
  final String typeContenu; // 'photo_unique' ou 'carrousel'
  final List<String> imagesUrls;
  final String? categorie;
  final String statut; // 'en_attente', 'approuve', 'rejete'
  final int nombreInspirations;
  // ...
}
```

## Thème

Le thème GOODLY utilise Material 3 avec une palette verte :

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF4CAF50), // Vert GOODLY
  brightness: Brightness.light,
),
```

## State Management

Le projet utilise Provider pour la gestion d'état. Exemples à implémenter :

```dart
// providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  Utilisateur? _utilisateur;
  bool _isAuthenticated = false;

  Future<void> login(String email, String password) async {
    // Logique de connexion
    notifyListeners();
  }
}

// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => PublicationsProvider()),
  ],
  child: MyApp(),
)
```

## Sécurité

### Stockage des tokens

Les tokens JWT sont stockés de manière sécurisée avec Flutter Secure Storage :

```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
final token = await storage.read(key: 'access_token');
```

### Refresh automatique

Le client API gère automatiquement le rafraîchissement des tokens expirés.

## Tests

### Tests unitaires

```bash
flutter test test/unit/
```

### Tests de widgets

```bash
flutter test test/widget/
```

### Tests d'intégration

```bash
flutter test test/integration/
```

## Build de production

### Android (APK)

```bash
flutter build apk --release
```

### Android (App Bundle)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

## Dépendances principales

| Package | Version | Usage |
|---------|---------|-------|
| cupertino_icons | ^1.0.6 | Icônes iOS |
| provider | ^6.1.1 | State management |
| dio | ^5.4.1 | Client HTTP |
| flutter_secure_storage | ^9.0.0 | Stockage sécurisé |
| go_router | ^13.0.0 | Navigation |
| image_picker | ^1.0.7 | Sélection d'images |
| geolocator | ^11.0.0 | Géolocalisation |
| cached_network_image | ^3.3.1 | Cache d'images |
| google_fonts | ^6.1.0 | Polices Google |

## Prochaines étapes

### Écrans à développer

1. **Auth**
   - [ ] Page de connexion
   - [ ] Page d'inscription
   - [ ] Récupération de mot de passe

2. **Profil**
   - [ ] Page de profil utilisateur
   - [ ] Édition du profil
   - [ ] Upload de photos (profil + galerie)
   - [ ] Mes publications

3. **Publications**
   - [ ] Flux public avec infinite scroll
   - [ ] Carte de publication avec carrousel
   - [ ] Création de publication
   - [ ] Upload d'images
   - [ ] Détail d'une publication
   - [ ] Bouton d'inspiration

4. **Modération (Admin)**
   - [ ] Dashboard de modération
   - [ ] Liste des publications en attente
   - [ ] Validation/rejet de publications
   - [ ] Gestion des signalements
   - [ ] Statistiques

5. **Autres**
   - [ ] Notifications
   - [ ] Paramètres
   - [ ] À propos
   - [ ] Mentions légales

### Fonctionnalités à ajouter

- [ ] Dark mode
- [ ] Internationalisation (i18n)
- [ ] Notifications push
- [ ] Mode hors-ligne
- [ ] Analytics
- [ ] Partage de publications
- [ ] Recherche avancée
- [ ] Filtres et tri

## Conventions de code

- **Noms de fichiers** : snake_case (ex: `auth_service.dart`)
- **Classes** : PascalCase (ex: `AuthService`)
- **Variables** : camelCase (ex: `nomUtilisateur`)
- **Constantes** : camelCase (ex: `apiBaseUrl`)
- **Commentaires** : Documentation claire pour les fonctions publiques

## Debug

### Logs

Utiliser `print()` ou `debugPrint()` pour le debug :

```dart
debugPrint('Utilisateur connecté: ${utilisateur.nomUtilisateur}');
```

### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Problèmes courants

### "Failed to load network image"

Vérifier que le backend est lancé et accessible à l'URL configurée.

### "No MaterialLocalizations found"

Ajouter `MaterialApp` à la racine de l'application.

### "Token expired"

Le refresh automatique devrait gérer cela. Sinon, se reconnecter.

## Ressources

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Dart](https://dart.dev/guides)
- [Dio](https://pub.dev/packages/dio)
- [Provider](https://pub.dev/packages/provider)
- [GoRouter](https://pub.dev/packages/go_router)

## Licence

Tous droits réservés © 2024 GOODLY

---

**Version:** 1.0.0
**Dernière mise à jour:** Janvier 2024
