#!/usr/bin/env bash
# Install NzbDav + Rclone on Ubuntu / CasaOS / ZimaOS with one command.
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/killamfkr/nzbdav/main/scripts/install-casaos.sh | sudo bash
#
# Non-interactive (set all required variables):
#   curl -fsSL ... | sudo NZBDAV_ADMIN_PASS='secret' NZBDAV_WEBDAV_PASS='secret' \
#     USENET_HOST='news.example.com' USENET_USER='user' USENET_PASS='pass' bash
#
# Options:
#   --uninstall   Stop containers and remove install files (keeps /DATA/AppData/nzbdav/config unless --purge)
#   --purge       With --uninstall, also delete config and credentials
#   -y            Accept defaults where possible (still requires passwords via env vars in non-interactive mode)

set -euo pipefail

NZBDAV_VERSION="${NZBDAV_VERSION:-0.6.4}"
RCLONE_VERSION="${RCLONE_VERSION:-1.74.3}"
WEBUI_PORT="${WEBUI_PORT:-3000}"
INSTALL_DIR="${INSTALL_DIR:-/DATA/AppData/nzbdav}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-nzbdav}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}==>${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

UNINSTALL=false
PURGE=false
ASSUME_YES=false

for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=true ;;
    --purge) PURGE=true ;;
    -y|--yes) ASSUME_YES=true ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

rand_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 16
  else
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

prompt() {
  local var_name="$1"
  local prompt_text="$2"
  local default="${3:-}"
  local secret="${4:-false}"
  local value=""

  if [[ -n "${!var_name:-}" ]]; then
    return 0
  fi

  if [[ "$ASSUME_YES" == true && -n "$default" ]]; then
    printf -v "$var_name" '%s' "$default"
    return 0
  fi

  if [[ "$secret" == true ]]; then
    read -r -s -p "$prompt_text: " value
    echo
  else
    read -r -p "$prompt_text${default:+ [$default]}: " value
  fi

  if [[ -z "$value" && -n "$default" ]]; then
    value="$default"
  fi

  [[ -n "$value" ]] || die "No value provided for $var_name"
  printf -v "$var_name" '%s' "$value"
}

detect_ids() {
  if [[ -n "${PUID:-}" && -n "${PGID:-}" ]]; then
    export PUID PGID
    return
  fi

  local user=""
  local candidates=()

  [[ -n "${SUDO_USER:-}" ]] && candidates+=("$SUDO_USER")
  [[ -n "${LOGNAME:-}" ]] && candidates+=("$LOGNAME")
  candidates+=("$(stat -c '%U' /DATA 2>/dev/null || true)")
  candidates+=("$(stat -c '%U' /DATA/AppData 2>/dev/null || true)")
  candidates+=("casaos" "tower" "ubuntu")

  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && "$candidate" != "root" ]] && id "$candidate" >/dev/null 2>&1; then
      user="$candidate"
      break
    fi
  done

  if [[ -n "$user" ]]; then
    PUID="$(id -u "$user")"
    PGID="$(id -g "$user")"
  else
    PUID=1000
    PGID=1000
  fi

  if [[ "$PUID" -eq 0 ]]; then
    PUID=1000
    PGID=1000
  fi

  export PUID PGID
}

detect_tz() {
  if [[ -z "${TZ:-}" ]]; then
    if [[ -f /etc/timezone ]]; then
      TZ="$(cat /etc/timezone)"
    else
      TZ="UTC"
    fi
  fi
  export TZ
}

ensure_docker() {
  need_cmd docker
  if ! docker info >/dev/null 2>&1; then
    die "Docker is not running or this user cannot access it. Try: sudo bash"
  fi
  if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
  else
    die "Docker Compose is not installed"
  fi
}

uninstall() {
  detect_ids
  ensure_docker
  log "Stopping NzbDav stack..."
  if [[ -f "$INSTALL_DIR/docker-compose.yml" ]]; then
    (cd "$INSTALL_DIR" && "${COMPOSE[@]}" -p "$COMPOSE_PROJECT_NAME" down --remove-orphans) || true
  else
    docker rm -f nzbdav nzbdav_rclone 2>/dev/null || true
  fi

  if [[ "$PURGE" == true ]]; then
    warn "Removing $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    rm -rf /DATA/remote/nzbdav 2>/dev/null || true
  else
    ok "Containers removed. Config kept at $INSTALL_DIR/config"
    ok "Run with --purge to delete config too."
  fi
  exit 0
}

[[ "$UNINSTALL" == true ]] && uninstall

if [[ "$(id -u)" -ne 0 ]]; then
  warn "Not running as root. Re-running with sudo..."
  exec sudo -E bash "$0" "$@"
fi

detect_ids
detect_tz
ensure_docker

if [[ ! -d /DATA ]]; then
  warn "/DATA not found (not a standard CasaOS install). Using $INSTALL_DIR anyway."
  mkdir -p "$(dirname "$INSTALL_DIR")"
fi

mkdir -p "$INSTALL_DIR/config" /DATA/remote/nzbdav

