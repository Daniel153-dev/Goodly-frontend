import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import nécessaire pour initializeDateFormatting
import 'core/api/api_client.dart';
import 'core/api/api_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/publications/services/publications_service.dart';
import 'features/publications/providers/publications_provider.dart';
import 'features/moderation/services/moderation_service.dart';
import 'features/moderation/providers/moderation_provider.dart';
import 'features/donation/services/donation_service.dart';
import 'features/donation/providers/donation_provider.dart';
import 'features/publications/services/promotion_service.dart';
import 'features/publications/providers/promotion_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null); // Initialise les données de localisation pour le formatage des dates

  // Initialiser Stripe seulement sur mobile (pas sur web)
  if (!kIsWeb) {
    Stripe.publishableKey = ApiConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const GoodlyApp());
}

class GoodlyApp extends StatelessWidget {
  const GoodlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation des services
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);
    final publicationsService = PublicationsService(apiClient);
    final moderationService = ModerationService(apiClient);
    final donationService = DonationService(apiClient);
    final promotionService = PromotionService(apiClient);

    return MultiProvider(
      providers: [
        // Provider de langue
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(),
        ),
        // Provider d'authentification
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        // Provider de publications
        ChangeNotifierProvider(
          create: (_) => PublicationsProvider(publicationsService),
        ),
        // Provider de modération (admin)
        ChangeNotifierProvider(
          create: (_) => ModerationProvider(moderationService),
        ),
        // Provider de dons
        ChangeNotifierProvider(
          create: (_) => DonationProvider(donationService),
        ),
        // Provider de promotion de posts
        ChangeNotifierProvider(
          create: (_) => PromotionProvider(promotionService),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'GOODLY',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4CAF50), // Vert GOODLY
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: false,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Écran de splash pour vérifier l'authentification
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Attendre un peu pour l'effet de splash
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Naviguer vers la bonne page selon l'état d'authentification
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              const Text(
                'GOODLY',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              // Sous-titre
              const Text(
                'Le réseau social des bonnes actions',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 48),

              // Indicateur de chargement
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
