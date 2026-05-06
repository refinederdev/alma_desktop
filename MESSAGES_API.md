# Messages API Guide

هذا الملف يشرح جميع واجهات API الخاصة بالرسائل داخل المشروع وكيف تستخدمها عمليًا.

## Base URL

- Local: `http://localhost/api`
- كل endpoints (ما عدا webhooks) تتطلب `auth:sanctum`.

## Authentication

أرسل التوكن في الهيدر:

```http
Authorization: Bearer YOUR_TOKEN
Accept: application/json
```

مثال `curl`:

```bash
curl -X GET "http://localhost/api/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## 1) List Messages

- **Method:** `GET`
- **Endpoint:** `/messages`
- **Purpose:** جلب الرسائل مع pagination وفلاتر متعددة.

### Query Params (اختياري)

- `per_page` (default: 20)
- `deal_id`
- `crm_session_id`
- `from_me` (`true` / `false`)
- `message_type`
- `contact_phone`
- `search` (بحث داخل `message_body`)
- `date_from` (يُحوّل بـ `strtotime`)
- `date_to` (يُحوّل بـ `strtotime`)
- `order_dir` (`asc` أو `desc`, default: `desc`)

### Example

```bash
curl -G "http://localhost/api/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "deal_id=15" \
  --data-urlencode "from_me=true" \
  --data-urlencode "order_dir=desc" \
  --data-urlencode "per_page=50"
```

---

## 2) Get Single Message

- **Method:** `GET`
- **Endpoint:** `/messages/{id}`
- **Purpose:** جلب رسالة واحدة حسب ID من قاعدة البيانات.

### Example

```bash
curl -X GET "http://localhost/api/messages/120" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## 3) Create Message

- **Method:** `POST`
- **Endpoint:** `/messages`
- **Purpose:** إنشاء رسالة جديدة (نصية أو ميديا).  
  إذا `from_me=true` يتم إرسالها عبر مزود الـ CRM (Wasender) ثم حفظها.

### Body (form-data أو JSON حسب الحالة)

- `deal_id` **required**
- `from_me` **required** (`true` أو `false`)
- `message_body` optional (مطلوب فعليًا للرسالة النصية)
- `message_type` optional  
  القيم المدعومة:
  - `conversation`
  - `imageMessage`
  - `videoMessage`
  - `audioMessage`
  - `documentMessage`
  - `stickerMessage`
  - `locationMessage`
  - `pollMessage`
- `media` optional file (max 10MB)

### Text Message Example

```bash
curl -X POST "http://localhost/api/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "deal_id": 15,
    "from_me": true,
    "message_type": "conversation",
    "message_body": "Hello from API"
  }'
```

### Media Message Example

```bash
curl -X POST "http://localhost/api/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -F "deal_id=15" \
  -F "from_me=true" \
  -F "message_type=imageMessage" \
  -F "message_body=Caption text" \
  -F "media=@/absolute/path/image.jpg"
```

---

## 4) Update Message (Edit)

- **Method:** `PUT`
- **Endpoint:** `/messages/{id}`
- **Purpose:** تعديل الرسالة في قاعدة البيانات.

### Body

- `message_body` optional
- `media_url` optional (must be valid URL)
- `media_type` optional

### Example

```bash
curl -X PUT "http://localhost/api/messages/120" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "message_body": "Updated text from API"
  }'
```

### Important Note

- هذا endpoint يحدث الرسالة في قاعدة البيانات ويضع `edited_at` عند تعديل النص.
- لا يعتمد على `wasender msgId` داخل هذا الـ endpoint.

---

## 5) Delete Message

- **Method:** `DELETE`
- **Endpoint:** `/messages/{id}`
- **Purpose:** حذف الرسالة من قاعدة البيانات.

### Example

```bash
curl -X DELETE "http://localhost/api/messages/120" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## 6) Get Deal Messages

- **Method:** `GET`
- **Endpoint:** `/messages/deal/{dealId}`
- **Purpose:** جلب رسائل صفقة محددة.

### Query Params (اختياري)

- `per_page` (default: 50)
- `from_me`
- `message_type`
- `search`
- `order_dir` (`asc` / `desc`, default `desc`)

### Example

```bash
curl -G "http://localhost/api/messages/deal/15" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "per_page=100" \
  --data-urlencode "order_dir=asc"
```

---

## 7) Messages Stats

- **Method:** `GET`
- **Endpoint:** `/messages/stats`
- **Purpose:** إرجاع إحصائيات الرسائل:
  - `total_messages`
  - `sent`
  - `received`
  - `reply_rate`

### Example

```bash
curl -X GET "http://localhost/api/messages/stats" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## 8) Messages Line Chart

- **Method:** `GET`
- **Endpoint:** `/messages/linechart`
- **Purpose:** بيانات آخر 7 أيام (مرسل/مستقبل لكل يوم).

### Example

```bash
curl -X GET "http://localhost/api/messages/linechart" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## Message Object (Common Fields)

أغلب endpoints ترجع رسالة بصيغة قريبة من:

- `id`
- `deal_id`
- `crm_session_id`
- `message_id`
- `from_me`
- `message_timestamp`
- `status`
- `edited_at`
- `message_type`
- `message_type_display`
- `message_body`
- `has_media_content`
- `media_url`
- `media_type`
- `poll_data`
- `context_info`
- `created_at`
- `updated_at`

---

## Common Errors

- `401 Unauthorized`: التوكن غير موجود أو غير صالح.
- `403 Forbidden`: ليس لديك صلاحية الوصول للـ deal/message.
- `404 Not Found`: الرسالة أو الصفقة غير موجودة.
- `422 Validation Error`: البيانات غير صحيحة (مثال: `media_url` ليس URL صالح).

---

## Quick Postman Setup

1. أنشئ Collection جديدة.
2. اجعل Base URL متغير مثل: `{{base_url}} = http://localhost/api`
3. أضف Header ثابت:
   - `Authorization: Bearer {{token}}`
   - `Accept: application/json`
4. أضف endpoints المذكورة فوق بنفس المسارات.