log "NzbDav installer for Ubuntu / CasaOS / ZimaOS"
echo "  Install dir : $INSTALL_DIR"
echo "  Web UI port : $WEBUI_PORT"
echo "  PUID/PGID   : $PUID/$PGID"
echo "  Timezone    : $TZ"
if [[ -n "${SUDO_USER:-}" ]]; then
  echo "  Run as user : $SUDO_USER (via sudo)"
fi
echo

# Credentials
NZBDAV_ADMIN_USER="${NZBDAV_ADMIN_USER:-admin}"
NZBDAV_WEBDAV_USER="${NZBDAV_WEBDAV_USER:-admin}"

prompt NZBDAV_ADMIN_PASS "Admin password (web UI login)" "" true
if [[ -z "${NZBDAV_WEBDAV_PASS:-}" ]]; then
  if [[ "$ASSUME_YES" == true ]]; then
    NZBDAV_WEBDAV_PASS="$NZBDAV_ADMIN_PASS"
  else
    read -r -p "WebDAV password [same as admin]: " _webdav_reply
    NZBDAV_WEBDAV_PASS="${_webdav_reply:-$NZBDAV_ADMIN_PASS}"
  fi
fi

FRONTEND_BACKEND_API_KEY="${FRONTEND_BACKEND_API_KEY:-$(rand_hex)}"

# Usenet (optional but recommended)
if [[ -z "${USENET_HOST:-}" ]]; then
  if [[ "$ASSUME_YES" == true ]]; then
    USENET_HOST=""
  else
    read -r -p "Usenet host (leave blank to skip for now): " USENET_HOST
  fi
fi

if [[ -n "${USENET_HOST:-}" ]]; then
  USENET_PORT="${USENET_PORT:-563}"
  USENET_SSL="${USENET_SSL:-true}"
  USENET_MAX_CONN="${USENET_MAX_CONN:-100}"
  prompt USENET_USER "Usenet username"
  prompt USENET_PASS "Usenet password" "" true
fi

log "Generating rclone.conf..."
OBSCURED_PASS="$(docker run --rm "rclone/rclone:${RCLONE_VERSION}" obscure "$NZBDAV_WEBDAV_PASS" | tail -n1)"
cat >"$INSTALL_DIR/rclone.conf" <<EOF
[nzbdav]
type = webdav
url = http://nzbdav:3000/
vendor = other
user = ${NZBDAV_WEBDAV_USER}
pass = ${OBSCURED_PASS}
EOF
chmod 600 "$INSTALL_DIR/rclone.conf"

log "Writing .env and docker-compose.yml..."
cat >"$INSTALL_DIR/.env" <<EOF
PUID=${PUID}
PGID=${PGID}
TZ=${TZ}
WEBUI_PORT=${WEBUI_PORT}
FRONTEND_BACKEND_API_KEY=${FRONTEND_BACKEND_API_KEY}
WEBDAV_USER=${NZBDAV_WEBDAV_USER}
WEBDAV_PASSWORD=${NZBDAV_WEBDAV_PASS}
NZBDAV_IMAGE=nzbdav/nzbdav:${NZBDAV_VERSION}
RCLONE_IMAGE=rclone/rclone:${RCLONE_VERSION}
EOF
chmod 600 "$INSTALL_DIR/.env"

NZBDAV_IMAGE="nzbdav/nzbdav:${NZBDAV_VERSION}"
RCLONE_IMAGE="rclone/rclone:${RCLONE_VERSION}"

# Use a folded string for rclone command — CasaOS compose rejects array entries like "nzbdav:"
cat >"$INSTALL_DIR/docker-compose.yml" <<EOF
name: nzbdav
services:
  nzbdav:
    container_name: nzbdav
    image: ${NZBDAV_IMAGE}
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "${WEBUI_PORT}:3000"
    volumes:
      - ${INSTALL_DIR}/config:/config
      - /DATA/remote:/mnt/remote:rshared
    healthcheck:
      test: curl -f http://localhost:3000/health || exit 1
      interval: 30s
      retries: 5
      start_period: 60s
      timeout: 10s
    networks:
      - nzbdav

  nzbdav_rclone:
    container_name: nzbdav_rclone
    image: ${RCLONE_IMAGE}
    restart: unless-stopped
    depends_on:
      - nzbdav
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    devices:
      - /dev/fuse:/dev/fuse:rwm
    env_file:
      - .env
    volumes:
      - /DATA/remote:/mnt/remote:rshared
      - ${INSTALL_DIR}/rclone.conf:/config/rclone/rclone.conf
    command: >-
      mount nzbdav: /mnt/remote/nzbdav
      --allow-other
      --links
      --use-cookies
      --vfs-cache-mode=full
      --vfs-cache-max-size=20G
      --vfs-cache-max-age=24h
      --buffer-size=0M
      --vfs-read-ahead=512M
      --dir-cache-time=20s
      --uid=${PUID}
      --gid=${PGID}
    networks:
      - nzbdav

networks:
  nzbdav:
    driver: bridge
EOF

chmod 644 "$INSTALL_DIR/docker-compose.yml"

