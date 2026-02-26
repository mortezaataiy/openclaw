---
summary: "راهنمای نصب و راه‌اندازی OpenClaw با Docker"
title: "راهنمای فارسی Docker"
---

# راهنمای نصب OpenClaw با Docker

## خلاصه سریع

```bash
# نصب سریع (توصیه می‌شود)
./docker-setup.sh

# دسترسی به رابط کاربری
# باز کردن http://127.0.0.1:18789/ در مرورگر
```

**نکته مهم:** اگر تازه شروع کرده‌اید و نمی‌دانید Docker چیست، از [روش نصب معمولی](/start/getting-started) استفاده کنید. Docker اختیاری است!

## آیا Docker برای من مناسب است؟

Docker برای OpenClaw **اختیاری** است. از آن استفاده کنید اگر:

- می‌خواهید محیط Gateway ایزوله و مجزا داشته باشید
- می‌خواهید OpenClaw را روی سرور بدون نصب مستقیم اجرا کنید
- می‌خواهید فرآیند Docker را تست کنید

اگر روی سیستم شخصی خودتان کار می‌کنید و سریع‌ترین روش را می‌خواهید، از نصب معمولی استفاده کنید.

## پیش‌نیازها

قبل از شروع، نیاز دارید:

- Docker Desktop (یا Docker Engine) + Docker Compos
می‌کند**

### مرحله 2: پاسخ به سوالات ویزارد

هنگام اجرای اسکریپت، به سوالات زیر پاسخ دهید:

- **Gateway bind**: `lan` را انتخاب کنید
- **Gateway auth**: `token` را انتخاب کنید
- **Gateway token**: از token پیشنهادی استفاده کنید (اسکریپت آن را نمایش می‌دهد)
- **Tailscale exposure**: `Off` (خاموش)
- **Install Gateway daemon**: `No` (خیر)

### مرحله 3: دسترسی به رابط کاربری

پس از اتمام نصب:

1. مرورگر خود را باز کنید و به آدرس زیر بروید:
   ```
   http://127.0.0.1:18789/
   ```

2. Token را در رابط کاربری Control UI وارد کنید:
   - به بخش Settings بروید
   - Token را paste کنید

3. اگر نیاز به دریافت مجدد URL داشتید:
   ```bash
   docker compose run --rm openclaw-cli dashboard --no-open
   ```

## محل ذخیره‌سازی فایل‌ها

فایل‌های تنظیمات و workspace روی سیستم میزبان (host) ذخیره می‌شوند:

- **تنظیمات**: `~/.openclaw/`
- **Workspace**: `~/.openclaw/workspace`

### درک تفاوت Bind Mount و Volume

💡 **برای توضیحات کامل‌تر درباره Mount:** [Mount در Docker چیست؟](/install/docker-mount-explained-fa)

**Bind Mount (حالت پیش‌فرض):**
```
سیستم شما                    Container
~/.openclaw/          →      /home/node/.openclaw
~/.openclaw/workspace →      /home/node/.openclaw/workspace
```
- فایل‌ها مستقیماً روی سیستم شما هستند
- می‌توانید با ویرایشگر متن خودتان آنها را ببینید و ویرایش کنید
- وقتی container پاک می‌شود، فایل‌ها باقی می‌مانند

**Volume (با `OPENCLAW_HOME_VOLUME`):**
```
Docker Volume                 Container
openclaw_home         →      /home/node/
```
- فایل‌ها توسط Docker مدیریت می‌شوند
- در مکانی خاص Docker ذخیره می‌شوند (نه مستقیماً در home شما)
- حتی اگر container و image را پاک کنید، volume باقی می‌ماند
- برای دسترسی باید از دستورات Docker استفاده کنید

**مثال عملی تفاوت:**

```bash
# بدون Volume
docker compose down
docker compose up -d
# ❌ مرورگرهای Playwright پاک شدند

# با Volume
docker compose down
docker compose up -d
# ✅ مرورگرهای Playwright هنوز هستند
```

## متغیرهای محیطی اختیاری

می‌توانید قبل از اجرای `docker-setup.sh` این متغیرها را تنظیم کنید:

