#!/bin/bash
# Pull latest backup from ozma.gogol.school and restore to local Docker ozma
set -euo pipefail

REMOTE=root@ozma.gogol.school
REMOTE_DIR=/root/backups/ozmadb
LOCAL_DIR="$HOME/backups/ozmadb"
POSTGRES_CONTAINER=ozma-postgres-1
OZMADB_CONTAINER=ozma-ozmadb-1

# Production origin that needs to be replaced for local use
PROD_ORIGIN="https://ozma.gogol.school"
LOCAL_ORIGIN="http://localhost:9080"

DOCKER=/usr/local/bin/docker

mkdir -p "$LOCAL_DIR"

echo "=== [1/5] Pulling backups from server ==="
rsync -avz --progress "$REMOTE:$REMOTE_DIR/" "$LOCAL_DIR/"

# Find latest dumps
LATEST_DB=$(ls -t "$LOCAL_DIR"/ozmadb_*.dump 2>/dev/null | head -1)
LATEST_KC=$(ls -t "$LOCAL_DIR"/keycloak_*.dump 2>/dev/null | head -1)

if [ -z "$LATEST_DB" ]; then
    echo "ERROR: No ozmadb dump found in $LOCAL_DIR"
    exit 1
fi

echo ""
echo "=== [2/5] Restoring ozmadb from: $(basename "$LATEST_DB") ==="

# Terminate active connections to ozmadb
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'ozmadb' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

# Stop ozmadb service to avoid reconnects during restore
$DOCKER stop "$OZMADB_CONTAINER" > /dev/null
echo "ozmadb container stopped"

# Drop and recreate database
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c "DROP DATABASE IF EXISTS ozmadb;" > /dev/null
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c "CREATE DATABASE ozmadb OWNER ozmadb;" > /dev/null
echo "Database recreated"

# Copy dump into container and restore (--jobs=4 for parallel restore)
echo "Copying dump into container..."
$DOCKER cp "$LATEST_DB" "$POSTGRES_CONTAINER":/tmp/ozmadb_restore.dump

# Pre-create extensions from dump as superuser (CREATE EXTENSION requires superuser)
echo "Pre-creating extensions..."
$DOCKER exec "$POSTGRES_CONTAINER" pg_restore --list /tmp/ozmadb_restore.dump \
    | awk '/EXTENSION -/ {print $NF}' \
    | while IFS= read -r ext; do
        if $DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -d ozmadb \
            -c "CREATE EXTENSION IF NOT EXISTS \"$ext\";" > /dev/null 2>&1; then
            echo "  + $ext"
        else
            echo "  ! $ext (failed, will retry in restore)"
        fi
    done

echo "Restoring (this may take a few minutes)..."
$DOCKER exec "$POSTGRES_CONTAINER" pg_restore \
    -U postgres \
    -d ozmadb \
    --jobs=4 \
    --no-owner \
    --no-privileges \
    --exit-on-error \
    /tmp/ozmadb_restore.dump
$DOCKER exec "$POSTGRES_CONTAINER" rm /tmp/ozmadb_restore.dump
echo "ozmadb restored!"

# Grant privileges to ozmadb user (lost due to --no-owner --no-privileges)
echo "Granting privileges and fixing ownership for ozmadb user..."
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -d ozmadb -c "
    GRANT ALL PRIVILEGES ON SCHEMA public TO ozmadb;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ozmadb;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ozmadb;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ozmadb;
    DO \$\$
    DECLARE s text;
    BEGIN
      FOR s IN
        SELECT schema_name FROM information_schema.schemata
        WHERE schema_name NOT IN ('pg_catalog','information_schema','pg_toast','public')
      LOOP
        -- Fix schema owner so ozmadb can CREATE OR REPLACE functions in it
        EXECUTE 'ALTER SCHEMA ' || quote_ident(s) || ' OWNER TO ozmadb';
        EXECUTE 'GRANT ALL PRIVILEGES ON SCHEMA ' || quote_ident(s) || ' TO ozmadb';
        EXECUTE 'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || quote_ident(s) || ' TO ozmadb';
        EXECUTE 'GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ' || quote_ident(s) || ' TO ozmadb';
        EXECUTE 'GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA ' || quote_ident(s) || ' TO ozmadb';
      END LOOP;
    END
    \$\$;
    -- Fix function ownership (required for CREATE OR REPLACE)
    DO \$\$
    DECLARE r record;
    BEGIN
      FOR r IN
        SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname NOT IN ('pg_catalog','information_schema')
          AND p.proowner != (SELECT oid FROM pg_roles WHERE rolname = 'ozmadb')
      LOOP
        EXECUTE 'ALTER FUNCTION ' || quote_ident(r.nspname) || '.' || quote_ident(r.proname) || '(' || r.args || ') OWNER TO ozmadb';
      END LOOP;
    END
    \$\$;
