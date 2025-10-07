#!/usr/bin/env bash
set -euo pipefail

log(){ printf "\n\033[1;32m[init]\033[0m %s\n" "$*"; }
err(){ printf "\n\033[1;31m[err]\033[0m %s\n" "$*"; }

: "${WP_LOCALE:=en_US}"
: "${WP_TIMEZONE:=UTC}"
: "${WP_PERMALINKS:=/%postname%/}"
: "${WP_BLOG_PUBLIC:=1}"
: "${WP_PLUGINS:=}"
: "${WP_THEME:=}"
: "${WP_MEMORY_LIMIT:=256M}"

# Accept either WP_ADMIN_PASS or WP_ADMIN_PASSWORD
if [ -z "${WP_ADMIN_PASSWORD:-}" ] && [ -n "${WP_ADMIN_PASS:-}" ]; then
  export WP_ADMIN_PASSWORD="${WP_ADMIN_PASS}"
fi

need=(WORDPRESS_DB_HOST WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD WORDPRESS_DB_NAME WP_URL WP_TITLE WP_ADMIN_USER WP_ADMIN_PASSWORD WP_ADMIN_EMAIL)
missing=()
for v in "${need[@]}"; do [ -z "${!v:-}" ] && missing+=("$v"); done
if [ "${#missing[@]}" -gt 0 ]; then
  err "Missing required env: ${missing[*]}"
  err "Make sure wpcli loads .env (env_file: .env) or export them manually."
  exit 1
fi

cd /var/www/html

if [ ! -f wp-includes/version.php ]; then
  log "Downloading WordPress core (${WP_LOCALE})..."
  wp core download --locale="${WP_LOCALE}" --force
fi

if [ ! -f wp-config.php ]; then
  log "Creating wp-config.php..."
  wp config create \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --locale="${WP_LOCALE}" \
    --skip-check
  wp config set FS_METHOD direct --type=constant --raw
  wp config set WP_MEMORY_LIMIT "${WP_MEMORY_LIMIT}" --type=constant
  wp config shuffle-salts
fi

if wp core is-installed >/dev/null 2>&1; then
  log "Core already installed; skipping."
else
  log "Installing core..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"
fi

if ! wp language core is-installed "${WP_LOCALE}" >/dev/null 2>&1; then
  log "Installing language ${WP_LOCALE}..."
  wp language core install "${WP_LOCALE}"
fi
log "Switching language to ${WP_LOCALE}..."
wp site switch-language "${WP_LOCALE}"

log "Applying options..."
wp option update blog_public "${WP_BLOG_PUBLIC}"
wp option update timezone_string "${WP_TIMEZONE}"
wp rewrite structure "${WP_PERMALINKS}" --hard
wp rewrite flush --hard

# Clean demo content
#log "Cleaning default content..."
#wp post delete 1 --force 2>/dev/null || true
#wp post delete 2 --force 2>/dev/null || true
#wp comment delete $(wp comment list --format=ids) --force 2>/dev/null || true

if [ -n "${WP_PLUGINS// }" ]; then
  log "Installing plugins: ${WP_PLUGINS}"
  wp plugin install $(echo "$WP_PLUGINS" | tr ',' ' ') --activate
fi
if [ -n "${WP_THEME}" ]; then
  if wp theme is-installed "${WP_THEME}" >/dev/null 2>&1; then
    wp theme activate "${WP_THEME}"
  else
    wp theme install "${WP_THEME}" --activate
  fi
fi

log "Done. Site URL: $(wp option get siteurl)"