### نصب پکیج‌های سیستمی اضافی

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg git curl jq"
./docker-setup.sh
```

### اضافه کردن mount های اضافی

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

### ذخیره‌سازی دائمی home directory

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

**توضیح Volume:**

Volume در Docker یک فضای ذخیره‌سازی دائمی است که مستقل از container عمل می‌کند.

**بدون تنظیم این متغیر (حالت پیش‌فرض):**
- ✅ تنظیمات و workspace شما ذخیره می‌شوند (روی `~/.openclaw/`)
- ❌ کش‌ها، مرورگرهای Playwright و ابزارهای نصب شده پاک می‌شوند

**با تنظیم این متغیر:**
- ✅ همه چیز در `/home/node` دائمی می‌ماند
- ✅ مرورگرهای Playwright نیازی به نصب مجدد ندارند
- ✅ کش‌ها و ابزارها بین rebuild ها حفظ می‌شوند

**نکته:** Docker خودش volume را می‌سازد، نیازی به ایجاد دستی نیست.

**چه زمانی استفاده کنیم:**
- وقتی مرورگرهای Playwright نصب می‌کنید
- وقتی ابزارهای سنگین نصب می‌کنید
- وقتی روی سرور production کار می‌کنید

**برای استفاده معمولی:** حالت پیش‌فرض کافی است.

## تنظیم کانال‌های ارتباطی (اختیاری)

### WhatsApp (با QR Code)

```bash
docker compose run --rm openclaw-cli channels login
```

### Telegram (با Bot Token)

```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<توکن-بات-شما>"
```

### Discord (با Bot Token)

```bash
docker compose run --rm openclaw-cli channels add --channel discord --token "<توکن-بات-شما>"
```

## دستورات مفید

### مشاهده لاگ‌های Gateway

```bash
docker compose logs -f openclaw-gateway
```

### بررسی وضعیت سلامت (Health Check)

```bash
docker compose exec openclaw-gateway node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

### توقف Gateway

```bash
docker compose down
```

### راه‌اندازی مجدد Gateway

```bash
docker compose restart openclaw-gateway
```

### مشاهده containerهای در حال اجرا

```bash
docker compose ps
```

## نصب دستی (بدون اسکریپت)

اگر می‌خواهید مراحل را به صورت دستی انجام دهید:

### 1. Build کردن Image

```bash
docker build -t openclaw:local -f Dockerfile .
```

### 2. اجرای Onboarding

```bash
docker compose run --rm openclaw-cli onboard
```

### 3. راه‌اندازی Gateway

```bash
docker compose up -d openclaw-gateway
```

## استفاده روی VPS

اگر می‌خواهید OpenClaw را روی یک سرور VPS اجرا کنید، راهنمای کامل Hetzner را مطالعه کنید:

[راهنمای Hetzner (Docker VPS)](/install/hetzner)

## ابزارهای کمکی Shell (ClawDock)

برای مدیریت راحت‌تر Docker، می‌توانید ابزارهای کمکی ClawDock را نصب کنید:

```bash
mkdir -p ~/.clawdock && curl -sL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/shell-helpers/clawdock-helpers.sh -o ~/.clawdock/clawdock-helpers.sh
```

سپس به فایل تنظیمات shell خود اضافه کنید:

```bash
echo 'source ~/.clawdock/clawdock-helpers.sh' >> ~/.zshrc && source ~/.zshrc
```

دستورات موجود:
- `clawdock-start` - راه‌اندازی Gateway
- `clawdock-stop` - توقف Gateway
- `clawdock-dashboard` - باز کردن Dashboard
- `clawdock-help` - نمایش راهنما

## عیب‌یابی مشکلات رایج

### نمودار فرآیند Build

```
┌─────────────────────────────────────────────────────────────┐
│  روش 1: Build محلی (نیاز به اینترنت قوی)                   │
│                                                              │
│  سیستم شما → docker build → Image محلی → استفاده           │
│                                                              │
│  ❌ مشکل: Error: getaddrinfo EAI_AGAIN registry.npmjs.org  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  روش 2: Build با GitHub Actions (توصیه می‌شود)             │
│                                                              │
│  1. Push کد → GitHub                                        │
│  2. اجرای Workflow → GitHub Actions (سرورهای GitHub)       │
│  3. Build Image → GitHub Container Registry (ghcr.io)       │
│  4. Pull Image → سیستم شما                                 │
│  5. استفاده از Image                                        │
│                                                              │
│  ✅ حل شد: سرورهای GitHub به همه جا دسترسی دارند          │
└─────────────────────────────────────────────────────────────┘
```

### خطای دسترسی (Permission Errors)

Image به عنوان کاربر `node` (uid 1000) اجرا می‌شود. اگر خطای دسترسی دیدید:

```bash
sudo chown -R 1000:1000 ~/.openclaw ~/.openclaw/workspace
```

### خطای "unauthorized" یا "disconnected"

Token جدید دریافت کنید و دستگاه را تایید کنید:

```bash
docker compose run --rm openclaw-cli dashboard --no-open
docker compose run --rm openclaw-cli devices list
docker compose run --rm openclaw-cli devices approve <requestId>
```

### مشکل حافظه (OOM) هنگام Build

اگر هنگام build با خطای حافظه مواجه شدید، حداقل 2GB RAM اختصاص دهید.

### Image پیدا نمی‌شود

مطمئن شوید که image را build کرده‌اید:

```bash
docker build -t openclaw:local -f Dockerfile .
```

### خطای شبکه هنگام Build (EAI_AGAIN registry.npmjs.org)

اگر به دلیل مشکلات شبکه (فیلترینگ یا محدودیت دسترسی) نمی‌توانید image بسازید:

**راه‌حل: استفاده از GitHub Actions**

📖 [راهنمای سریع: Build با GitHub Actions](/install/DOCKER-BUILD-GITHUB)

