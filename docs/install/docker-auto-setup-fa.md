---
summary: "راهنمای استفاده از نسخه اتوماتیک docker-setup"
title: "نصب اتوماتیک Docker (بدون تعامل)"
---

# نصب اتوماتیک OpenClaw با Docker

این راهنما برای کسانی است که می‌خواهند OpenClaw را بدون تعامل (non-interactive) و به صورت کاملاً خودکار نصب کنند.

## تفاوت با نسخه معمولی

| ویژگی | `docker-setup.sh` | `docker-setup-auto.sh` |
|-------|-------------------|------------------------|
| تعاملی (Interactive) | ✅ بله | ❌ خیر |
| Onboarding Wizard | ✅ دارد | ❌ ندارد |
| تنظیمات از ENV | ✅ بله | ✅ بله |
| مناسب برای | نصب دستی | CI/CD، اسکریپت‌ها |

## نصب سریع

### مرحله 1: کپی کردن فایل تنظیمات

```bash
cp .env.docker.example .env
```

### مرحله 2: ویرایش تنظیمات

```bash
nano .env
```

**حداقل تنظیمات:**

```bash
# استفاده از image از GitHub
OPENCLAW_IMAGE=ghcr.io/USERNAME/REPO:latest

# یا build محلی (نیاز به اینترنت قوی)
# OPENCLAW_IMAGE=openclaw:local
```

### مرحله 3: اجرای نصب

```bash
chmod +x docker-setup-auto.sh
./docker-setup-auto.sh
```

⏱️ **زمان:** 2-5 دقیقه (اگر image از قبل pull شده باشد)

### مرحله 4: دسترسی

```bash
# باز کردن در مرورگر
open http://127.0.0.1:18789/

# Token را از خروجی اسکریپت کپی کنید
```

## تنظیمات کامل

### فایل `.env` نمونه

```bash
# ═══════════════════════════════════════════════════════════
# تنظیمات اصلی
# ═══════════════════════════════════════════════════════════

# Image
OPENCLAW_IMAGE=ghcr.io/myusername/openclaw:latest

# Token (اختیاری - خودکار تولید می‌شود)
# OPENCLAW_GATEWAY_TOKEN=abc123...

# ═══════════════════════════════════════════════════════════
# مسیرها
# ═══════════════════════════════════════════════════════════

OPENCLAW_CONFIG_DIR=$HOME/.openclaw
OPENCLAW_WORKSPACE_DIR=$HOME/.openclaw/workspace

# ═══════════════════════════════════════════════════════════
# پورت‌ها
# ═══════════════════════════════════════════════════════════

OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790

# ═══════════════════════════════════════════════════════════
# شبکه
# ═══════════════════════════════════════════════════════════

# loopback = فقط localhost
# lan = دسترسی از شبکه محلی
OPENCLAW_GATEWAY_BIND=lan

# ═══════════════════════════════════════════════════════════
# پیشرفته
# ═══════════════════════════════════════════════════════════

# Volume برای ذخیره دائمی
OPENCLAW
:local

# اجرا
./docker-setup-auto.sh
```

**نیازمندی:**
- ❌ اینترنت قوی (برای دانلود پکیج‌ها)
- ⏱️ زمان‌بر (10-15 دقیقه)

### سناریو 3: با Volume دائمی

```bash
# .env
OPENCLAW_IMAGE=ghcr.io/myusername/openclaw:latest
OPENCLAW_HOME_VOLUME=openclaw_home

# اجرا
./docker-setup-auto.sh
```

**مزایا:**
- ✅ کش‌ها و مرورگرها ذخیره می‌شوند
- ✅ نیازی به نصب مجدد Playwright نیست

### سناریو 4: با Mount های اضافی

```bash
# .env
OPENCLAW_IMAGE=ghcr.io/myusername/openclaw:latest
OPENCLAW_EXTRA_MOUNTS=$HOME/projects:/home/node/projects:rw,$HOME/.ssh:/home/node/.ssh:ro

# اجرا
./docker-setup-auto.sh
```

**کاربرد:**
- دسترسی به پروژه‌های محلی
- استفاده از کلیدهای SSH

### سناریو 5: استفاده در CI/CD

```bash
#!/bin/bash
# deploy.sh

# تنظیم متغیرها
export OPENCLAW_IMAGE="ghcr.io/myorg/openclaw:latest"
export OPENCLAW_GATEWAY_TOKEN="$SECRET_TOKEN"
export OPENCLAW_CONFIG_DIR="/opt/openclaw/config"
export OPENCLAW_WORKSPACE_DIR="/opt/openclaw/workspace"

# اجرا
./docker-setup-auto.sh

# بررسی وضعیت
docker compose ps
```

## مقایسه کارهای انجام شده

