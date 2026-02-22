# GOODLY - Commandes de Build Flutter

Documentation des commandes pour builder l'application GOODLY en différents environnements et plateformes.

## Table des matières

- [Développement (Local)](#développement-local)
- [Production (AWS)](#production-aws)
- [Variables d'environnement](#variables-denvironnement)
- [Raccourcis Windows](#raccourcis-windows)

---

## Développement (Local)

### Web (Chrome)

```bash
flutter run -d chrome \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://goodly.abrdns.com
```

### Android (Émulateur)

L'émulateur Android utilise `10.0.2.2` comme alias pour `localhost` de la machine hôte.

```bash
flutter run -d emulator \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://goodly.abrdns.com
```

**Note:** L'API URL est automatiquement remplacée par `http://10.0.2.2:8000` dans le code pour l'émulateur Android.

### Android (Appareil physique via USB)

Pour un appareil physique connecté en USB, utilisez l'adresse IP locale de votre machine.

**Windows - Trouver votre IP locale:**
```bash
ipconfig
# Cherchez "Adresse IPv4" dans la section de votre carte réseau
```

**Commande de build:**
```bash
flutter run -d <DEVICE_ID> \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=http://192.168.X.X:8000
```

Remplacez `192.168.X.X` par votre IP locale.

### iOS (Simulateur)

```bash
flutter run -d simulator \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=https://goodly.abrdns.com
```

### iOS (Appareil physique)

```bash
flutter run -d <DEVICE_ID> \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_URL=http://192.168.X.X:8000
```

---

## Production (AWS)

### Variables requises

Pour les builds de production, vous devez fournir:
- `API_URL`: URL publique de votre serveur EC2 AWS
- `STRIPE_PUBLISHABLE_KEY`: Clé publique Stripe de production (optionnel en dev)

**Exemple:**
- API URL: `http://51.20.45.123:8000` (votre Elastic IP EC2)
- Stripe: `pk_live_xxxxxxxxxxxxx`

### Android APK (Production)

Build d'un APK pour distribution directe:

```bash
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=http://VOTRE_EC2_ELASTIC_IP:8000 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PROD
```

**Fichier généré:** `build\app\outputs\flutter-apk\app-release.apk`

### Android App Bundle (Google Play Store)

Build d'un App Bundle pour publication sur Google Play:

```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=http://VOTRE_EC2_ELASTIC_IP:8000 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PROD
```

**Fichier généré:** `build\app\outputs\bundle\release\app-release.aab`

### iOS (Production)

Build pour TestFlight ou App Store:

```bash
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=http://VOTRE_EC2_ELASTIC_IP:8000 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PROD
```

**Note:** Nécessite un Mac avec Xcode installé et un compte Apple Developer.

### Web (Production)

Build pour hébergement web (Firebase, Netlify, AWS S3, etc.):

```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=http://VOTRE_EC2_ELASTIC_IP:8000 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PROD
```

**Fichiers générés:** `build\web\`

---

## Variables d'environnement

### ENVIRONMENT

Détermine l'environnement d'exécution:
- `development` (défaut): Mode développement avec logs verbeux
- `production`: Mode production optimisé

### API_URL

URL de base de l'API backend:
- **Development:** `https://goodly.abrdns.com` (défaut)
- **Production:** URL publique de votre serveur EC2 AWS

**Important:** Incluez le port `:8000` dans l'URL.

### STRIPE_PUBLISHABLE_KEY

Clé publique Stripe pour les paiements:
- **Development:** Utilise automatiquement la clé de test
- **Production:** Doit être fournie via `--dart-define`

### DEBUG (optionnel)

Active/désactive les logs de debug:
- `true` (défaut en development)
- `false` (recommandé en production)

```bash
--dart-define=DEBUG=false
```

---

## Raccourcis Windows

Pour simplifier les builds, créez des fichiers `.bat` dans le dossier `scripts/`.

### `scripts/dev-web.bat`

```batch
@echo off
echo [GOODLY] Lancement en mode développement (Web)...
flutter run -d chrome --dart-define=ENVIRONMENT=development --dart-define=API_URL=https://goodly.abrdns.com
```

### `scripts/dev-android.bat`

```batch
@echo off
echo [GOODLY] Lancement en mode développement (Android Emulator)...
flutter run -d emulator --dart-define=ENVIRONMENT=development --dart-define=API_URL=https://goodly.abrdns.com
```

### `scripts/build-prod-apk.bat`

```batch
@echo off
echo [GOODLY] Build APK Production...
echo.
set /p API_URL="Entrez l'URL de l'API EC2 (ex: http://51.20.45.123:8000): "
set /p STRIPE_KEY="Entrez la clé Stripe (laisser vide pour test): "

if "%STRIPE_KEY%"=="" (
    set STRIPE_KEY=pk_test_51RpHMHDUKHeEZYpIwvWy7yaWCYVCLTtWacmQO8LC1Ars8Ebby2EgaBFzX4a9iyv8rJ5SdrbEbhhcAtgCBOYXuDb100tqdVgU3L
)

flutter build apk --release ^
  --dart-define=ENVIRONMENT=production ^
  --dart-define=API_URL=%API_URL% ^
  --dart-define=STRIPE_PUBLISHABLE_KEY=%STRIPE_KEY%

echo.
echo APK généré avec succès!
echo Emplacement: build\app\outputs\flutter-apk\app-release.apk
pause
```

**Utilisation:**
```bash
cd goodly_frontend\goodly_app\scripts
dev-web.bat
```

---

## Commandes utiles

### Vérifier les devices disponibles

```bash
flutter devices
```

### Nettoyer le projet

```bash
flutter clean
flutter pub get
```

### Analyser le code

```bash
flutter analyze
```

### Tester le build de production (sans signer)

```bash
flutter build apk --debug \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_URL=http://VOTRE_EC2_IP:8000
```

---

## Troubleshooting

### Erreur: "API_URL not defined"

**Solution:** Assurez-vous d'inclure tous les `--dart-define` dans la commande.

### Erreur: "Connection refused" en production

**Vérifications:**
1. L'URL EC2 est correcte et accessible
2. Le backend est démarré sur EC2
3. Le port 8000 est ouvert dans le Security Group EC2
4. CORS est configuré pour accepter les requêtes

### APK ne se connecte pas à l'API

**Vérifications:**
1. L'URL API dans le build inclut bien `http://` et le port `:8000`
2. Le firewall/antivirus ne bloque pas les connexions
3. Le backend log les requêtes (vérifier sur EC2: `sudo journalctl -u goodly-gateway -f`)

### Stripe ne fonctionne pas

**Vérifications:**
1. La clé Stripe est bien fournie au build
2. La clé est valide (commence par `pk_test_` ou `pk_live_`)
3. Le backend utilise la clé secrète correspondante (`sk_test_` ou `sk_live_`)

---

## Plus d'informations

- Documentation Flutter: https://docs.flutter.dev/deployment
- Stripe Flutter: https://pub.dev/packages/flutter_stripe
- Documentation AWS EC2: https://docs.aws.amazon.com/ec2/

---

**Auteur:** Claude Code
**Dernière mise à jour:** 2026-01-09
**Version GOODLY:** 1.0.0
