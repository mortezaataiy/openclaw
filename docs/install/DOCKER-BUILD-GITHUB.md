# 🚀 راهنمای سریع: Build Docker Image با GitHub Actions

## مشکل شما

```
Error: getaddrinfo EAI_AGAIN registry.npmjs.org
```

نمی‌توانید روی سیستم خودتان Docker image بسازید به دلیل مشکلات شبکه.

## راه‌حل: استفاده از GitHub Actions

### قدم 1: اجرای Workflow

1. به repository خود در GitHub بروید
2. تب **Actions** → **Docker Build (Manual)**
3. **Run workflow** → تنظیمات:
   - **tag**: `latest`
   - **platform**: `linux/amd64`
4. **Run workflow** (دکمه سبز)

⏱️ منتظر بمانید: 10-15 دقیقه

### قدم 2: استفاده از Image

```bash
# تنظیم image
export OPENCLAW_IMAGE="ghcr.io/USERNAME/REPO:latest"

# اجرا
./docker-setup.sh
```

**جایگزین کنید:**
- `USERNAME` → نام کاربری GitHub شما
- `REPO` → نام repository شما

### مثال واقعی

```bash
# اگر repository شما این است:
# https://github.com/myusername/openclaw

export OPENCLAW_IMAGE="ghcr.io/myusername/openclaw:latest"
./docker-setup.sh
```

## نیاز به Token؟

**برای repository های public:** خیر، نیازی نیست!

**برای repository های private:**

```bash
# 1. ساخت token در GitHub:
# Settings → Developer settings → Personal access tokens
# دسترسی: read:packages

# 2. Login
echo "YOUR_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 3. Pull
docker pull ghcr.io/USERNAME/REPO:latest
```

## مستندات کامل

📖 [راهنمای کامل فارسی](/install/docker-github-action-fa)

## خلاصه

```bash
# 1. اجرای workflow در GitHub (رابط وب)
# 2. منتظر بمانید (10-15 دقیقه)
# 3. استفاده:

export OPENCLAW_IMAGE="ghcr.io/USERNAME/REPO:latest"
./docker-setup.sh
```

✅ حل شد!
