# Dockerfile pour builder et servir Flutter Web
FROM ghcr.io/cirruslabs/flutter:3.27.0 AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.yaml pubspec.lock ./

# Installer les dépendances
RUN flutter pub get

# Copier le reste du code
COPY . .

# Builder l'application web
RUN flutter build web --release --dart-define=ENVIRONMENT=production

# Étape de production avec nginx
FROM nginx:alpine

# Copier les fichiers buildés
COPY --from=build /app/build/web /usr/share/nginx/html

# Copier la configuration nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
