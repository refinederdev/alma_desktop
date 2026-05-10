# Messages API Guide

هذا الملف يشرح جميع واجهات API الخاصة بالرسائل داخل المشروع وكيف تستخدمها عمليًا.

## آخر التحديثات

| التاريخ | التغيير |
|---------|---------|
| 2026-05-10 | **تاريخ العميل الكامل (Full history)** على مسار `GET /messages/deal/{dealId}`: معامل اختياري `full_history` يجمع رسائل **كل الصفقات** التي تشترك مع الصفقة الحالية في `contact_phone` (نفس سلوك شاشة CRM «عرض التاريخ الكامل»). يتطلب صلاحية `crm.chat.view_full_history`. عند التفعيل تُعاد كائنات الرسائل مع حقل `deal` (عنوان الصفقة وحالتها) لتمييز أي صفقة جاءت منها الرسالة. |

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
- **Purpose:** تعديل الرسالة بنفس سلوك الشات (Livewire):  
  1) تعديل الرسالة على Wasender  
  2) ثم تحديث قاعدة البيانات محليًا

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

- عند إرسال `message_body` يتم تنفيذ تعديل على Wasender أولًا.
- شروط التعديل النصي (مثل الشات):
  - الرسالة تكون `from_me=true`
  - نوع الرسالة `conversation`
  - الرسالة غير معدلة سابقًا (`edited_at` فارغ)
  - `message_id` يكون رقم Wasender صالح
- إذا فشل Wasender، لن يتم تحديث قاعدة البيانات.

---

## 5) Delete Message

- **Method:** `DELETE`
- **Endpoint:** `/messages/{id}`
- **Purpose:** حذف الرسالة بنفس سلوك الشات (Livewire):  
  1) حذف الرسالة من Wasender  
  2) ثم حذفها من قاعدة البيانات

### Example

```bash
curl -X DELETE "http://localhost/api/messages/120" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### Important Note

- الحذف عبر هذا endpoint يتطلب:
  - الرسالة تكون `from_me=true`
  - `message_id` يكون رقم Wasender صالح
  - وجود CRM session + API key
- إذا فشل الحذف على Wasender، لن يتم حذف الرسالة محليًا.

---

## 6) Get Deal Messages

- **Method:** `GET`
- **Endpoint:** `/messages/deal/{dealId}`
- **Purpose:** جلب رسائل صفقة محددة، أو — عند تفعيل الخيار أدناه — جلب **كل رسائل نفس العميل** عبر كل صفقاته المرتبطة بنفس رقم الهاتف.

### Query Params (اختياري)

- `per_page` (default: 50)
- `from_me`
- `message_type`
- `search`
- `order_dir` (`asc` / `desc`, default `desc`)
- **`full_history`** (`true` / `false` أو `1` / `0`): عند `true` يتم جلب الرسائل من **جميع** الصفقات التي لها نفس `contact_phone` للصفقة `{dealId}`. يجب أن يملك المستخدم صلاحية **`crm.chat.view_full_history`**؛ وإلا يُرجع الـ API **`403 Forbidden`**.

### السلوك الافتراضي (`full_history` غير مفعّل أو `false`)

- يُجلب فقط: `deal_id = {dealId}`.
- لا يُضاف حقل **`meta`** في جسم الاستجابة (للتوافق مع العملاء القدامى).

### تاريخ العميل الكامل (`full_history=true`)

1. يُتحقق من أن المستخدم يملك صلاحية رؤية الصفقة `{dealId}` (كالعادة عبر `Deal::forUser`).
2. يُحدَّد `contact_phone` للصفقة الحالية.
3. إذا وُجد الرقم: تُجمع كل معرفات الصفقات `deal_ids` من جدول الصفقات حيث `contact_phone` مطابق، وتُجلب الرسائل حيث `deal_id` ضمن هذه القائمة.
4. تُحمَّل علاقة **`deal`** لكل رسالة (حقول مختصرة: `id`, `title`, `status`) حتى يعرض تطبيق الجوال من أي صفقة أتت الرسالة.
5. يُضاف في الاستجابة حقل **`meta`** (يظهر فقط عند `full_history=true`):

| مفتاح `meta` | المعنى |
|----------------|--------|
| `full_history` | `true` |
| `contact_phone` | رقم العميل المستخدم للربط، أو `null` إن لم يكن محفوظًا على الصفقة |
| `deal_ids` | مصفوفة أرقام الصفقات المشمولة في الطلب |
| `full_history_note` | يظهر فقط عند غياب `contact_phone` على الصفقة: القيمة `no_contact_phone_on_deal` (في هذه الحالة يبقى النطاق = صفقة واحدة فقط `{dealId}`) |

### أمثلة — صفقة واحدة (كالسابق)

```bash
curl -G "http://localhost/api/messages/deal/15" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "per_page=100" \
  --data-urlencode "order_dir=asc"
```

### مثال — تطبيق الجوال: تاريخ العميل الكامل عبر كل الصفقات

```bash
curl -G "http://localhost/api/messages/deal/15" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "full_history=1" \
  --data-urlencode "per_page=50" \
  --data-urlencode "order_dir=desc"
```

### ملاحظات لتطبيق الجوال

- استخدم **`full_history=1`** عندما يفعّل المستخدم «عرض كل المحادثات مع هذا الرقم» (أو ما يعادله في الواجهة).
- عالج **`403`**: إخفِ الخيار أو اعرض رسالة أن المستخدم لا يملك صلاحية عرض التاريخ الكامل.
- الرسائل قد تأتي من صفقات متعددة؛ استخدم **`deal.id` / `deal.title` / `deal.status`** داخل كل عنصر رسالة لعرض شارة الصفقة إن رغبت.
- **ما لا يشمله هذا المسار:** أحداث سجل الصفقة النظامية (تعيين، تحويل، دفع…) التي يدمجها الويب في الشات — هذا المسار يوسّع **الرسائل فقط** بين الصفقات.

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
- **`deal`** (اختياري): يظهر عندما يُحمَّل من الخادم؛ في **`GET /messages/deal/{dealId}` مع `full_history=1`** يُعاد كائن الصفقة المختصر (`id`, `title`, `status`, …) لمعرفة مصدر الرسالة عند دمج عدة صفقات.

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

