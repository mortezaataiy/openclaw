#!/usr/bin/env bash
# docker-entrypoint.sh - اسکریپت خودکار برای راه‌اندازی container
set -euo pipefail

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# مسیرهای مهم
CONFIG_DIR="${HOME}/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"
WORKSPACE_DIR="${CONFIG_DIR}/workspace"

# تنظیمات پیش‌فرض
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"

log_info "شروع راه‌اندازی OpenClaw..."

# ═══════════════════════════════════════════════════════════
# 1. ساخت پوشه‌های مورد نیاز
# ═══════════════════════════════════════════════════════════

log_info "بررسی پوشه‌های مورد نیاز..."

if [[ ! -d "$CONFIG_DIR" ]]; then
  log_info "ساخت پوشه config: $CONFIG_DIR"
  mkdir -p "$CONFIG_DIR"
fi

if [[ ! -d "$WORKSPACE_DIR" ]]; then
  log_info "ساخت پوشه workspace: $WORKSPACE_DIR"
  mkdir -p "$WORKSPACE_DIR"
fi

if [[ ! -d "$CONFIG_DIR/identity" ]]; then
  mkdir -p "$CONFIG_DIR/identity"
fi

log_success "پوشه‌ها آماده هستند"

# ═══════════════════════════════════════════════════════════
# 2. تولید یا بازیابی Token
# ═══════════════════════════════════════════════════════════

if [[ -z "$GATEWAY_TOKEN" ]]; then
  log_info "بررسی Token موجود..."
  
  # تلاش برای خواندن token از config موجود
  if [[ -f "$CONFIG_FILE" ]]; then
    if command -v node >/dev/null 2>&1; then
      EXISTING_TOKEN=$(node -e "
        try {
          const fs = require('fs');
          const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
          const token = cfg?.gateway?.auth?.token;
          if (token && token.trim()) {
            process.stdout.write(token.trim());
          }
        } catch (e) {}
      " 2>/dev/null || true)
      
      if [[ -n "$EXISTING_TOKEN" ]]; then
        GATEWAY_TOKEN="$EXISTING_TOKEN"
        log_success "استفاده از Token موجود"
      fi
    fi
  fi
  
  # اگر هنوز token نداریم، یکی بساز
  if [[ -z "$GATEWAY_TOKEN" ]]; then
    log_info "تولید Token جدید..."
    if command -v openssl >/dev/null 2>&1; then
      GATEWAY_TOKEN="$(openssl rand -hex 32)"
    elif command -v node >/dev/null 2>&1; then
      GATEWAY_TOKEN="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
    else
      log_error "نیاز به openssl یا node برای تولید token"
      exit 1
    fi
    log_success "Token جدید تولید شد"
  fi
fi

# ═══════════════════════════════════════════════════════════
# 3. ساخت یا به‌روزرسانی فایل تنظیمات
# ═══════════════════════════════════════════════════════════

log_info "بررسی فایل تنظیمات..."

CONFIG_EXISTS=false
if [[ -f "$CONFIG_FILE" ]]; then
  CONFIG_EXISTS=true
  log_info "فایل تنظیمات موجود است"
  
  # بررسی اینکه آیا gateway.mode تنظیم شده
  if command -v node >/dev/null 2>&1; then
    HAS_MODE=$(node -e "
      try {
        const fs = require('fs');
        const cfg = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        if (cfg?.gateway?.mode) {
          process.stdout.write('yes');
        }
      } catch (e) {}
    " 2>/dev/null || true)
    
    if [[ "$HAS_MODE" == "yes" ]]; then
      log_success "تنظیمات معتبر است، از آن استفاده می‌شود"
    else
      log_warning "فایل تنظیمات ناقص است، به‌روزرسانی می‌شود"
      CONFIG_EXISTS=false
    fi
  fi
fi

if [[ "$CONFIG_EXISTS" == "false" ]]; then
  log_info "ساخت فایل تنظیمات جدید..."
  
  # تعیین allowedOrigins بر اساس bind mode
  if [[ "$GATEWAY_BIND" == "loopback" ]]; then
    ALLOWED_ORIGINS="[]"
  else
    ALLOWED_ORIGINS="[\"http://127.0.0.1:${GATEWAY_PORT}\"]"
  fi
  
  cat >"$CONFIG_FILE" <<EOF
{
  "gateway": {
    "mode": "local",
    "bind": "$GATEWAY_BIND",
    "port": $GATEWAY_PORT,
    "auth": {
      "token": "$GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowedOrigins": $ALLOWED_ORIGINS
    }
  },
  "bridge": {
    "port": $BRIDGE_PORT
  }
}
EOF
  log_success "فایل تنظیمات ساخته شد"
fi

# ═══════════════════════════════════════════════════════════
# 4. نمایش اطلاعات
# ═══════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ OpenClaw آماده راه‌اندازی است${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}📍 دسترسی:${NC}"
echo "   URL: http://127.0.0.1:${GATEWAY_PORT}/"
echo "   Token: ${GATEWAY_TOKEN}"
echo ""
echo -e "${BLUE}📁 مسیرها:${NC}"
echo "   Config: ${CONFIG_DIR}"
echo "   Workspace: ${WORKSPACE_DIR}"
echo ""
echo -e "${BLUE}🚀 راه‌اندازی Gateway...${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# 5. اجرای دستور اصلی
# ═══════════════════════════════════════════════════════════

# اگر دستوری به entrypoint داده نشده، از CMD پیش‌فرض استفاده کن
if [[ $# -eq 0 ]]; then
  exec node dist/index.js gateway --bind "$GATEWAY_BIND" --port "$GATEWAY_PORT"
else
  # اجرای دستور داده شده
  exec "$@"
fi
