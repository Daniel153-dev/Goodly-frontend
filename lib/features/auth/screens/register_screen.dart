import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/math_captcha.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../home/screens/home_screen.dart';

/// Mapping des codes pays ISO vers les noms de pays
const Map<String, String> countryCodeToName = {
  'AF': 'Afghanistan', 'AL': 'Albanie', 'DZ': 'Algérie', 'AD': 'Andorre',
  'AO': 'Angola', 'AR': 'Argentine', 'AM': 'Arménie', 'AU': 'Australie',
  'AT': 'Autriche', 'AZ': 'Azerbaïdjan', 'BH': 'Bahreïn', 'BD': 'Bangladesh',
  'BY': 'Biélorussie', 'BE': 'Belgique', 'BJ': 'Bénin', 'BT': 'Bhoutan',
  'BO': 'Bolivie', 'BA': 'Bosnie-Herzégovine', 'BW': 'Botswana', 'BR': 'Brésil',
  'BN': 'Brunei', 'BG': 'Bulgarie', 'BF': 'Burkina Faso', 'BI': 'Burundi',
  'KH': 'Cambodge', 'CM': 'Cameroun', 'CA': 'Canada', 'CV': 'Cap-Vert',
  'CF': 'Centrafrique', 'TD': 'Tchad', 'CL': 'Chili', 'CN': 'Chine',
  'CO': 'Colombie', 'KM': 'Comores', 'CG': 'Congo', 'CD': 'RD Congo',
  'CR': 'Costa Rica', 'CI': 'Côte d\'Ivoire', 'HR': 'Croatie', 'CU': 'Cuba',
  'CY': 'Chypre', 'CZ': 'Tchéquie', 'DK': 'Danemark', 'DJ': 'Djibouti',
  'DO': 'République Dominicaine', 'EC': 'Équateur', 'EG': 'Égypte',
  'SV': 'Salvador', 'GQ': 'Guinée Équatoriale', 'ER': 'Érythrée',
  'EE': 'Estonie', 'ET': 'Éthiopie', 'FJ': 'Fidji', 'FI': 'Finlande',
  'FR': 'France', 'GA': 'Gabon', 'GM': 'Gambie', 'GE': 'Géorgie',
  'DE': 'Allemagne', 'GH': 'Ghana', 'GR': 'Grèce', 'GT': 'Guatemala',
  'GN': 'Guinée', 'GW': 'Guinée-Bissau', 'GY': 'Guyana', 'HT': 'Haïti',
  'HN': 'Honduras', 'HU': 'Hongrie', 'IS': 'Islande', 'IN': 'Inde',
  'ID': 'Indonésie', 'IR': 'Iran', 'IQ': 'Irak', 'IE': 'Irlande',
  'IL': 'Israël', 'IT': 'Italie', 'JM': 'Jamaïque', 'JP': 'Japon',
  'JO': 'Jordanie', 'KZ': 'Kazakhstan', 'KE': 'Kenya', 'KW': 'Koweït',
  'KG': 'Kirghizistan', 'LA': 'Laos', 'LV': 'Lettonie', 'LB': 'Liban',
  'LS': 'Lesotho', 'LR': 'Liberia', 'LY': 'Libye', 'LI': 'Liechtenstein',
  'LT': 'Lituanie', 'LU': 'Luxembourg', 'MG': 'Madagascar', 'MW': 'Malawi',
  'MY': 'Malaisie', 'MV': 'Maldives', 'ML': 'Mali', 'MT': 'Malte',
  'MR': 'Mauritanie', 'MU': 'Maurice', 'MX': 'Mexique', 'MD': 'Moldavie',
  'MC': 'Monaco', 'MN': 'Mongolie', 'ME': 'Monténégro', 'MA': 'Maroc',
  'MZ': 'Mozambique', 'MM': 'Myanmar', 'NA': 'Namibie', 'NP': 'Népal',
  'NL': 'Pays-Bas', 'NZ': 'Nouvelle-Zélande', 'NI': 'Nicaragua', 'NE': 'Niger',
  'NG': 'Nigeria', 'NO': 'Norvège', 'OM': 'Oman', 'PK': 'Pakistan',
  'PA': 'Panama', 'PG': 'Papouasie-Nouvelle-Guinée', 'PY': 'Paraguay',
  'PE': 'Pérou', 'PH': 'Philippines', 'PL': 'Pologne', 'PT': 'Portugal',
  'QA': 'Qatar', 'RO': 'Roumanie', 'RU': 'Russie', 'RW': 'Rwanda',
  'SA': 'Arabie Saoudite', 'SN': 'Sénégal', 'RS': 'Serbie', 'SL': 'Sierra Leone',
  'SG': 'Singapour', 'SK': 'Slovaquie', 'SI': 'Slovénie', 'SO': 'Somalie',
  'ZA': 'Afrique du Sud', 'KR': 'Corée du Sud', 'ES': 'Espagne',
  'LK': 'Sri Lanka', 'SD': 'Soudan', 'SR': 'Suriname', 'SZ': 'Eswatini',
  'SE': 'Suède', 'CH': 'Suisse', 'SY': 'Syrie', 'TW': 'Taïwan',
  'TJ': 'Tadjikistan', 'TZ': 'Tanzanie', 'TH': 'Thaïlande', 'TG': 'Togo',
  'TN': 'Tunisie', 'TR': 'Turquie', 'TM': 'Turkménistan', 'UG': 'Ouganda',
  'UA': 'Ukraine', 'AE': 'Émirats Arabes Unis', 'GB': 'Royaume-Uni',
  'US': 'États-Unis', 'UY': 'Uruguay', 'UZ': 'Ouzbékistan', 'VE': 'Venezuela',
  'VN': 'Vietnam', 'YE': 'Yémen', 'ZM': 'Zambie', 'ZW': 'Zimbabwe',
};

