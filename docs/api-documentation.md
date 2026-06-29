# مستندات API افزونه اپ مشخصات محصول

هدر احراز هویت برای همه درخواست‌ها:

```text
Authorization: Bearer YOUR_TOKEN
```

## تست اتصال

```text
GET /wp-json/product-specs/v1/ping
```

## دریافت دسته‌بندی‌ها

```text
GET /wp-json/product-specs/v1/categories
```

## دریافت محصولات

```text
GET /wp-json/product-specs/v1/products?category_id=12&search=&sort=newest&page=1&per_page=30
```

مقادیر sort:

```text
newest
name
price
```

## دریافت جزئیات محصول

```text
GET /wp-json/product-specs/v1/products/123
```

## ذخیره مشخصات محصول

```text
POST /wp-json/product-specs/v1/products/123/specs
```

بدنه نمونه:

```json
{
  "mode": "append",
  "specs": [
    {"name": "قطر", "value": "۱۰ میلی‌متر"},
    {"name": "طول", "value": "۸۰ میلی‌متر"},
    {"name": "جنس", "value": "فولاد تندبر"}
  ],
  "raw_text": "متن خام ویس",
  "ai_provider": "openai",
  "product_content": "متن یک پاراگرافی محصول. این محصول با ارسال فوری از بازار قفل سفارش بدید"
}
```

حالت‌ها:

```text
append = افزودن به مشخصات قبلی
replace = جایگزینی ویژگی‌های اختصاصی قبلی
```


## ذخیره محتوای محصول

اگر مقدار `product_content` ارسال شود، افزونه آن را به‌عنوان توضیح کوتاه محصول ووکامرس ذخیره می‌کند.

افزونه برای اطمینان، اگر جمله زیر در انتهای متن نبود، آن را اضافه می‌کند:

```text
این محصول با ارسال فوری از بازار قفل سفارش بدید
```

## API ورود وردپرس

```http
POST /wp-json/product-specs/v1/login
Authorization: Bearer YOUR_APP_TOKEN
Content-Type: application/json
```

ورودی:

```json
{
  "username": "admin",
  "password": "wordpress-password"
}
```

فقط کاربران با نقش `administrator` یا `shop_manager` اجازه ورود دارند. بعد از ۵ ورود اشتباه، ورود به مدت ۱۰ دقیقه قفل می‌شود.

## فیلدهای جدید ذخیره محصول

در endpoint ذخیره مشخصات، این فیلدها هم پشتیبانی می‌شوند:

```json
{
  "product_content": "توضیح یک پاراگرافی محصول",
  "seo_title": "عنوان سئو",
  "seo_description": "توضیح متا"
}
```

افزونه عنوان و توضیح متا را برای RankMath، Yoast و AIOSEO به‌صورت meta ذخیره می‌کند.
