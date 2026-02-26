# 🚀 OpenClaw با Docker - روش ساده

## فقط 3 مرحله!

```bash
# 1. تنظیم image
cp .env.simple .env
nano .env  # فقط OPENCLAW_IMAGE را تنظیم کنید

# 2. اجرا
docker compose -f docker-compose.simple.yml up -d

# 3. دسترسی
docker compose -f docker-compose.simple.yml logs openclaw | grep Token
# باز کردن http://127.0.0.1:18789/
```

## چرا این روش؟

- ✅ **بدون اسکریپت** - فقط `docker compose up`
- ✅ **خودکار** - همه چیز خودش تنظیم می‌شه
- ✅ **ساده** - 2 دقیقه نصب

## Container خودش چه کارهایی انجام می‌ده؟

وقتی container راه‌اندازی می‌شه:

1. ✅ پوشه‌های مورد نیاز رو می‌سازه (`~/.openclaw/`)
2. ✅ Token تولید می‌کنه (اگر نداشته باشی)
3. ✅ فایل تنظیمات رو می‌سازه (`openclaw.json`)
4. ✅ Gateway رو راه‌اندازی می‌کنه

**شما فقط باید image رو تنظیم کنید و `up` بزنید!**

## مثال کامل

```bash
# کپی تنظیمات
cp .env.simple .env

# تنظیم image (از GitHub)
echo 'OPENCLAW_IMAGE=ghcr.io/myusername/openclaw:latest' >> .env

# اجرا
docker compose -f docker-compose.simple.yml up -d

# دریافت Token
docker compose -f docker-compose.simple.yml logs openclaw | grep Token
#    Token: abc123def456...

# دسترسی
open http://127.0.0.1:18789/
```

## دستورات مفید

```bash
# لاگ‌ها
docker compose -f docker-compose.simple.yml logs -f openclaw

# توقف
docker compose -f docker-compose.simple.yml down

# راه‌اندازی مجدد
docker compose -f docker-compose.simple.yml restart openclaw
```

## نیاز به Image؟

اگر مشکل شبکه دارید، از GitHub Actions استفاده کنید:

1. به repository خود در GitHub بروید
2. Actions → Docker Build (Manual) → Run workflow
3. منتظر بمانید (10-15 دقیقه)
4. استفاده:
   ```bash
   OPENCLAW_IMAGE=ghcr.io/USERNAME/REPO:latest
   ```

📖 [راهنمای کامل Build با GitHub Actions](docs/install/docker-github-action-fa.md)

## مستندات

- 📖 [راهنمای کامل روش ساده](docs/install/docker-simple-fa.md)
- 📖 [Build Image با GitHub Actions](docs/install/docker-github-action-fa.md)
- 📖 [راهنمای کامل Docker](docs/install/docker-fa.md)

---

**خلاصه:** فقط `docker compose up` بزن، بقیه‌اش خودکاره! 🎉
