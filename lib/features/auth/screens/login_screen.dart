import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/models/user_session.dart';
import '../../../core/utils/photo_url_helper.dart';
import '../../../core/l10n/app_localizations.dart';
import 'register_screen.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    // Charger les sessions mémorisées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadSessionsMemorisees();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.connexion(
      email: _emailController.text.trim(),
      motDePasse: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.tr('login_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Connexion rapide avec une session mémorisée
  void _connexionRapide(UserSession session) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.reconnecterSession(session);
    
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.tr('login_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Bouton de changement de langue en haut à droite
            Positioned(
              top: 16,
              right: 16,
              child: const LanguageToggleButton(),
            ),
            
            // Formulaire de connexion
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(maxWidth: kIsWeb ? 480 : 600),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'GOODLY',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('login_title'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 32),

                        // ========== SESSIONS MEMORISEES ==========
                        if (authProvider.sessionsMemorisees.isNotEmpty) ...[
                          _buildSessionsMemoriseesSection(authProvider, theme),
                          const SizedBox(height: 24),
                        ],

                        // Champ Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: context.tr('email'),
                            hintText: context.tr('email_hint'),
                            prefixIcon: const Icon(Icons.mail_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('email_required');
                            }
                            // Validation email stricte avec regex
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return context.tr('email_invalid');
                            }
                            if (value.length > 254) {
                              return context.tr('email_invalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: context.tr('password'),
                            hintText: context.tr('password_hint'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('password_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bouton Se connecter
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: context.tr('login_button'),
                            onPressed: _login,
                            isLoading: authProvider.isLoading,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Séparateur
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                context.tr('or'),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Lien Inscription
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(context.tr('no_account')),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(context.tr('sign_up')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section des sessions mémorisées
  Widget _buildSessionsMemoriseesSection(AuthProvider authProvider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('saved_sessions'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Liste des sessions
        ...authProvider.sessionsMemorisees.map((session) {
          return _buildSessionCard(session, authProvider, theme);
        }).toList(),
        
        // Option pour effacer toutes les sessions
        if (authProvider.sessionsMemorisees.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await authProvider.effacerToutesSessions();
            },
            child: Text(
              context.tr('clear_sessions'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  /// Construit une carte de session mémorisée
  Widget _buildSessionCard(UserSession session, AuthProvider authProvider, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: authProvider.isLoading
            ? null
            : () => _connexionRapide(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo de profil ou initiale
              _buildAvatar(session, theme),
              const SizedBox(width: 12),
              
              // Informations de l'utilisateur (email complet)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.email, // Email complet
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildProviderIcon(session.provider),
                        const SizedBox(width: 4),
                        Text(
                          _getConnexionText(session.dateConnexion),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Indicateur de connexion rapide
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retourne la partie avant le @ de l'email
  String _getEmailPrefix(String email) {
    if (email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }

  /// Construit l'avatar de l'utilisateur (photo ou initiale)
  Widget _buildAvatar(UserSession session, ThemeData theme) {
    final hasValidPhoto = session.photoProfil != null && session.photoProfil!.isNotEmpty;
    
    if (!hasValidPhoto) {
      // Pas de photo, afficher l'initiale de l'email
      final initial = session.email.isNotEmpty 
          ? session.email[0].toUpperCase() 
          : '?';
      
      return CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          initial,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }
    
    // Charger la photo avec CachedNetworkImage
    final photoUrl = PhotoUrlHelper.getFullPhotoUrl(session.photoProfil);
    
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.primary.withOpacity(0.2),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) {
            // Fallback: afficher l'initiale
            final initial = session.email.isNotEmpty 
                ? session.email[0].toUpperCase() 
                : '?';
            return Container(
              color: theme.colorScheme.primary,
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construit l'icône du provider de connexion
  Widget _buildProviderIcon(String? provider) {
    IconData icon;
    Color color;
    
    switch (provider) {
      case 'google':
        icon = Icons.g_mobiledata;
        color = Colors.red;
        break;
      case 'apple':
        icon = Icons.apple;
        color = Colors.black;
        break;
      default:
        icon = Icons.email;
        color = Colors.blue;
    }
    
    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  /// Retourne le texte de connexion basé sur la date
  String _getConnexionText(DateTime dateConnexion) {
    final now = DateTime.now();
    final difference = now.difference(dateConnexion);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateConnexion.day}/${dateConnexion.month}/${dateConnexion.year}';
    }
  }
}
