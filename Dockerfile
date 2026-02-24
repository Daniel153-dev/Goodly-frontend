# Dockerfile pour construire et déployer Flutter web sur Render
# Construction en deux étapes pour optimiser la taille
# Version 2 - Force rebuild

# Étape 1: Build Flutter
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.yaml pubspec.lock ./

# Installer les dépendances
RUN flutter pub get

# Copier le code source
COPY . .

# Construire l'application web en production
RUN flutter build web --release --dart-define=ENVIRONMENT=production

# Étape 2: Serveur nginx
FROM nginx:alpine

# Copier les fichiers buildés
COPY --from=build /app/build/web /usr/share/nginx/html

# Copier la configuration nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
