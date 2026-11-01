#!/bin/sh
# Moves the postgres_data volume from an older PostgreSQL to the one in
# docker-compose.yml: pg_dumpall with the old version, restore into a fresh cluster.
# Run once from the repository root after git pull.
#
# While restoring, the old files sit in the volume under upgrade-in-progress/; once
# the restore is done they become <old major>-old/ and stay until removed by hand.
# If a run breaks off, the next one puts the old files back and starts over.
set -euC
umask 077

TARGET=18
IN_PROGRESS=upgrade-in-progress

backup_dir=${PG_UPGRADE_BACKUP_DIR:-$HOME/postgres-upgrade-backups}
mkdir -p "$backup_dir"
backup_dir=$(cd "$backup_dir" && pwd -P)
repo_dir=$(pwd -P)
case "$backup_dir/" in
  "$repo_dir/"*)
    echo "The backup directory must be outside the repository: $backup_dir" >&2
    exit 1
    ;;
esac

project=$(docker compose config | sed -n 's/^name: //p' | head -n 1)
volume=$(docker volume ls -q \
  --filter "label=com.docker.compose.project=$project" \
  --filter "label=com.docker.compose.volume=postgres_data")
if [ -z "$volume" ]; then
  echo "No postgres_data volume for project $project, nothing to upgrade." >&2
  exit 1
fi
DUMP_CONTAINER=$project-pg-upgrade-dump
RESTORE_CONTAINER=$project-pg-upgrade-restore

# Runs a shell command in the root of the volume.
in_volume() {
  docker run --rm -u 0 -v "$volume:/v" -w /v --entrypoint sh "postgres:$TARGET" -c "$1"
}

# Before 18 the data sits in the root of the volume, from 18 on in <major>/docker.
if in_volume "[ -d $IN_PROGRESS ]"; then
  resume=1
elif in_volume '[ -f PG_VERSION ]'; then
  resume=
else
  echo "$volume is already on PostgreSQL $TARGET or newer, nothing to do."
  exit 0
fi

cleanup() { docker rm -f "$DUMP_CONTAINER" "$RESTORE_CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

# Over TCP: during initialization the entrypoint runs a temporary server on the
# socket only, and stops it before the real start.
wait_ready() {
  waited=0
  until docker exec "$1" pg_isready -h 127.0.0.1 -U postgres -q 2>/dev/null; do
    if [ "$(docker inspect -f '{{.State.Running}}' "$1")" != true ]; then
      docker logs --tail 20 "$1" >&2
      echo "$1 has stopped." >&2
      exit 1
    fi
    waited=$((waited + 1))
    if [ "$waited" -ge 300 ]; then
      echo "$1 is not ready after 5 minutes." >&2
      exit 1
    fi
    sleep 1
  done
}

docker compose down
# Left over from a run that broke off: nothing may use the volume during the rollback.
cleanup

if [ -n "$resume" ]; then
  echo "The previous run did not finish: putting the old files back."
  in_volume "rm -rf $TARGET
    find $IN_PROGRESS -mindepth 1 -maxdepth 1 -exec mv {} . ';'
    rmdir $IN_PROGRESS"
fi

old=$(in_volume 'cat PG_VERSION')
echo "Upgrading $volume: PostgreSQL $old -> $TARGET"

dump="$backup_dir/postgres-$old-$(date +%Y%m%d-%H%M%S)-$$.sql.gz"
docker run -d --name "$DUMP_CONTAINER" -v "$volume:/var/lib/postgresql/data" "postgres:$old" >/dev/null
wait_ready "$DUMP_CONTAINER"
docker exec "$DUMP_CONTAINER" pg_dumpall -U postgres | gzip >"$dump"
docker rm -f "$DUMP_CONTAINER" >/dev/null
# sh has no pipefail: a dump that broke off has no closing line.
if ! gzip -dc "$dump" | tail -n 5 | grep -q 'cluster dump complete'; then
  echo "The dump is incomplete, the volume is left as it was." >&2
  exit 1
fi
echo "Dump: $dump"

# A failed start of postgres:18 on the old volume leaves empty $TARGET/docker behind.
in_volume "[ ! -d $TARGET ] || find $TARGET -depth -type d -empty -delete
  [ ! -e $TARGET ] || { echo '$TARGET/ in the volume is not empty.' >&2; exit 1; }
  mkdir $IN_PROGRESS
  find . -mindepth 1 -maxdepth 1 ! -name $IN_PROGRESS -exec mv {} $IN_PROGRESS/ ';'"

# Without the init script: the dump brings its own roles and databases.
docker run -d --name "$RESTORE_CONTAINER" -v "$volume:/var/lib/postgresql" \
  -e POSTGRES_PASSWORD=postgres "postgres:$TARGET" \
  -c shared_preload_libraries=pg_stat_statements >/dev/null
wait_ready "$RESTORE_CONTAINER"
# The fresh cluster already has its superuser. Keep identical lines in COPY data.
gzip -dc "$dump" | awk '$0 == "CREATE ROLE postgres;" && !skipped { skipped=1; next } { print }' |
  docker exec -i "$RESTORE_CONTAINER" psql -U postgres -X -q -v ON_ERROR_STOP=1 -d postgres >/dev/null
docker exec "$RESTORE_CONTAINER" vacuumdb -U postgres -q --all --analyze-only
docker stop "$RESTORE_CONTAINER" >/dev/null

in_volume "mv $IN_PROGRESS $old-old"

docker compose up -d
echo "Done. Once everything works:"
echo "  Remove dump after verification: $dump"
echo "  docker run --rm -v $volume:/v alpine rm -rf /v/$old-old"
