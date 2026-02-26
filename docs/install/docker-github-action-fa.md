---
summary: "راهنمای build کردن Docker image با GitHub Actions"
title: "Build Docker Image با GitHub Actions"
---

# Build کردن Docker Image با GitHub Actions

اگر به دلیل مشکلات شبکه (مثل فیلترینگ یا محدودیت دسترسی به `registry.npmjs.org`) نمی‌توانید روی سیستم خودتان Docker image بسازید، می‌توانید از GitHub Actions استفاده کنید.

## مزایا

- ✅ بدون نیاز به اینترنت قوی روی سیستم شما
- ✅ سرورهای GitHub به همه جا دسترسی دارند
- ✅ Image روی GitHub Container Registry ذخیره می‌شود
- ✅ می‌توانید از هر جایی image را pull کنید
- ✅ رایگان برای repository های public

## پیش‌نیازها

### 1. فعال‌سازی GitHub Container Registry

این کار به صورت خودکار انجام می‌شود، نیازی به تنظیمات اضافی نیست.

### 2. دسترسی‌های لازم (Permissions)

GitHub Actions به صورت خودکار دسترسی `GITHUB_TOKEN` دارد که برای push کردن image کافی است.

**نکته:** اگر repository شما private است، باید Package را public کنید یا با token شخصی دسترسی داشته باشید.

## روش 1: استفاده از Workflow آماده (توصیه می‌شود)

### مرحله 1: اجرای Workflow

1. به repository خود در GitHub بروید
2. به تب **Actions** بروید
3. از لیست سمت چپ، **Docker Build (Manual)** را انتخاب کنید
4. دکمه **Run workflow** را بزنید
5. تنظیمات را وارد کنید:
   - **tag**: نام tag برای image (مثلاً `latest` یا `dev` یا `v1.0.0`)
   - **platform**: پلتفرم مورد نظر:
     - `linux/amd64` - برای سیستم‌های معمولی (توصیه می‌شود)
     - `linux/arm64` - برای Raspberry Pi و Mac M1/M2
     - `linux/amd64,linux/arm64` - هر دو (زمان‌بر)
6. دکمه **Run workflow** سبز رنگ را بزنید

### مرحله 2: منتظر بمانید

Build کردن حدود 10-15 دقیقه طول می‌کشد. می‌توانید پیشرفت را در صفحه Actions ببینید.

### مرحله 3: استفاده از Image

بعد از اتمام build، image در آدرس زیر قرار دارد:

```
ghcr.io/USERNAME/REPO:TAG
```

مثال:
```
ghcr.io/myusername/openclaw:latest
```

## روش 2: استفاده از Image در سیستم خودتان

### گزینه A: Pull کردن Image

```bash
# Login به GitHub Container Registry
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull کردن image
docker pull ghcr.io/USERNAME/REPO:TAG

# مثال
docker pull ghcr.io/myusername/openclaw:latest
```

**نکته:** برای repository های public نیازی به login نیست.

### گزینه B: استفاده مستقیم در docker-setup.sh

```bash
# تنظیم متغیر محیطی
export OPENCLAW_IMAGE="ghcr.io/USERNAME/REPO:TAG"
assic)** را بزنید
4. دسترسی‌های زیر را انتخاب کنید:
   - ✅ `read:packages` - برای pull کردن image
   - ✅ `write:packages` - برای push کردن image (اختیاری)
5. **Generate token** را بزنید
6. Token را کپی کنید (فقط یک بار نمایش داده می‌شود!)

### مرحله 2: Login با Token

```bash
# ذخیره token در فایل
echo "YOUR_TOKEN" > ~/.github-token

# Login
cat ~/.github-token | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# حذف فایل token (امنیت)
rm ~/.github-token
```

## مشاهده و مدیریت Images

### لیست Images در GitHub

1. به repository خود بروید
2. سمت راست صفحه، بخش **Packages** را ببینید
3. روی package کلیک کنید

### حذف Image

```bash
# حذف از سیستم محلی
docker rmi ghcr.io/USERNAME/REPO:TAG

# حذف از GitHub Container Registry
# باید از رابط وب GitHub استفاده کنید
```

## عیب‌یابی

### خطا: permission denied

**علت:** دسترسی کافی ندارید.

**راه‌حل:**
```bash
# مطمئن شوید که login کرده‌اید
docker login ghcr.io -u YOUR_USERNAME

# یا repository را public کنید
```

### خطا: workflow failed

**علت:** ممکن است مشکلی در build باشد.

**راه‌حل:**
1. به تب Actions بروید
2. روی workflow شکست خورده کلیک کنید
3. لاگ‌ها را بررسی کنید

### Image خیلی بزرگ است

**علت:** Image کامل حدود 2-3 GB است.

**راه‌حل:**
- از اینترنت پرسرعت استفاده کنید
- یا image را روی سرور build کنید و از آنجا استفاده کنید

## مثال کامل: از صفر تا اجرا

```bash
# 1. اجرای workflow در GitHub
# (از رابط وب GitHub)

# 2. منتظر بمانید تا build تمام شود
# (10-15 دقیقه)

# 3. Pull کردن image
docker pull ghcr.io/myusername/openclaw:latest

# 4. استفاده در docker-setup
export OPENCLAW_IMAGE="ghcr.io/myusername/openclaw:latest"
./docker-setup.sh

# 5. دسترسی به رابط کاربری
# باز کردن http://127.0.0.1:18789/ در مرورگر
```

## Workflow خودکار (پیشرفته)

اگر می‌خواهید هر بار که کد را push می‌کنید، image به صورت خودکار build شود:

فایل `.github/workflows/docker-build-manual.yml` را ویرایش کنید:

```yaml
on:
  push:
    branches:
      - main  # یا branch دلخواه شما
  workflow_dispatch:
    # ...
```

حالا هر بار که به branch `main` push کنید، image به صورت خودکار build می‌شود.

## مقایسه روش‌ها

| روش | مزایا | معایب |
|-----|-------|-------|
| Build محلی | سریع، کنترل کامل | نیاز به اینترنت قوی |
| GitHub Actions | بدون نیاز به اینترنت قوی، رایگان | کمی کندتر، نیاز به GitHub |
| Docker Hub | عمومی، سریع | نیاز به حساب Docker Hub |

## نکات امنیتی

- ❌ هرگز token های خود را در کد commit نکنید
- ✅ از GitHub Secrets برای ذخیره token ها استفاده کنید
- ✅ به token ها فقط دسترسی‌های لازم بدهید
- ✅ token ها را به صورت دوره‌ای تغییر دهید

## منابع بیشتر

- [GitHub Container Registry Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

## خلاصه دستورات

```bash
# اجرای workflow
# (از رابط وب GitHub: Actions → Docker Build (Manual) → Run workflow)

# Pull کردن image
docker pull ghcr.io/USERNAME/REPO:TAG

# استفاده در docker-setup
export OPENCLAW_IMAGE="ghcr.io/USERNAME/REPO:TAG"
./docker-setup.sh

# مشاهده images محلی
docker images | grep openclaw

# حذف image محلی
docker rmi ghcr.io/USERNAME/REPO:TAG
```

---

**نکته مهم:** اگر repository شما private است، باید Package را public کنید یا با token دسترسی داشته باشید. برای repository های public، همه می‌توانند image را pull کنند.
