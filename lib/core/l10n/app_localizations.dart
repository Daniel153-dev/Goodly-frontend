import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire de localisation pour l'application GOODLY
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Charge les traductions depuis le fichier JSON
  Future<bool> load() async {
    String jsonString = await rootBundle.loadString(
      'assets/l10n/${locale.languageCode}.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  /// Traduit une clé
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// Traduit une clé avec des paramètres
  String translateWithParams(String key, Map<String, String> params) {
    String text = _localizedStrings[key] ?? key;
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value);
    });
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension pour faciliter l'accès aux traductions
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }

  String trParams(String key, Map<String, String> params) {
    return AppLocalizations.of(this)?.translateWithParams(key, params) ?? key;
  }
}

/// Provider pour gérer la langue de l'application
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('fr');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  /// Charge la langue sauvegardée
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  /// Change la langue de l'application
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Change la langue vers le français
  Future<void> setFrench() => setLocale(const Locale('fr'));

  /// Change la langue vers l'anglais
  Future<void> setEnglish() => setLocale(const Locale('en'));

  /// Bascule entre français et anglais
  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'fr') {
      await setEnglish();
    } else {
      await setFrench();
    }
  }

  /// Retourne true si la langue actuelle est le français
  bool get isFrench => _locale.languageCode == 'fr';

  /// Retourne true si la langue actuelle est l'anglais
  bool get isEnglish => _locale.languageCode == 'en';

  /// Retourne le nom de la langue actuelle
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }
}