### `docker-setup.sh` (تعاملی)

```
1. ✅ Validation
2. ✅ ساخت پوشه‌ها
3. ✅ تولید Token
4. ✅ ساخت .env
5. ✅ ساخت docker-compose.extra.yml
6. ✅ Build/Pull Image
7. ⚠️  Onboarding Wizard (تعاملی)
   - سوال: Gateway bind?
   - سوال: Auth method?
   - سوال: Token?
   - سوال: Tailscale?
   - سوال: Install daemon?
8. ✅ تنظیم Control UI
9. ✅ راه‌اندازی Gateway
```

### `docker-setup-auto.sh` (اتوماتیک)

```
1. ✅ Validation
2. ✅ ساخت پوشه‌ها
3. ✅ تولید Token (از ENV یا خودکار)
4. ✅ ساخت .env
5. ✅ ساخت docker-compose.extra.yml
6. ✅ Build/Pull Image
7. ✅ ساخت openclaw.json (بدون wizard)
   - همه تنظیمات از ENV
8. ✅ راه‌اندازی Gateway
```

## دستورات مفید

### مشاهده لاگ‌ها

```bash
docker compose logs -f openclaw-gateway
```

### بررسی وضعیت

```bash
# دریافت Token از .env
source .env

# Health check
docker compose exec openclaw-gateway \
  node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

### توقف و راه‌اندازی مجدد

```bash
# توقف
docker compose down

# راه‌اندازی مجدد
docker compose up -d openclaw-gateway

# یا استفاده مجدد از اسکریپت
./docker-setup-auto.sh
```

### پاک کردن کامل

```bash
# توقف containerها
docker compose down

# پاک کردن volumes
docker volume rm openclaw_home  # اگر استفاده کرده‌اید

# پاک کردن تنظیمات
rm -rf ~/.openclaw/

# پاک کردن فایل‌های موقت
rm -f .env docker-compose.extra.yml
```

## عیب‌یابی

### خطا: Image not found

```bash
# بررسی نام image
echo $OPENCLAW_IMAGE

# Pull دستی
docker pull $OPENCLAW_IMAGE

# یا تغییر به build محلی
export OPENCLAW_IMAGE=openclaw:local
./docker-setup-auto.sh
```

### خطا: Permission denied

```bash
# اجازه اجرا
chmod +x docker-setup-auto.sh

# یا اجرا با bash
bash docker-setup-auto.sh
```

### خطا: Port already in use

```bash
# تغییر پورت
export OPENCLAW_GATEWAY_PORT=18790
./docker-setup-auto.sh

# یا توقف سرویس قبلی
docker compose down
```

### Token گم شده

```bash
# خواندن از .env
cat .env | grep OPENCLAW_GATEWAY_TOKEN

# یا از config
cat ~/.openclaw/openclaw.json | grep token
```

## استفاده در Production

### 1. استفاده از Docker Secrets

```bash
# ساخت secret
echo "my-secure-token" | docker secret create openclaw_token -

# استفاده در docker-compose
# (نیاز به Docker Swarm)
```

### 2. استفاده از Environment Variables

```bash
# در systemd service
Environment="OPENCLAW_GATEWAY_TOKEN=xxx"
Environment="OPENCLAW_IMAGE=ghcr.io/org/openclaw:latest"

ExecStart=/path/to/docker-setup-auto.sh
```

### 3. استفاده در Kubernetes

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openclaw-config
data:
  OPENCLAW_IMAGE: "ghcr.io/org/openclaw:latest"
  OPENCLAW_GATEWAY_PORT: "18789"
---
apiVersion: v1
kind: Secret
metadata:
  name: openclaw-secrets
stringData:
  OPENCLAW_GATEWAY_TOKEN: "xxx"
```

## مقایسه روش‌ها

| ویژگی | تعاملی | اتوماتیک |
|-------|--------|----------|
| سرعت | کند (نیاز به ورودی) | سریع |
| مناسب برای | نصب اولیه | CI/CD، اسکریپت |
| قابلیت سفارشی‌سازی | بالا | بالا |
| نیاز به تعامل | بله | خیر |
| مستندسازی | کمتر | بیشتر |

## خلاصه

```bash
# 1. کپی تنظیمات
cp .env.docker.example .env

# 2. ویرایش
nano .env

# 3. اجرا
./docker-setup-auto.sh

# 4. دسترسی
open http://127.0.0.1:18789/
```

✅ تمام!

## منابع بیشتر

- [راهنمای Docker اصلی](/install/docker-fa)
- [Build با GitHub Actions](/install/docker-github-action-fa)
- [Mount در Docker](/install/docker-mount-explained-fa)
- [مستندات کامل](https://docs.openclaw.ai/)