/// Écran d'inscription
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captchaKey = GlobalKey<MathCaptchaState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCaptchaValid = false;

  String? _phoneNumber;
  String _countryCode = 'CM'; // Cameroun par défaut
  String _countryName = 'Cameroun'; // Nom du pays
  String? _selectedSexe; // 'homme' ou 'femme'
  DateTime? _selectedBirthDate; // Date de naissance

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier le CAPTCHA
    if (!_isCaptchaValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('captcha_required')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Vérifier la date de naissance
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('birth_date_required')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await authProvider.inscription(
      nomUtilisateur: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      motDePasse: _passwordController.text,
      numeroTelephone: _phoneNumber ?? '',
      codePays: _countryCode,
      pays: _countryName,
      dateNaissance: _selectedBirthDate,
      sexe: _selectedSexe,
      biographie: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Navigation vers la page d'accueil
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // Réinitialiser le CAPTCHA en cas d'erreur
      _captchaKey.currentState?.refresh();

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.tr('register_failed')),
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
      appBar: AppBar(
        title: Text(context.tr('register_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.favorite,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // Titre
                Text(
                  context.tr('register_title'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Sous-titre
                Text(
                  context.tr('register_subtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Nom d'utilisateur
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('username'),
                    hintText: context.tr('username_hint'),
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('username_required');
                    }
                    if (value.length < 3) {
                      return context.tr('username_min_length');
                    }
                    if (value.length > 50) {
                      return context.tr('username_max_length');
                    }
                    // Autoriser seulement lettres, chiffres, underscore et tiret
                    final allowedChars = RegExp(r'^[a-zA-Z0-9_-]+$');
                    if (!allowedChars.hasMatch(value)) {
                      return context.tr('username_invalid_chars');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Numéro de téléphone
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: '${context.tr('phone_number')} *',
                    hintText: '655 20 51 36',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  initialCountryCode: _countryCode,
                  onChanged: (phone) {
                    setState(() {
                      _phoneNumber = phone.completeNumber;
                      _countryCode = phone.countryISOCode;
                      _countryName = countryCodeToName[phone.countryISOCode] ?? phone.countryISOCode;
                    });
                  },
                  onCountryChanged: (country) {
                    setState(() {
                      _countryCode = country.code;
                      _countryName = countryCodeToName[country.code] ?? country.name;
                    });
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return context.tr('phone_required');
                    }
                    if (phone.number.length < 8) {
                      return context.tr('phone_invalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pays (affiché automatiquement)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('country_auto'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _countryName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Date de naissance
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Minimum 13 ans
                      helpText: context.tr('birth_date_required'),
                      cancelText: context.tr('cancel'),
                      confirmText: context.tr('confirm'),
                      builder: (context, child) {
                        return Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(
                              primary: theme.colorScheme.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && picked != _selectedBirthDate) {
                      setState(() {
                        _selectedBirthDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '${context.tr('birth_date')} *',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedBirthDate != null
                          ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedBirthDate!)
                          : context.tr('select_date'),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedBirthDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sexe
                DropdownButtonFormField<String>(
                  value: _selectedSexe,
                  decoration: InputDecoration(
                    labelText: '${context.tr('gender')} *',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'homme',
                      child: Text(context.tr('male')),
                    ),
                    DropdownMenuItem(
                      value: 'femme',
                      child: Text(context.tr('female')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSexe = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('gender_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    hintText: context.tr('email_hint'),
                    prefixIcon: const Icon(Icons.email_outlined),
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
                      return context.tr('too_long');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    hintText: context.tr('password_hint'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
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
                    if (value.length < 8) {
                      return context.tr('password_min_length');
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return context.tr('password_uppercase');
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return context.tr('password_lowercase');
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return context.tr('password_digit');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('confirm_password'),
                    hintText: context.tr('password_hint'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return context.tr('password_mismatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Biographie (optionnel)
                TextFormField(
                  controller: _bioController,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: context.tr('biography_optional'),
                    hintText: context.tr('biography_hint'),
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // CAPTCHA - Vérification humaine
                MathCaptcha(
                  key: _captchaKey,
                  onValidated: (isValid) {
                    setState(() {
                      _isCaptchaValid = isValid;
                    });
                  },
                  onRefresh: () {
                    setState(() {
                      _isCaptchaValid = false;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Bouton d'inscription
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: context.tr('register_button'),
                    onPressed: _handleRegister,
                    isLoading: authProvider.isLoading,
                  ),
                ),
                const SizedBox(height: 16),

                // Retour à la connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${context.tr('already_account')} ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.tr('sign_in')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
