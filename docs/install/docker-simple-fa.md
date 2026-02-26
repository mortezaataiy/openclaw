---
summary: "ساده‌ترین روش اجرای OpenClaw با Docker - فقط docker compose up!"
title: "Docker - روش ساده (فقط compose up)"
---

# روش ساده: فقط `docker compose up`!

این ساده‌ترین روش برای اجرای OpenClaw با Docker است. نیازی به اجرای اسکریپت نیست!

## چطور کار می‌کنه؟

Container وقتی راه‌اندازی می‌شه، خودش:
- ✅ پوشه‌های مورد نیاز رو می‌سازه
- ✅ Token تولید می‌کنه (اگر نداشته باشی)
- ✅ فایل تنظیمات رو می‌سازه (اگر نباشه)
- ✅ Gateway رو راه‌اندازی می‌کنه

**شما فقط باید `docker compose up` بزنید!**

## نصب سریع

### مرحله 1: کپی تنظیمات

```bash
cp .env.simple .
 | grep token
```

سپس:
1. باز کردن `http://127.0.0.1:18789/` در مرورگر
2. وارد کردن Token

## مثال کامل

```bash
# 1. کپی تنظیمات
cp .env.simple .env

# 2. ویرایش
echo 'OPENCLAW_IMAGE=ghcr.io/myusername/openclaw:latest' >> .env

# 3. اجرا
docker compose -f docker-compose.simple.yml up -d

# 4. مشاهده Token
docker compose -f docker-compose.simple.yml logs openclaw | grep Token

# خروجی:
#    Token: abc123def456...

# 5. دسترسی
# باز کردن http://127.0.0.1:18789/
```

## تنظیمات اختیاری

### تغییر پورت

```bash
# .env
OPENCLAW_GATEWAY_PORT=8080
```

### تنظیم Token دستی

```bash
# .env
OPENCLAW_GATEWAY_TOKEN=my-secure-token-here
```

### استفاده از Volume برای ذخیره دائمی

```bash
# 1. در .env
OPENCLAW_HOME_VOLUME=openclaw_home

# 2. در docker-compose.simple.yml
# uncomment کردن این خطوط:
volumes:
  openclaw_home:

# و در بخش services.openclaw.volumes:
- openclaw_home:/home/node
```

## دستورات مفید

### مشاهده لاگ‌ها

```bash
docker compose -f docker-compose.simple.yml logs -f openclaw
```

### توقف

```bash
docker compose -f docker-compose.simple.yml down
```

### راه‌اندازی مجدد

```bash
docker compose -f docker-compose.simple.yml restart openclaw
```

### بررسی وضعیت

```bash
docker compose -f docker-compose.simple.yml ps
```

### دریافت Token

```bash
# از لاگ‌ها
docker compose -f docker-compose.simple.yml logs openclaw | grep Token

# یا از فایل تنظیمات
cat ~/.openclaw/openclaw.json | grep token
```

## مقایسه روش‌ها

| روش | مراحل | سختی | زمان |
|-----|-------|------|------|
| **ساده (این روش)** | 3 | ⭐ | 2 دقیقه |
| اتوماتیک | 3 | ⭐⭐ | 3 دقیقه |
| تعاملی | 5+ | ⭐⭐⭐ | 5 دقیقه |

## چرا این روش بهتره؟

### روش قدیمی (پیچیده):
```bash
# 1. اجرای اسکریپت setup
./docker-setup.sh

# 2. پاسخ به سوالات
# - Gateway bind? lan
# - Auth method? token
# - Token? ...
# - Tailscale? no
# - Install daemon? no

# 3. منتظر ماندن
# ...

# 4. اجرا
docker compose up -d
```

### روش جدید (ساده):
```bash
# 1. تنظیم image
echo 'OPENCLAW_IMAGE=ghcr.io/user/repo:latest' > .env

# 2. اجرا
docker compose -f docker-compose.simple.yml up -d

# تمام! 🎉
```

## عیب‌یابی

### خطا: Image not found

```bash
# بررسی نام image
cat .env | grep OPENCLAW_IMAGE

# Pull دستی
docker pull ghcr.io/USERNAME/REPO:latest
```

### Token گم شده

```bash
# از لاگ‌ها
docker compose -f docker-compose.simple.yml logs openclaw | grep Token

# از فایل تنظیمات
cat ~/.openclaw/openclaw.json
```

### پورت اشغال است

```bash
# تغییر پورت در .env
OPENCLAW_GATEWAY_PORT=8080

# راه‌اندازی مجدد
docker compose -f docker-compose.simple.yml up -d
```

### نمی‌توانم به Gateway دسترسی پیدا کنم

```bash
# بررسی وضعیت
docker compose -f docker-compose.simple.yml ps

# بررسی لاگ‌ها
docker compose -f docker-compose.simple.yml logs openclaw

# بررسی پورت
ss -tlnp | grep 18789
```

## سوالات متداول

### آیا باید اسکریپت اجرا کنم؟

**خیر!** فقط `docker compose up` کافیه.

### Token کجاست؟

```bash
# در لاگ‌ها
docker compose -f docker-compose.simple.yml logs openclaw | grep Token

# یا در فایل
cat ~/.openclaw/openclaw.json | grep token
```

### چطور تنظیمات رو تغییر بدم؟

```bash
# 1. ویرایش فایل تنظیمات
nano ~/.openclaw/openclaw.json

# 2. راه‌اندازی مجدد
docker compose -f docker-compose.simple.yml restart openclaw
```

### چطور Volume اضافه کنم؟

```bash
# 1. در .env
OPENCLAW_HOME_VOLUME=openclaw_home

# 2. در docker-compose.simple.yml
# uncomment کردن بخش volumes

# 3. راه‌اندازی مجدد
docker compose -f docker-compose.simple.yml up -d
```

## خلاصه

```bash
# نصب
cp .env.simple .env
echo 'OPENCLAW_IMAGE=ghcr.io/user/repo:latest' >> .env
docker compose -f docker-compose.simple.yml up -d

# دسترسی
docker compose -f docker-compose.simple.yml logs openclaw | grep Token
# باز کردن http://127.0.0.1:18789/

# مدیریت
docker compose -f docker-compose.simple.yml logs -f openclaw  # لاگ‌ها
docker compose -f docker-compose.simple.yml restart openclaw  # راه‌اندازی مجدد
docker compose -f docker-compose.simple.yml down             # توقف
```

## منابع بیشتر

- [Build Image با GitHub Actions](/install/docker-github-action-fa)
- [راهنمای کامل Docker](/install/docker-fa)
- [Mount در Docker](/install/docker-mount-explained-fa)

---

**نکته:** این ساده‌ترین روش است! اگر نیاز به تنظیمات پیشرفته دارید، از [روش کامل](/install/docker-fa) استفاده کنید.
