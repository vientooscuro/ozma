#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"
OZMADB_LOCAL_DIR="${OZMADB_LOCAL_DIR:-/Users/vientooscuro/SyncFolder/ozmadb}"
OZMADB_LOCAL_IMAGE="ghcr.io/vientooscuro/ozmadb:master"
OZMADB_BIN_PATH="$OZMADB_LOCAL_DIR/out/ozmadb/OzmaDB"
OZMADB_DOCKER_PLATFORM="${OZMADB_DOCKER_PLATFORM:-}"

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

require_cmd docker
require_cmd yarn
require_cmd file
require_cmd git

if [[ ! -d "$OZMADB_LOCAL_DIR" ]]; then
  echo "Error: local ozmadb directory not found: $OZMADB_LOCAL_DIR" >&2
  exit 1
fi

if [[ ! -f "$OZMADB_LOCAL_DIR/docker/Dockerfile" ]]; then
  echo "Error: Dockerfile not found: $OZMADB_LOCAL_DIR/docker/Dockerfile" >&2
  exit 1
fi

if [[ ! -d "$OZMADB_LOCAL_DIR/.git" ]]; then
  echo "Error: git repository not found: $OZMADB_LOCAL_DIR/.git" >&2
  exit 1
fi

if [[ ! -d "$OZMADB_LOCAL_DIR/out/ozmadb" ]]; then
  echo "Error: build output missing: $OZMADB_LOCAL_DIR/out/ozmadb" >&2
  echo "Build ozmadb binaries first, then re-run this script." >&2
  exit 1
fi

if [[ -z "$OZMADB_DOCKER_PLATFORM" ]]; then
  if [[ ! -f "$OZMADB_BIN_PATH" ]]; then
    echo "Error: OzmaDB binary not found: $OZMADB_BIN_PATH" >&2
    exit 1
  fi

  OZMADB_BIN_INFO="$(file -b "$OZMADB_BIN_PATH" | tr '[:upper:]' '[:lower:]')"
  if [[ "$OZMADB_BIN_INFO" == *"x86-64"* ]] || [[ "$OZMADB_BIN_INFO" == *"x86_64"* ]]; then
    OZMADB_DOCKER_PLATFORM="linux/amd64"
  elif [[ "$OZMADB_BIN_INFO" == *"aarch64"* ]] || [[ "$OZMADB_BIN_INFO" == *"arm64"* ]]; then
    OZMADB_DOCKER_PLATFORM="linux/arm64"
  else
    echo "Error: cannot detect OzmaDB binary architecture from: $OZMADB_BIN_INFO" >&2
    echo "Set OZMADB_DOCKER_PLATFORM manually (e.g. linux/amd64)." >&2
    exit 1
  fi
fi

log "Using OzmaDB platform: $OZMADB_DOCKER_PLATFORM"

log "Building local OzmaDB base image from $OZMADB_LOCAL_DIR..."
docker build \
  --platform "$OZMADB_DOCKER_PLATFORM" \
  -f "$OZMADB_LOCAL_DIR/docker/Dockerfile" \
  -t "$OZMADB_LOCAL_IMAGE" \
  "$OZMADB_LOCAL_DIR"

log "Reverting generated lockfile changes in ozmadb..."
git -C "$OZMADB_LOCAL_DIR" restore \
  OzmaDBSchema/packages.lock.json \
  OzmaUtils/packages.lock.json

log "Building frontend assets (yarn build)..."
yarn build

log "Building Docker images for ozmadb and ozma..."
DOCKER_DEFAULT_PLATFORM="$OZMADB_DOCKER_PLATFORM" docker compose build ozmadb
docker compose build ozma

log "Publishing changes and restarting containers..."
DOCKER_DEFAULT_PLATFORM="$OZMADB_DOCKER_PLATFORM" docker compose up -d --no-deps ozmadb
docker compose up -d --no-deps ozma

log "Current status:"
docker compose ps ozmadb ozma

log "Done."