📖 [راهنمای کامل فارسی](/install/docker-github-action-fa)

خلاصه:
1. به repository خود در GitHub بروید
2. Actions → Docker Build (Manual) → Run workflow
3. منتظر بمانید (10-15 دقیقه)
4. استفاده از image:
   ```bash
   export OPENCLAW_IMAGE="ghcr.io/USERNAME/REPO:latest"
   ./docker-setup.sh
   ```

## سوالات متداول (FAQ)

### Mount چیست؟

**Mount** = اتصال یک پوشه از سیستم شما به داخل Container

مثل یک پنجره بین دو اتاق:
- **Bind Mount**: پوشه‌ای از سیستم شما (می‌توانید ببینید و ویرایش کنید)
- **Volume**: فضایی که Docker مدیریت می‌کند (دائمی و بهینه)

📖 **توضیحات کامل:** [Mount در Docker چیست؟](/install/docker-mount-explained-fa)

### آیا باید Volume ایجاد کنم؟

**خیر!** Docker خودش volume را می‌سازد. فقط متغیر محیطی را تنظیم کنید:

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

### چطور ببینم Volume ساخته شده یا نه؟

```bash
docker volume ls | grep openclaw
```

خروجی:
```
local     openclaw_home
```

### چطور فضای استفاده شده Volume را ببینم؟

```bash
docker volume inspect openclaw_home
```

یا برای دیدن حجم:
```bash
docker system df -v | grep openclaw_home
```

### چطور فایل‌های داخل Volume را ببینم؟

```bash
# راه 1: از طریق container
docker compose run --rm openclaw-cli ls -lah /home/node

# راه 2: دسترسی مستقیم (Linux)
sudo ls -lah /var/lib/docker/volumes/openclaw_home/_data/
```

### اگر بخواهم Volume را پاک کنم چطور؟

**احتیاط! این کار همه چیز را پاک می‌کند:**

```bash
# اول containerها را متوقف کنید
docker compose down

# سپس volume را پاک کنید
docker volume rm openclaw_home
```

### آیا می‌توانم Volume را backup بگیرم؟

بله:

```bash
# Backup
docker run --rm \
  -v openclaw_home:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/openclaw-backup.tar.gz -C /data .

# Restore
docker run --rm \
  -v openclaw_home:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/openclaw-backup.tar.gz -C /data
```

### تفاوت `OPENCLAW_HOME_VOLUME` و `OPENCLAW_EXTRA_MOUNTS` چیست؟

- **`OPENCLAW_HOME_VOLUME`**: کل `/home/node` را در یک volume ذخیره می‌کند
- **`OPENCLAW_EXTRA_MOUNTS`**: پوشه‌های خاصی از سیستم شما را mount می‌کند

مثال:
```bash
# Volume: برای ذخیره دائمی کش‌ها و ابزارها
export OPENCLAW_HOME_VOLUME="openclaw_home"

# Extra Mounts: برای دسترسی به پوشه‌های خاص
export OPENCLAW_EXTRA_MOUNTS="$HOME/projects:/home/node/projects:rw"
```

### چرا باید از Volume استفاده کنم؟

استفاده کنید اگر:
- ✅ نمی‌خواهید مرورگرهای Playwright را دوباره نصب کنید (60-90 ثانیه صرفه‌جویی)
- ✅ ابزارهای سنگین نصب می‌کنید
- ✅ روی سرور production کار می‌کنید
- ✅ می‌خواهید کش‌های npm/pnpm را نگه دارید

استفاده نکنید اگر:
- ❌ فقط تست می‌کنید
- ❌ می‌خواهید محیط تمیز داشته باشید
- ❌ فضای دیسک محدود دارید

## Sandbox برای Agent (پیشرفته)

اگر می‌خواهید ابزارهای agent در محیط ایزوله Docker اجرا شوند (در حالی که Gateway روی host است):

### 1. Build کردن Sandbox Image

```bash
scripts/sandbox-setup.sh
```

### 2. فعال‌سازی Sandbox در تنظیمات

در فایل `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main",
        "scope": "agent",
        "workspaceAccess": "none",
        "docker": {
          "image": "openclaw-sandbox:bookworm-slim"
        }
      }
    }
  }
}
```

## منابع بیشتر

- [مستندات کامل Docker](/install/docker)
- [راهنمای Sandboxing](/gateway/sandboxing)
- [تنظیمات Gateway](/gateway/configuration)
- [کانال‌های ارتباطی](/channels)

## خلاصه دستورات

```bash
# نصب سریع
./docker-setup.sh

# مشاهده لاگ‌ها
docker compose logs -f openclaw-gateway

# توقف
docker compose down

# راه‌اندازی مجدد
docker compose up -d openclaw-gateway

# دسترسی به Dashboard
# باز کردن http://127.0.0.1:18789/ در مرورگر
```

---

**نکته مهم**: Docker برای OpenClaw اختیاری است. اگر فقط می‌خواهید سریع شروع کنید، از [روش نصب معمولی](/start/getting-started) استفاده کنید.
