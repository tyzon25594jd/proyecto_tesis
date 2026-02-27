#!/bin/bash
# Script para obtener el certificado SSL por primera vez.
# Ejecutar UNA SOLA VEZ antes de levantar los servicios normalmente.
#
# Uso:
#   chmod +x init-ssl.sh
#   ./init-ssl.sh

DOMAIN="investiup.com"
EMAIL="tyzonperu@gmail.com"

set -e

echo "==> Creando carpetas para certbot..."
mkdir -p ./certbot/conf ./certbot/www

echo "==> Levantando nginx temporal (solo HTTP) para validar el dominio..."
docker run --rm -d \
    --name nginx-temp \
    -p 80:80 \
    -v "$(pwd)/certbot/www:/var/www/certbot" \
    nginx:alpine \
    sh -c 'echo "server { listen 80; location /.well-known/acme-challenge/ { root /var/www/certbot; } }" > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'

echo "==> Obteniendo certificado SSL para $DOMAIN..."
docker run --rm \
    -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
    -v "$(pwd)/certbot/www:/var/www/certbot" \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

echo "==> Deteniendo nginx temporal..."
docker stop nginx-temp

echo ""
echo "Certificado obtenido correctamente."
echo "Ahora ejecuta: docker compose up -d --build"