log "Pulling images..."
(cd "$INSTALL_DIR" && "${COMPOSE[@]}" -p "$COMPOSE_PROJECT_NAME" down --remove-orphans) 2>/dev/null || true
docker rm -f nzbdav nzbdav_rclone 2>/dev/null || true
(cd "$INSTALL_DIR" && "${COMPOSE[@]}" -p "$COMPOSE_PROJECT_NAME" pull)

log "Starting containers..."
(cd "$INSTALL_DIR" && "${COMPOSE[@]}" -p "$COMPOSE_PROJECT_NAME" up -d)

log "Waiting for NzbDav to become healthy (this can take a minute)..."
for i in $(seq 1 60); do
  if docker exec nzbdav curl -sf http://localhost:8080/health >/dev/null 2>&1; then
    ok "NzbDav backend is healthy"
    break
  fi
  if [[ "$i" -eq 60 ]]; then
    die "NzbDav did not become healthy. Check: docker logs nzbdav"
  fi
  sleep 2
done

api() {
  docker exec nzbdav curl -sf \
    -H "x-api-key: ${FRONTEND_BACKEND_API_KEY}" \
    "$@"
}

log "Creating admin account..."
if api http://localhost:8080/api/is-onboarding | grep -q '"isOnboarding":true\|"IsOnboarding":true'; then
  api -X POST \
    -F "username=${NZBDAV_ADMIN_USER}" \
    -F "password=${NZBDAV_ADMIN_PASS}" \
    -F "type=admin" \
    http://localhost:8080/api/create-account >/dev/null
  ok "Admin account created"
else
  warn "Admin account already exists — skipping create-account"
fi

log "Applying WebDAV and mount settings..."
api -X POST \
  -F "webdav.user=${NZBDAV_WEBDAV_USER}" \
  -F "webdav.pass=${NZBDAV_WEBDAV_PASS}" \
  -F "webdav.enforce-readonly=false" \
  -F "rclone.mount-dir=/mnt/remote/nzbdav" \
  http://localhost:8080/api/update-config >/dev/null
ok "WebDAV configured"

if [[ -n "${USENET_HOST:-}" ]]; then
  log "Applying usenet provider settings..."
  USENET_JSON="$(cat <<EOF
{"Providers":[{"Type":1,"Host":"${USENET_HOST}","Port":${USENET_PORT},"UseSsl":${USENET_SSL},"User":"${USENET_USER}","Pass":"${USENET_PASS}","MaxConnections":${USENET_MAX_CONN}}]}
EOF
)"
  api -X POST \
    -F "usenet.providers=${USENET_JSON}" \
    -F "usenet.max-download-connections=15" \
    http://localhost:8080/api/update-config >/dev/null
  ok "Usenet provider configured"
else
  warn "Usenet not configured — add your provider in Settings → Usenet later"
fi

log "Restarting Rclone mount..."
docker restart nzbdav_rclone >/dev/null
sleep 5

if docker exec nzbdav_rclone ls /mnt/remote/nzbdav >/dev/null 2>&1; then
  ok "Rclone mount is up at /DATA/remote/nzbdav"
else
  warn "Rclone may still be starting. Check: docker logs nzbdav_rclone"
fi

CREDS_FILE="$INSTALL_DIR/credentials.txt"
cat >"$CREDS_FILE" <<EOF
NzbDav install summary
======================
Web UI       : http://$(hostname -I | awk '{print $1}'):${WEBUI_PORT}
Admin user   : ${NZBDAV_ADMIN_USER}
Admin pass   : ${NZBDAV_ADMIN_PASS}
WebDAV user  : ${NZBDAV_WEBDAV_USER}
WebDAV pass  : ${NZBDAV_WEBDAV_PASS}
Mount path   : /DATA/remote/nzbdav
Config dir   : ${INSTALL_DIR}/config
Compose dir  : ${INSTALL_DIR}
EOF
chmod 600 "$CREDS_FILE"

# Optional: register with CasaOS app folder for visibility
if [[ -d /DATA/AppData/casaos/apps ]]; then
  mkdir -p /DATA/AppData/casaos/apps/nzbdav
  cp "$INSTALL_DIR/docker-compose.yml" /DATA/AppData/casaos/apps/nzbdav/docker-compose.yml 2>/dev/null || true
fi

echo
ok "Installation complete!"
echo
cat "$CREDS_FILE"
echo
echo "Credentials saved to: $CREDS_FILE"
echo
echo "Next steps:"
echo "  • Open the Web UI and verify Settings"
echo "  • For Radarr/Sonarr: use host nzbdav (or server IP), port ${WEBUI_PORT}, SABnzbd API key from Settings → SABnzbd"
echo "  • Full guide: https://github.com/killamfkr/nzbdav/blob/main/docs/setup-guide.md"
echo
echo "Manage stack:"
echo "  cd ${INSTALL_DIR} && docker compose -p ${COMPOSE_PROJECT_NAME} logs -f"
echo "  cd ${INSTALL_DIR} && docker compose -p ${COMPOSE_PROJECT_NAME} down"
echo
