# 🚀 راهنمای سریع Docker

## روش 1: اتوماتیک (توصیه می‌شود)

```bash
# 1. کپی تنظیمات
cp .env.docker.example .env

# 2. ویرایش (حداقل OPENCLAW_IMAGE را تنظیم کنید)
nano .env

# 3. اجرا
chmod +x docker-setup-auto.sh
./docker-setup-auto.sh

# 4. دسترسی
# باز کردن http://127.0.0.1:18789/ در مرورگر
```

## روش 2: تعاملی (با Wizard)

```bash
./docker-setup.sh
# به سوالات پاسخ دهید
```

## استفاده از GitHub Image

اگر مشکل شبکه دارید:

```bash
# 1. Image را در GitHub Actions بسازید
# (Actions → Docker Build (Manual) → Run workflow)

# 2. در .env تنظیم کنید
OPENCLAW_IMAGE=ghcr.io/USERNAME/REPO:latest

# 3. اجرا
./docker-setup-auto.sh
```

## مستندات کامل

- 📖 [نصب اتوماتیک](docs/install/docker-auto-setup-fa.md)
- 📖 [راهنمای Docker](docs/install/docker-fa.md)
- 📖 [Build با GitHub Actions](docs/install/docker-github-action-fa.md)
- 📖 [Mount در Docker](docs/install/docker-mount-explained-fa.md)

## دستورات مفید

```bash
# مشاهده لاگ‌ها
docker compose logs -f openclaw-gateway

# توقف
docker compose down

# راه‌اندازی مجدد
docker compose up -d openclaw-gateway
```

## نیاز به کمک؟

- [مستندات کامل](https://docs.openclaw.ai/)
- [GitHub Issues](https://github.com/openclaw/openclaw/issues)
