#!/bin/sh
set -e

if [ -z "$EXTERNAL_ORIGIN" ]; then
  if [ -n "$EXTERNAL_HOSTPORT" ]; then
    EXTERNAL_ORIGIN="${EXTERNAL_PROTOCOL:-http}://${EXTERNAL_HOSTPORT}"
  fi
fi

if [ -z "$KC_HOSTNAME" ]; then
  if [ -n "$EXTERNAL_ORIGIN" ]; then
    export KC_HOSTNAME="${EXTERNAL_ORIGIN}/auth"
  fi
fi

if [ -z "$KEYCLOAK_ADMIN" ]; then
  if [ -n "$ADMIN_EMAIL" ]; then
    export KEYCLOAK_ADMIN="$ADMIN_EMAIL"
  fi
fi

if [ -z "$KEYCLOAK_ADMIN_PASSWORD" ]; then
  if [ -n "$ADMIN_PASSWORD" ]; then
    export KEYCLOAK_ADMIN_PASSWORD="$ADMIN_PASSWORD"
  fi
fi

# The realm JSON was prepared by deploy.sh before docker compose up.
# Just copy it to the import directory.
mkdir -p /opt/keycloak/data/import
cp /etc/keycloak/realm.json /opt/keycloak/data/import/realm.json

exec /opt/keycloak/bin/kc.sh "$@"
