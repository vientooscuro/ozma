#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
info() { echo -e "$*"; }

# Run a command locally or on the remote server
run_on_server() {
  if [[ "$DEPLOY_MODE" == "remote" ]]; then
    ssh "$DEPLOY_HOST" "$@"
  else
    bash -c "$*"
  fi
}

# Run a multi-line script on server (passes via stdin)
run_script_on_server() {
  if [[ "$DEPLOY_MODE" == "remote" ]]; then
    ssh "$DEPLOY_HOST" bash -s
  else
    bash
  fi
}

# Defaults
DEPLOY_MODE=""       # "remote" or "local"
DEPLOY_HOST=""
ENV_FILE=""
DOMAIN=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
OZMA_USER_EMAIL=""
OZMA_USER_PASSWORD=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)      DEPLOY_MODE="remote"; [[ -n "${2:-}" ]] || fail "--remote requires a host argument (user@host)"; DEPLOY_HOST="$2"; shift 2 ;;
    --local)       DEPLOY_MODE="local"; shift ;;
    --env)         [[ -n "${2:-}" ]] || fail "--env requires a file path"; ENV_FILE="$2"; shift 2 ;;
    --domain)      [[ -n "${2:-}" ]] || fail "--domain requires a domain name"; DOMAIN="$2"; shift 2 ;;
    --admin-email) [[ -n "${2:-}" ]] || fail "--admin-email requires an email address"; ADMIN_EMAIL="$2"; shift 2 ;;
    --admin-password) [[ -n "${2:-}" ]] || fail "--admin-password requires a password"; ADMIN_PASSWORD="$2"; shift 2 ;;
    --ozma-email)  [[ -n "${2:-}" ]] || fail "--ozma-email requires an email address"; OZMA_USER_EMAIL="$2"; shift 2 ;;
    --ozma-password) [[ -n "${2:-}" ]] || fail "--ozma-password requires a password"; OZMA_USER_PASSWORD="$2"; shift 2 ;;
    *) fail "Unknown argument: $1" ;;
  esac
done

# Load .env file if provided or auto-detect
if [[ -z "$ENV_FILE" && -f ".env" ]]; then
  ENV_FILE=".env"
fi

if [[ -n "$ENV_FILE" ]]; then
  [[ -f "$ENV_FILE" ]] || fail ".env file not found: $ENV_FILE"
  # Load vars not already set from CLI
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    value="${value%%#*}"   # strip inline comments
    value="${value%"${value##*[![:space:]]}"}"  # trim trailing whitespace
    value="${value#\"}"; value="${value%\"}"     # strip surrounding double quotes
    value="${value#\'}"; value="${value%\'}"     # strip surrounding single quotes
    # Only set if not already set via CLI
    case "$key" in
      DEPLOY_HOST)        [[ -z "$DEPLOY_HOST" ]]        && DEPLOY_HOST="$value" ;;
      DOMAIN)             [[ -z "$DOMAIN" ]]             && DOMAIN="$value" ;;
      ADMIN_EMAIL)        [[ -z "$ADMIN_EMAIL" ]]        && ADMIN_EMAIL="$value" ;;
      ADMIN_PASSWORD)     [[ -z "$ADMIN_PASSWORD" ]]     && ADMIN_PASSWORD="$value" ;;
      OZMA_USER_EMAIL)    [[ -z "$OZMA_USER_EMAIL" ]]    && OZMA_USER_EMAIL="$value" ;;
      OZMA_USER_PASSWORD) [[ -z "$OZMA_USER_PASSWORD" ]] && OZMA_USER_PASSWORD="$value" ;;
    esac
  done < "$ENV_FILE"
fi

# If DEPLOY_HOST is set in env and mode not set, default to remote
if [[ -z "$DEPLOY_MODE" && -n "$DEPLOY_HOST" ]]; then
  DEPLOY_MODE="remote"
fi

# Interactive prompts for missing required variables
prompt_if_missing() {
  local varname="$1"
  local prompt="$2"
  local secret="${3:-false}"
  if [[ -z "${!varname}" ]]; then
    if [[ -t 0 ]]; then
      if [[ "$secret" == "true" ]]; then
        read -rsp "$prompt: " value; echo
      else
        read -rp "$prompt: " value
      fi
      printf -v "$varname" '%s' "$value"
    fi
  fi
}

