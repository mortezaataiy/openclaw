#!/usr/bin/env bash
# docker-setup-auto.sh - نسخه اتوماتیک بدون تعامل
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
EXTRA_COMPOSE_FILE="$ROOT_DIR/docker-compose.extra.yml"
IMAGE_NAME="${OPENCLAW_IMAGE:-openclaw:local}"
EXTRA_MOUNTS="${OPENCLAW_EXTRA_MOUNTS:-}"
HOME_VOLUME_NAME="${OPENCLAW_HOME_VOLUME:-}"

# رنگ‌ها برای خروجی
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

fail() {
  log_error "$*"
  exit 1
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing dependency: $1"
  fi
}

contains_disallowed_chars() {
  local value="$1"
  [[ "$value" == *$'\n'* || "$value" == *$'\r'* || "$value" == *$'\t'* ]]
}

validate_mount_path_value() {
  local label="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    fail "$label cannot be empty."
  fi
  if contains_disallowed_chars "$value"; then
    fail "$label contains unsupported control characters."
  fi
  if [[ "$value" =~ [[:space:]] ]]; then
    fail "$label cannot contain whitespace."
  fi
}

validate_named_volume() {
  local value="$1"
  if [[ ! "$value" =~ ^[A-Za-z0-9][A-Za-z0-9
e version >/dev/null 2>&1; then
  fail "Docker Compose not available"
fi
log_success "Docker و Docker Compose موجود است"

# تنظیم متغیرهای پیش‌فرض
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
OPENCLAW_DOCKER_APT_PACKAGES="${OPENCLAW_DOCKER_APT_PACKAGES:-}"

# Validation
log_info "اعتبارسنجی تنظیمات..."
validate_mount_path_value "OPENCLAW_CONFIG_DIR" "$OPENCLAW_CONFIG_DIR"
validate_mount_path_value "OPENCLAW_WORKSPACE_DIR" "$OPENCLAW_WORKSPACE_DIR"
if [[ -n "$HOME_VOLUME_NAME" ]]; then
  if [[ "$HOME_VOLUME_NAME" == *"/"* ]]; then
    validate_mount_path_value "OPENCLAW_HOME_VOLUME" "$HOME_VOLUME_NAME"
  else
    validate_named_volume "$HOME_VOLUME_NAME"
  fi
fi
if contains_disallowed_chars "$EXTRA_MOUNTS"; then
  fail "OPENCLAW_EXTRA_MOUNTS cannot contain control characters."
fi
log_success "تنظیمات معتبر است"

# ساخت پوشه‌ها
log_info "ساخت پوشه‌های مورد نیاز..."
mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
mkdir -p "$OPENCLAW_CONFIG_DIR/identity"
log_success "پوشه‌ها ایجاد شدند"

# تولید یا استفاده از Token موجود
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  log_info "بررسی Token موجود..."
  CONFIG_FILE="$OPENCLAW_CONFIG_DIR/openclaw.json"
  
  if [[ -f "$CONFIG_FILE" ]]; then
    # تلاش برای خواندن token از config
    if command -v python3 >/dev/null 2>&1; then
      EXISTING_TOKEN=$(python3 - "$CONFIG_FILE" 2>/dev/null <<'PY' || true
import json, sys
try:
    with open(sys.argv[1]) as f:
        cfg = json.load(f)
    token = cfg.get("gateway", {}).get("auth", {}).get("token", "")
    if token.strip():
        print(token.strip())
except:
    pass
PY
)
      if [[ -n "$EXISTING_TOKEN" ]]; then
        OPENCLAW_GATEWAY_TOKEN="$EXISTING_TOKEN"
        log_success "استفاده از Token موجود"
      fi
    fi
  fi
  
  # اگر هنوز token نداریم، یکی بساز
  if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
    log_info "تولید Token جدید..."
    if command -v openssl >/dev/null 2>&1; then
      OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
    elif command -v python3 >/dev/null 2>&1; then
      OPENCLAW_GATEWAY_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
    else
      fail "نیاز به openssl یا python3 برای تولید token"
    fi
    log_success "Token جدید تولید شد"
  fi
fi

export OPENCLAW_CONFIG_DIR
export OPENCLAW_WORKSPACE_DIR
export OPENCLAW_GATEWAY_PORT
export OPENCLAW_BRIDGE_PORT
export OPENCLAW_GATEWAY_BIND
export OPENCLAW_GATEWAY_TOKEN
export OPENCLAW_IMAGE="$IMAGE_NAME"
export OPENCLAW_DOCKER_APT_PACKAGES
export OPENCLAW_EXTRA_MOUNTS="$EXTRA_MOUNTS"
export OPENCLAW_HOME_VOLUME="$HOME_VOLUME_NAME"

# ساخت docker-compose.extra.yml در صورت نیاز
COMPOSE_FILES=("$COMPOSE_FILE")
COMPOSE_ARGS=()

write_extra_compose() {
  local home_volume="$1"
  shift
  
  cat >"$EXTRA_COMPOSE_FILE" <<'YAML'
services:
  openclaw-gateway:
    volumes:
YAML

  if [[ -n "$home_volume" ]]; then
    local gateway_home_mount="${home_volume}:/home/node"
    local gateway_config_mount="${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw"
    local gateway_workspace_mount="${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace"
    validate_mount_spec "$gateway_home_mount"
    validate_mount_spec "$gateway_config_mount"
    validate_mount_spec "$gateway_workspace_mount"
    printf '      - %s\n' "$gateway_home_mount" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s\n' "$gateway_config_mount" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s\n' "$gateway_workspace_mount" >>"$EXTRA_COMPOSE_FILE"
  fi

  for mount in "$@"; do
    validate_mount_spec "$mount"
    printf '      - %s\n' "$mount" >>"$EXTRA_COMPOSE_FILE"
  done

  cat >>"$EXTRA_COMPOSE_FILE" <<'YAML'
  openclaw-cli:
    volumes:
YAML

  if [[ -n "$home_volume" ]]; then
    printf '      - %s\n' "${home_volume}:/home/node" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s\n' "${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s\n' "${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace" >>"$EXTRA_COMPOSE_FILE"
  fi

  for mount in "$@"; do
    printf '      - %s\n' "$mount" >>"$EXTRA_COMPOSE_FILE"
  done

  if [[ -n "$home_volume" && "$home_volume" != *"/"* ]]; then
    validate_named_volume "$home_volume"
    cat >>"$EXTRA_COMPOSE_FILE" <<YAML
volumes:
  ${home_volume}:
YAML
  fi
}

VALID_MOUNTS=()
if [[ -n "$EXTRA_MOUNTS" ]]; then
  IFS=',' read -r -a mounts <<<"$EXTRA_MOUNTS"
  for mount in "${mounts[@]}"; do
    mount="${mount#"${mount%%[![:space:]]*}"}"
    mount="${mount%"${mount##*[![:space:]]}"}"
    if [[ -n "$mount" ]]; then
      VALID_MOUNTS+=("$mount")
    fi
  done
fi

if [[ -n "$HOME_VOLUME_NAME" || ${#VALID_MOUNTS[@]} -gt 0 ]]; then
  log_info "ساخت docker-compose.extra.yml..."
  if [[ ${#VALID_MOUNTS[@]} -gt 0 ]]; then
    write_extra_compose "$HOME_VOLUME_NAME" "${VALID_MOUNTS[@]}"
  else
    write_extra_compose "$HOME_VOLUME_NAME"
  fi
  COMPOSE_FILES+=("$EXTRA_COMPOSE_FILE")
  log_success "docker-compose.extra.yml ساخته شد"
fi

for compose_file in "${COMPOSE_FILES[@]}"; do
  COMPOSE_ARGS+=("-f" "$compose_file")
done

# ذخیره متغیرها در .env
log_info "ذخیره تنظیمات در .env..."
ENV_FILE="$ROOT_DIR/.env"
cat >"$ENV_FILE" <<EOF
OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=$OPENCLAW_GATEWAY_PORT
OPENCLAW_BRIDGE_PORT=$OPENCLAW_BRIDGE_PORT
OPENCLAW_GATEWAY_BIND=$OPENCLAW_GATEWAY_BIND
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_EXTRA_MOUNTS=$OPENCLAW_EXTRA_MOUNTS
OPENCLAW_HOME_VOLUME=$OPENCLAW_HOME_VOLUME
OPENCLAW_DOCKER_APT_PACKAGES=$OPENCLAW_DOCKER_APT_PACKAGES
EOF
log_success "تنظیمات در .env ذخیره شد"

# Build یا Pull کردن Image
if [[ "$IMAGE_NAME" == "openclaw:local" ]]; then
  log_info "Build کردن Docker image: $IMAGE_NAME"
  docker build \
    --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES}" \
    -t "$IMAGE_NAME" \
    -f "$ROOT_DIR/Dockerfile" \
    "$ROOT_DIR"
  log_success "Image ساخته شد"
else
  log_info "Pull کردن Docker image: $IMAGE_NAME"
  if ! docker pull "$IMAGE_NAME"; then
    fail "Failed to pull image $IMAGE_NAME"
  fi
  log_success "Image دریافت شد"
fi

# ساخت فایل تنظیمات اولیه (بدون onboarding تعاملی)
log_info "ساخت فایل تنظیمات اولیه..."
CONFIG_FILE="$OPENCLAW_CONFIG_DIR/openclaw.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
  cat >"$CONFIG_FILE" <<EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$OPENCLAW_GATEWAY_BIND",
    "port": $OPENCLAW_GATEWAY_PORT,
    "auth": {
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowedOrigins": ["http://127.0.0.1:$OPENCLAW_GATEWAY_PORT"]
    }
  },
  "bridge": {
    "port": $OPENCLAW_BRIDGE_PORT
  }
}
EOF
  log_success "فایل تنظیمات ساخته شد"
else
  log_warning "فایل تنظیمات از قبل وجود دارد، از آن استفاده می‌شود"
fi

# راه‌اندازی Gateway
log_info "راه‌اندازی Gateway..."
docker compose "${COMPOSE_ARGS[@]}" up -d openclaw-gateway
log_success "Gateway راه‌اندازی شد"

# نمایش اطلاعات
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ OpenClaw با موفقیت راه‌اندازی شد!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📍 دسترسی:${NC}"
echo "   URL: http://127.0.0.1:$OPENCLAW_GATEWAY_PORT/"
echo "   Token: $OPENCLAW_GATEWAY_TOKEN"
echo ""
echo -e "${BLUE}📁 مسیرها:${NC}"
echo "   Config: $OPENCLAW_CONFIG_DIR"
echo "   Workspace: $OPENCLAW_WORKSPACE_DIR"
echo ""
echo -e "${BLUE}🔧 دستورات مفید:${NC}"
echo "   مشاهده لاگ‌ها:"
echo "     docker compose ${COMPOSE_ARGS[*]:1} logs -f openclaw-gateway"
echo ""
echo "   بررسی وضعیت:"
echo "     docker compose ${COMPOSE_ARGS[*]:1} exec openclaw-gateway node dist/index.js health --token \"$OPENCLAW_GATEWAY_TOKEN\""
echo ""
echo "   توقف:"
echo "     docker compose ${COMPOSE_ARGS[*]:1} down"
echo ""
echo "   راه‌اندازی مجدد:"
echo "     docker compose ${COMPOSE_ARGS[*]:1} restart openclaw-gateway"
echo ""
echo -e "${YELLOW}📚 مستندات:${NC} https://docs.openclaw.ai/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