" > /dev/null
echo "Privileges and ownership fixed!"

echo ""
echo "=== [3/5] Restoring keycloak from: $(basename "$LATEST_KC") ==="

# Stop keycloak to avoid reconnects
$DOCKER stop ozma-keycloak-1 > /dev/null 2>&1 || true

$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'keycloak' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
# DROP and CREATE must be separate commands (not inside a transaction block)
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c "DROP DATABASE IF EXISTS keycloak;" > /dev/null
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -c "CREATE DATABASE keycloak OWNER keycloak;" > /dev/null

$DOCKER cp "$LATEST_KC" "$POSTGRES_CONTAINER":/tmp/keycloak_restore.dump
$DOCKER exec "$POSTGRES_CONTAINER" pg_restore \
    -U postgres \
    -d keycloak \
    --no-owner \
    --no-privileges \
    /tmp/keycloak_restore.dump
$DOCKER exec "$POSTGRES_CONTAINER" rm /tmp/keycloak_restore.dump

# Grant privileges to keycloak user (lost due to --no-owner --no-privileges)
echo "Granting keycloak privileges..."
$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -d keycloak -c "
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO keycloak;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO keycloak;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO keycloak;
" > /dev/null
echo "keycloak restored!"

echo ""
echo "=== [4/5] Patching keycloak URLs: $PROD_ORIGIN -> $LOCAL_ORIGIN ==="

$DOCKER exec "$POSTGRES_CONTAINER" psql -U postgres -d keycloak -c "
    -- Allow HTTP on localhost (production uses EXTERNAL which requires HTTPS)
    UPDATE realm SET ssl_required = 'NONE' WHERE id = 'ozma';

    -- Fix redirect URIs (ozma frontend and report-generator)
    UPDATE redirect_uris
       SET value = replace(value, '$PROD_ORIGIN', '$LOCAL_ORIGIN')
     WHERE value LIKE '%$PROD_ORIGIN%';

    -- Fix web origins (CORS)
    UPDATE web_origins
       SET value = replace(value, '$PROD_ORIGIN', '$LOCAL_ORIGIN')
     WHERE value LIKE '%$PROD_ORIGIN%';

    -- Fix root_url / base_url in client table (if any)
    UPDATE client
       SET root_url = replace(root_url, '$PROD_ORIGIN', '$LOCAL_ORIGIN')
     WHERE root_url LIKE '%$PROD_ORIGIN%';

    UPDATE client
       SET base_url = replace(base_url, '$PROD_ORIGIN', '$LOCAL_ORIGIN')
     WHERE base_url LIKE '%$PROD_ORIGIN%';

    -- Drop all active sessions so users log in fresh after restore
    DELETE FROM user_session;
    DELETE FROM client_session;
" 2>&1 | grep -v "^$"

echo "Keycloak URLs patched!"

echo ""
echo "=== [5/5] Starting services ==="
$DOCKER start ozma-keycloak-1 > /dev/null
$DOCKER start "$OZMADB_CONTAINER" > /dev/null
sleep 3
$DOCKER ps --filter "name=ozma-" --format "{{.Names}}: {{.Status}}"

echo ""
echo "=== Done! Local ozma is now synced with production ==="
echo "Backup date: $(basename "$LATEST_DB" | sed 's/ozmadb_//;s/.dump//')"
echo "Open: $LOCAL_ORIGIN"