prompt_if_missing DEPLOY_MODE      "Mode (remote/local)"
if [[ "${DEPLOY_MODE}" == "remote" ]]; then
  prompt_if_missing DEPLOY_HOST "SSH target (user@host)"
fi
prompt_if_missing DOMAIN           "Domain (e.g. example.com)"
prompt_if_missing ADMIN_EMAIL      "Keycloak admin email"
prompt_if_missing ADMIN_PASSWORD   "Keycloak admin password" true
prompt_if_missing OZMA_USER_EMAIL  "ozma user email"
prompt_if_missing OZMA_USER_PASSWORD "ozma user password" true

# Validate all required variables are set
validate_required() {
  local missing=()
  [[ -z "$DEPLOY_MODE" ]]         && missing+=("--local or --remote user@host")
  [[ -z "$DOMAIN" ]]              && missing+=("--domain / DOMAIN")
  [[ -z "$ADMIN_EMAIL" ]]         && missing+=("--admin-email / ADMIN_EMAIL")
  [[ -z "$ADMIN_PASSWORD" ]]      && missing+=("--admin-password / ADMIN_PASSWORD")
  [[ -z "$OZMA_USER_EMAIL" ]]     && missing+=("--ozma-email / OZMA_USER_EMAIL")
  [[ -z "$OZMA_USER_PASSWORD" ]]  && missing+=("--ozma-password / OZMA_USER_PASSWORD")
  if [[ "$DEPLOY_MODE" == "remote" && -z "$DEPLOY_HOST" ]]; then
    missing+=("SSH target (user@host) for --remote")
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing required configuration:${NC}"
    for m in "${missing[@]}"; do echo "  - $m"; done
    exit 1
  fi
}

validate_required

stage_preflight() {
  info "\n==> Stage 1: Preflight"

  if [[ "$DEPLOY_MODE" == "remote" ]]; then
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$DEPLOY_HOST" 'echo ok' > /dev/null 2>&1 \
      || fail "Cannot connect to $DEPLOY_HOST via SSH. Check your SSH config."
    ok "SSH connection to $DEPLOY_HOST"
  else
    ok "Local mode — no SSH needed"
  fi

  command -v curl > /dev/null || fail "curl is required on the local machine"
  ok "Preflight complete"
}

stage_preflight

stage_docker_install() {
  info "\n==> Stage 2: Docker install"

  if run_on_server 'command -v docker > /dev/null 2>&1'; then
    skip "Docker already installed"
    return
  fi

  info "Installing Docker..."
  run_on_server 'curl -fsSL https://get.docker.com | sh'

  # Add current user to docker group (so docker can be run without sudo)
  run_on_server 'sudo usermod -aG docker "$USER" || true'

  # Re-check
  run_on_server 'command -v docker > /dev/null 2>&1' \
    || fail "Docker installation failed"

  ok "Docker installed"
}

stage_docker_install

REPO_URL="https://github.com/vientooscuro/ozma.git"

stage_deploy_repo() {
  info "\n==> Stage 3: Deploy repo"

  if [[ "$DEPLOY_MODE" == "remote" ]]; then
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    info "Pushing branch '$current_branch' to origin..."
    git push origin "$current_branch" \
      || fail "git push failed. Make sure you have push access."
    ok "Pushed to origin"
  fi

  run_script_on_server << 'REMOTE_SCRIPT'
    set -euo pipefail
    if [ -d "$HOME/ozma/.git" ]; then
      echo "Repo exists, pulling..."
      git -C "$HOME/ozma" pull
    else
      echo "Cloning repo..."
      git clone https://github.com/vientooscuro/ozma.git "$HOME/ozma"
    fi
REMOTE_SCRIPT

  ok "Repo deployed"
}

stage_deploy_repo

stage_write_env() {
  info "\n==> Stage 4: Env setup"

  local env_content
  env_content="ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
CADDY_ADDRESS=${DOMAIN}
EXTERNAL_ORIGIN=https://${DOMAIN}
HTTP_PORT=80
HTTPS_PORT=443"

  if [[ "$DEPLOY_MODE" == "remote" ]]; then
    ssh "$DEPLOY_HOST" "cat > \$HOME/ozma/.env" <<< "$env_content"
  else
    echo "$env_content" > "$HOME/ozma/.env"
  fi

  ok ".env written to ~/ozma/.env"
}

stage_write_env
