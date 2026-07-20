#!/usr/bin/env bash
#
# SecureCity AI — one-time Let's Encrypt bootstrap for a FRESH deployment.
#
# Problem this solves: the `certbot` service in docker-compose.yml only
# RENEWS existing certificates (`certbot renew` in a loop) — it never
# performs the initial issuance. nginx.conf also expects a real cert to
# already exist at /etc/letsencrypt/live/<domain>/... before it can even
# start (`ssl_certificate`/`ssl_certificate_key`), which is a chicken-and-
# egg problem on a brand-new host. This script breaks that cycle using the
# standard approach: boot nginx with a temporary self-signed cert just long
# enough to serve the ACME HTTP-01 challenge, request the real certificate,
# then reload nginx with it.
#
# Not run automatically by docker-compose — this is a manual, one-time
# step an operator runs after `docker compose up -d` on a fresh host (or
# whenever the domain changes). Subsequent renewals are handled by the
# existing `certbot` service.
#
# Usage:
#   DOMAIN=ai.securecity.example.com EMAIL=ops@securecity.example.com \
#     ./infrastructure/init-letsencrypt.sh
#
# Requires: docker compose, run from the repository root.

set -euo pipefail

DOMAIN="${DOMAIN:-ai.securecity.example.com}"
EMAIL="${EMAIL:-}"
RSA_KEY_SIZE=4096

if [ -z "${EMAIL}" ]; then
  echo "[init-letsencrypt] EMAIL is required (used for Let's Encrypt expiry notices)." >&2
  echo "  Usage: DOMAIN=... EMAIL=... ./infrastructure/init-letsencrypt.sh" >&2
  exit 1
fi

echo "[init-letsencrypt] Domain:      ${DOMAIN}"
echo "[init-letsencrypt] Contact:     ${EMAIL}"

echo "[init-letsencrypt] Step 1/5 — creating a dummy self-signed certificate"
echo "  so nginx has something to bind to at startup..."
docker compose run --rm --entrypoint "\
  mkdir -p /etc/letsencrypt/live/${DOMAIN} && \
  openssl req -x509 -nodes -newkey rsa:${RSA_KEY_SIZE} -days 1 \
    -keyout '/etc/letsencrypt/live/${DOMAIN}/privkey.pem' \
    -out '/etc/letsencrypt/live/${DOMAIN}/fullchain.pem' \
    -subj '/CN=localhost' && \
  cp '/etc/letsencrypt/live/${DOMAIN}/fullchain.pem' '/etc/letsencrypt/live/${DOMAIN}/chain.pem'" certbot

echo "[init-letsencrypt] Step 2/5 — starting nginx with the dummy certificate"
docker compose up -d nginx

echo "[init-letsencrypt] Step 3/5 — deleting the dummy certificate"
docker compose run --rm --entrypoint "\
  rm -rf /etc/letsencrypt/live/${DOMAIN} && \
  rm -rf /etc/letsencrypt/archive/${DOMAIN} && \
  rm -rf /etc/letsencrypt/renewal/${DOMAIN}.conf" certbot

echo "[init-letsencrypt] Step 4/5 — requesting the real Let's Encrypt certificate"
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    --email '${EMAIL}' -d '${DOMAIN}' \
    --rsa-key-size ${RSA_KEY_SIZE} --agree-tos --no-eff-email" certbot

echo "[init-letsencrypt] Step 5/5 — reloading nginx with the real certificate"
docker compose exec nginx nginx -s reload

echo "[init-letsencrypt] Done. ${DOMAIN} is now serving a real Let's Encrypt certificate."
echo "  The 'certbot' service will keep it renewed automatically."
