# Dockerfile optimisé pour déploiement rapide
# Utilise les fichiers pré-construits (build/web doit exister)

FROM nginx:alpine

# Copier les fichiers buildés (doivent être dans build/web/)
COPY build/web /usr/share/nginx/html

# Copier la configuration nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
