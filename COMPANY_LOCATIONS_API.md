# Company Locations API Guide (Branches)

هذا الملف يشرح واجهة API الخاصة بجلب “فروع/مواقع الشركة” من قاعدة البيانات (جدول `company_locations` / Model: `CompanyLocation`).

## Base URL

- Local: `http://localhost/api`
- جميع الـendpoints (ما عدا `webhooks`) تتطلب `auth:sanctum`.

## Authentication

أرسل التوكن في الهيدر:

```http
Authorization: Bearer YOUR_TOKEN
Accept: application/json
```

مثال `curl`:

```bash
curl -X GET "http://localhost/api/company-locations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## 1) List Company Locations (Branches)

- **Method:** `GET`
- **Endpoint:** `/company-locations`

### Query Params (اختياري)

- `active_only` (boolean)
  - إذا موجود يتم تطبيق الفلتر على `is_active`
  - مثال: `active_only=true` فقط الفعال
  - مثال: `active_only=false` كل شيء
- `is_active` (boolean)
  - نفس الفكرة، لكن بدلاً من `active_only`
  - إذا لم تمرر أي فلاتر يتم إرجاع الكل (active + inactive)
- `per_page` (integer)
  - إذا مررتها يتم إرجاع نتيجة Pagination
  - إذا لم تمرها يتم إرجاع كل البيانات مرة واحدة

### Example (الكل)

```bash
curl -G "http://localhost/api/company-locations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### Example (غير فعال / الكل عبر active_only=false)

```bash
curl -G "http://localhost/api/company-locations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "active_only=false"
```

### Example (Pagination)

```bash
curl -G "http://localhost/api/company-locations" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  --data-urlencode "per_page=50"
```

---

## Response Format

الـResponse يرجع بشكل مشابه لـ:

```json
{
  "success": true,
  "status_code": "success",
  "message": "تم جلب فروع الشركة بنجاح",
  "data": [
    {
      "id": 1,
      "name": "Branch Name (حسب اللغة)",
      "description": "الوصف (حسب اللغة)",
      "address": "العنوان",
      "latitude": 24.7136,
      "longitude": 46.6753,
      "manager_id": 10,
      "manager_name": "Full Name",
      "is_active": true,
      "is_open_now": true,
      "working_hours": [
        { "day": "sunday", "from": "09:00", "to": "18:00", "is_closed": false }
      ],
      "created_at": "2026-05-07T08:00:00+00:00",
      "updated_at": "2026-05-07T08:00:00+00:00"
    }
  ]
}
```

ملاحظة: `name` و `description` تعتمد على `app()->getLocale()` (أي لغة التطبيق الحالية). إذا كنت تحتاج لغة محددة لواجهة الـAPI، أخبرني ما طريقة ضبط اللغة عندك في الـapp (header/param/تسجيل الدخول) لأضبط مثال مناسب.

---

## 2) إرسال موقع فرع (Location Message) — Livewire vs Message API

### كيف يتم الإرسال حالياً داخل Livewire

المنطق موجود في `app/Livewire/Dashboard/Crm/ChatComponent.php` داخل الدالة `sendLocation()`:

- **تأكد من وجود** `selectedLocationId` و `selectedDealId`
- **قراءة الفرع** من `CompanyLocation`
- **إرسال الموقع** عبر `CrmService->sendLocation(...)`
- **إنشاء سجل Message** محلياً بنوع `locationMessage` وتخزين الإحداثيات داخل `message_data`

مرجع من الكود الحالي:

```3109:3204:app/Livewire/Dashboard/Crm/ChatComponent.php
    public function sendLocation()
    {
        // ... validations ...
        $location = CompanyLocation::find($this->selectedLocationId);
        // ...
        $crmService = new CrmService();
        $crmService->setApiKey($apiKey);

        $recipient = $deal->remote_jid ?: $deal->contact_phone;
        $response = $crmService->sendLocation(
            $recipient,
            (float) $location->latitude,
            (float) $location->longitude,
            $location->translated_name,
            $location->address
        );

        $messageId = $response['data']['msgId'] ?? $response['msgId'] ?? null;
        $currentTimestamp = now()->timestamp;

        $message = Message::create([
            // ...
            'message_type' => 'locationMessage',
            'message_body' => $location->translated_name . ($location->address ? "\n" . $location->address : ''),
            'message_data' => [
                'locationMessage' => [
                    'degreesLatitude' => (float) $location->latitude,
                    'degreesLongitude' => (float) $location->longitude,
                    'name' => $location->translated_name,
                    'address' => $location->address,
                ]
            ]
        ]);

        event(new MessageReceived($message, $deal));
    }
```

### نفس الفكرة عبر Message API

تم دعم إرسال موقع الفرع عبر `POST /api/messages` باستخدام `location_id`.

- **Method:** `POST`
- **Endpoint:** `/messages`
- **Headers:** نفس التوثيق في `docs/MESSAGES_API.md` (Bearer token)

#### Body (JSON)

- `deal_id` **required**
- `from_me` **required** (لازم `true` للإرسال)
- `location_id` **required** (ID من `company_locations`)
- `message_type` اختياري (لو أرسلت `location_id` سيتم اعتباره `locationMessage` تلقائياً)

#### Example (curl)

```bash
curl -X POST "http://localhost/api/messages" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "deal_id": 15,
    "from_me": true,
    "location_id": 3
  }'
```

#### Example (Livewire call to API)

الفكرة: بدلاً من استدعاء `CrmService` مباشرة داخل Livewire، استدعي `Message API`:

```php
use Illuminate\Support\Facades\Http;

$response = Http::withToken($token)
    ->acceptJson()
    ->post(url('/api/messages'), [
        'deal_id' => (int) $dealId,
        'from_me' => true,
        'location_id' => (int) $locationId,
    ]);

// $response->json() يحتوي على MessageResource للرسالة المنشأة
```

> ملاحظة: الـAPI سيقوم بإرسال الموقع عبر Wasender (CrmService) ثم حفظ الرسالة محلياً بنفس شكل Livewire.

