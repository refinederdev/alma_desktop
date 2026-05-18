# WhatsApp Cloud Calling — Mobile / Flutter Integration Guide

This document is the **server-side contract** for integrating WhatsApp voice
calls (Cloud API) into a mobile client. It assumes the client already has:

- A Sanctum bearer token (same auth as the rest of `/api/*`)
- A working **Laravel Echo / Pusher-protocol WebSocket** client connected to
  Reverb (already used for chat)
- A **WebRTC** stack (e.g. `flutter_webrtc` for Flutter, or any browser
  equivalent). The platform doesn't matter — this API only ferries SDP
  strings; the mobile side is responsible for generating the local
  offer / answer and rendering audio.

> **Why WebRTC?** WhatsApp voice calls travel over a WebRTC peer connection
> between the agent's device and Meta's media servers. The Laravel backend
> never sees the audio — it only acts as the **signaling channel** (forwards
> SDP to Meta, broadcasts realtime events back to the device).

---

## 1. Architecture in 1 minute

```
                      ┌─────────────────────┐
                      │   Meta Cloud API    │  ← Audio (WebRTC)
                      │  (Graph + media)    │
                      └─────────┬───────────┘
                                │
              webhooks ↓        │ Audio peer connection
                                │   (SDP exchanged via API)
┌──────────────────────┐        │        ┌───────────────────────────┐
│   Laravel backend    │ ───────┘        │   Mobile app (Flutter)    │
│  - REST API          │                 │  - Sanctum token          │
│  - Reverb broadcast  │ ←── realtime ──►│  - Reverb WS subscription │
│  - DB (calls table)  │                 │  - WebRTC peer connection │
└──────────────────────┘                 └───────────────────────────┘
```

**Three concurrent transports:**

1. **HTTPS REST** — the mobile app calls the endpoints under `/api/whatsapp-calls/*`
   to fetch state and to send SDP / actions.
2. **WebSocket (Reverb)** — the mobile app subscribes to `private-calls.{sessionId}`
   to receive realtime events (incoming call, callee answered, callee hung up, etc.).
3. **WebRTC peer-to-peer** — audio media. The mobile WebRTC stack speaks
   directly to Meta's media server; the SDP strings are exchanged over the
   REST + WebSocket transports above.

---

## 2. Authentication

All endpoints below require the standard Sanctum bearer token:

```http
Authorization: Bearer {user_token}
Accept: application/json
```

Get a token via `POST /api/auth/login` (see existing auth docs).

The **Reverb** WebSocket connection uses the same token for the auth endpoint
(`POST /broadcasting/auth`). See `FLUTTER_REVERB_INTEGRATION.md` for the
exact handshake — there is no difference for the calls channel.

---

## 3. Realtime channel & events

### 3.1 The channel

Every CRM session (each WhatsApp Business phone number) has its own private
channel:

```
private-calls.{sessionId}
```

`sessionId` is the integer returned by `GET /api/whatsapp-calls/sessions`.
Authorization is granted automatically when the authed user is either the
owner of that CRM session or an admin/super-admin.

The mobile app should **subscribe once per session at app start** (after
fetching the session list) and stay subscribed for the lifetime of the
session.

### 3.2 The event name

All call events are broadcast with a single name (Pusher format):

```
.call.event
```

(The leading dot tells Echo it's a custom event name, not a class name.)

### 3.3 Event payload shape

Every broadcast has the same envelope:

```json
{
  "type": "incoming_call",
  "call": {
    "id": 123,
    "call_id": "wamid.HBgL...",
    "direction": "inbound",
    "status": "ringing",
    "caller_phone": "971501234567",
    "callee_phone": "971557654321",
    "remote_phone": "971501234567",
    "duration": "00:00",
    "deal_id": 42,
    "contact_name": "Ahmed",
    "sdp_offer": "v=0\r\no=- ... (only on incoming_call) ...",
    "sdp_answer": "v=0\r\no=- ... (only on call_connected) ..."
  },
  "session_id": 7,
  "timestamp": "2026-05-18T07:15:32+00:00"
}
```

### 3.4 The 6 event types

| `type`              | Direction the event represents       | Action the mobile app must take                                                  |
|---------------------|--------------------------------------|----------------------------------------------------------------------------------|
| `incoming_call`     | Inbound (user → agent)               | Ring loudly + show accept/reject UI. Read `call.sdp_offer` for the SDP to answer with. |
| `call_connected`    | Outbound (agent → user) ack from Meta | Take `call.sdp_answer` and pass it to your WebRTC peer's `setRemoteDescription`. |
| `call_ringing`      | Outbound, callee's phone is ringing  | Optional UX — show "ringing…" indicator.                                          |
| `call_accepted`     | Outbound, callee answered            | Switch UI to "in progress" + start the local call timer.                          |
| `call_rejected`     | Outbound, callee rejected            | Stop audio + show "rejected" notice.                                              |
| `call_terminated`   | Either side ended the call           | Stop audio + close peer connection + show "ended" / call summary.                 |

> The `call_terminated` event is the **only** authoritative source of "the
> call has truly ended" — always tear down WebRTC and the UI on this event.

---

## 4. REST endpoints

Base path: `/api/whatsapp-calls`. All endpoints return the standard wrapper:

```json
{
  "success": true,
  "status_code": "SUCCESS",
  "message": "...",
  "data": { ... }
}
```

On failure:

```json
{
  "success": false,
  "status_code": "ERROR",
  "message": "Human-readable error",
  "errors": { ... optional details ... }
}
```

### 4.1 List sessions

```
GET /api/whatsapp-calls/sessions
```

**Response:**

```json
{
  "data": {
    "sessions": [
      {
        "id": 7,
        "session_name": "Sales line",
        "phone_number": "971557654321",
        "phone_number_id": "1234567890",
        "status": "active",
        "realtime_channel": "calls.7"
      }
    ],
    "ice_servers": [
      { "urls": "stun:stun.l.google.com:19302" },
      { "urls": "stun:stun1.l.google.com:19302" }
    ]
  }
}
```

The `ice_servers` array is what you pass to your WebRTC peer connection
constructor. The `realtime_channel` is the Reverb channel for incoming events.

### 4.2 Enable / disable calling

Required **once per phone number** before calls work. Stored at Meta.

```
POST /api/whatsapp-calls/sessions/{sessionId}/enable
POST /api/whatsapp-calls/sessions/{sessionId}/disable
```

No body. Response:

```json
{ "data": { "session_id": 7, "calling_enabled": true } }
```

### 4.3 Get the active call (rehydration)

Use on app launch or after a network blip to find out if a call is ongoing.

```
GET /api/whatsapp-calls/active?session_id=7
```

**Response (no active call):**

```json
{ "data": { "call": null } }
```

**Response (active call):** the full `WhatsAppCallResource` including
`sdp_offer` (if inbound, still ringing) and `sdp_answer` (if outbound,
already connected).

### 4.4 Get one call by id

```
GET /api/whatsapp-calls/{id}?include_sdp=1
```

`include_sdp=1` adds the SDP strings to the response. Omit / use `0` for
list views — SDP strings can be tens of kilobytes.

### 4.5 Get SDP only

```
GET /api/whatsapp-calls/{id}/sdp
```

Minimal payload — useful right after receiving an `incoming_call` event
when you only need the SDP to feed into WebRTC.

```json
{
  "data": {
    "call_id": "wamid.HBgL...",
    "status": "ringing",
    "sdp_offer": "v=0\r\no=- ...",
    "sdp_answer": null
  }
}
```

### 4.6 Call history (paginated)

```
GET /api/whatsapp-calls/history?session_id=7&per_page=20&direction=inbound&status=completed&deal_id=42
```

All filters except `session_id` are optional. Returns standard paginated
shape with `data`, `meta.pagination`, etc.

### 4.7 Initiate an outbound call

```
POST /api/whatsapp-calls/initiate
```

**Body:**

```json
{
  "session_id": 7,
  "to": "971501234567",
  "sdp_offer": "v=0\r\no=- ..."
}
```

**Flow before calling this endpoint:**

1. Mobile creates a WebRTC `RTCPeerConnection` with the ICE servers from
   `/sessions`.
2. Add a microphone track to it.
3. `await peer.createOffer()` → get the local SDP.
4. `await peer.setLocalDescription(offer)` (with `iceComplete: true` so the
   full SDP is gathered before sending).
5. POST the SDP string here.

**Response:**

```json
{
  "data": {
    "call": {
      "id": 999,
      "call_id": "wamid.HBgL...",
      "direction": "outbound",
      "status": "ringing",
      "callee_phone": "971501234567",
      ...
    }
  }
}
```

**What happens next:** Meta will send back the SDP answer via the
**`call_connected`** realtime event (usually within 1–2s). You must:

```dart
// Pseudocode
peer.setRemoteDescription(RTCSessionDescription(
  payload.call.sdp_answer,
  'answer',
));
```

After that, the audio path is open. The actual "callee picked up" moment
arrives as the **`call_accepted`** event — that's when the timer should
start.

### 4.8 Accept an incoming call

```
POST /api/whatsapp-calls/{id}/accept
```

**Body:**

```json
{ "sdp_answer": "v=0\r\no=- ..." }
```

**Flow before calling this endpoint:**

1. You received an `incoming_call` realtime event with `call.sdp_offer`.
2. Create a WebRTC `RTCPeerConnection` with the ICE servers.
3. Add a mic track.
4. `await peer.setRemoteDescription(RTCSessionDescription(sdp_offer, 'offer'))`.
5. `await peer.createAnswer()`.
6. `await peer.setLocalDescription(answer)`.
7. POST the answer SDP here.

**Response:**

```json
{
  "data": {
    "call": {
      "id": 123,
      "status": "in_progress",
      ...
    }
  }
}
```

After this returns, the call timer should be running and audio should be
flowing. A `call_terminated` event will arrive when either side hangs up.

> **Tip — optimistic UI:** as soon as the user taps "Answer", switch the UI
> to a "Connecting…" state immediately. Don't wait for this API to return —
> the Meta round-trip takes ~1–2 seconds and the user will think the app
> is frozen otherwise.

### 4.9 Pre-accept (optional fast path)

```
POST /api/whatsapp-calls/{id}/pre-accept
```

Same body as accept. Sends the SDP answer to Meta but doesn't formally
accept yet — audio path opens slightly faster. **Most apps can skip this
and just use `/accept` directly.** It exists if you want to squeeze a few
hundred ms off the time-to-first-audio.

### 4.10 Reject an incoming call

```
POST /api/whatsapp-calls/{id}/reject
```

No body. Use this when the agent taps the red "Reject" button on a ringing
call. Idempotent — safe to call even if the call is already terminated.

### 4.11 Terminate an in-progress call

```
POST /api/whatsapp-calls/{id}/terminate
```

No body. Hang up the call. Server calculates `duration_seconds` from
`started_at`. You'll also receive a `call_terminated` realtime event right
after — listen for it as the authoritative "tear everything down" signal
(otherwise the UI desyncs if the **other** side hangs up first).

### 4.12 Check call permission

Meta requires the WhatsApp user to have granted call permission before you
can call them. Check it like this:

```
POST /api/whatsapp-calls/permissions/check
```

**Body:**

```json
{ "session_id": 7, "user_phone": "971501234567" }
```

Returns Meta's permission record. If the user hasn't granted permission,
you must request it first (next endpoint).

### 4.13 Request call permission

Sends a template message to the user with a "Allow calls" button.

```
POST /api/whatsapp-calls/permissions/request
```

**Body:**

```json
{
  "session_id": 7,
  "to": "971501234567",
  "template_name": "call_permission_request",
  "language_code": "en_US"
}
```

`template_name` and `language_code` are optional (defaults shown). The
template must be **pre-approved by Meta** for your business account.

Permission lasts 7 days after the user grants it.

---

## 5. Call lifecycles — end-to-end

### 5.1 Inbound call (user calls the business)

```
1. User dials the business number from their WhatsApp.

2. Meta hits the Laravel webhook → backend stores the call row with
   status="ringing" and the SDP offer, then broadcasts:

      type=incoming_call
      call.sdp_offer = "v=0\r\no=- ..."
      call.id = 123
      call.caller_phone, contact_name, deal_id

3. Mobile receives event over Reverb → plays ringtone + shows UI.

4. User taps Accept → mobile:
   - GET /api/whatsapp-calls/123/sdp   (only if SDP wasn't in the event)
   - Create RTCPeerConnection with ICE servers from /sessions
   - Add mic track
   - setRemoteDescription(sdp_offer, 'offer')
   - createAnswer() → setLocalDescription()
   - POST /api/whatsapp-calls/123/accept { sdp_answer }

5. Backend forwards pre_accept + accept to Meta → DB status=in_progress
   → broadcasts type=call_accepted (sometimes also call_connected).

6. Audio is now flowing peer-to-peer with Meta. Local timer starts.

7. User hangs up OR mobile POSTs /terminate:
   → Meta sends the terminate webhook
   → backend broadcasts type=call_terminated
   → mobile: stop audio, close peer, show summary.
```

**Or — user taps Reject:**

```
4'. POST /api/whatsapp-calls/123/reject
    → backend tells Meta + DB status=rejected
    → broadcasts type=call_rejected
    → mobile dismisses the ringing UI.
```

### 5.2 Outbound call (business calls the user)

```
1. (One-time per user, valid for 7 days)
   Check permission: POST /api/whatsapp-calls/permissions/check
   If "no permission": POST /api/whatsapp-calls/permissions/request
   → User taps "Allow" in their WhatsApp.

2. Mobile creates the local SDP offer:
   - RTCPeerConnection(ice servers)
   - Add mic track
   - createOffer() → setLocalDescription()
   - Wait for ICE gathering to complete (so the offer has all candidates).

3. POST /api/whatsapp-calls/initiate
      { session_id, to, sdp_offer }
   → backend forwards to Meta → DB row created (status=ringing)
   → API responds with the call.id.

4. Show "Calling…" UI on the mobile side.

5. Backend receives webhook from Meta with the SDP answer
   → broadcasts type=call_connected
      call.sdp_answer = "v=0\r\no=- ..."
   → mobile: peer.setRemoteDescription(answer, 'answer')
   → ICE candidates start flowing, audio path opens (one-way for now).

6. Optionally Meta broadcasts type=call_ringing — "callee's phone is ringing".

7. Callee answers → Meta broadcasts type=call_accepted
   → mobile: switch UI to "in progress", start timer.

8. Either side hangs up → call_terminated → tear down.
```

**Or — callee declines:**

```
7'. type=call_rejected → close UI.
```

**Or — callee never picks up:**

```
7''. Eventually type=call_terminated arrives with status=missed in the
     final call payload (check call.status).
```

---

## 6. WebRTC details the mobile side must handle

This API doesn't constrain the mobile WebRTC implementation, but a few
points are worth flagging:

### 6.1 SDP line endings

Chrome / libwebrtc are strict about CRLF (`\r\n`). If you transmit an SDP
string through any pipeline that normalizes line endings to LF (`\n`), you
**must** re-canonicalize before calling `setRemoteDescription`:

```
normalized = sdp.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n').trim() + '\r\n'
```

The web softphone has reference code for this in `public/js/whatsapp-webrtc.js`
(method `_normalizeSdp`).

### 6.2 ICE servers

Use exactly what `/api/whatsapp-calls/sessions` returns. Don't hardcode
extra TURN servers unless you know they're routable to Meta — they could
slow down ICE gathering.

### 6.3 The peer connection lifecycle

- **One peer per call.** Don't reuse the same `RTCPeerConnection` across
  consecutive calls — always close and recreate.
- **Audio only.** No video tracks.
- **Mic permission is required** every time on iOS until the user grants
  it; Android remembers it. Request it BEFORE you build the offer/answer.
- **Close the peer connection** on `call_terminated` even if your local
  state already thinks the call is over — Meta may have sent a hangup that
  arrived after your local termination.

### 6.4 Call timer

Don't rely on `peer.onconnectionstatechange === 'connected'` alone to
start the timer — that event isn't always reliable across libwebrtc
versions. Drive the timer off the **`call_accepted`** realtime event
instead, which is the canonical "call is now happening" signal from Meta.

For page refresh / app restart during an active call:

- The `call.started_at` field on the active call row is the source of
  truth for elapsed time.
- After `GET /api/whatsapp-calls/active` returns an in-progress call,
  compute `elapsed = now() - started_at` and start the timer from there.

---

## 7. Error handling

All endpoints return one of these HTTP statuses on failure:

| Status | When                                                                       |
|--------|----------------------------------------------------------------------------|
| 401    | Missing / expired Sanctum token                                            |
| 403    | Authenticated user doesn't own the session or the call                     |
| 404    | Session / call not found                                                   |
| 422    | Validation error OR Meta API rejected the request (SDP invalid, no perm, etc.) |
| 500    | Unexpected server error (also logged with full context)                    |

Meta-side errors come back in the message field:

```json
{
  "success": false,
  "message": "accept failed: Call API Error (131009): Parameter value is not valid"
}
```

**Common Meta error codes** (full list at
<https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes>):

| Code   | Meaning                                                | Common cause                                            |
|--------|--------------------------------------------------------|---------------------------------------------------------|
| 131009 | Parameter value is not valid                           | SDP malformed, or call_id stale (already terminated)    |
| 131056 | Call permission required                               | User hasn't granted permission via template             |
| 131055 | Call already in non-actionable state                   | E.g. trying to accept an already-terminated call         |
| 100    | Generic parameter error                                | Wrong phone number format (must be E.164 without +)     |

If you get **131009 on accept**: the SDP answer was probably built from a
stale offer. Re-fetch the offer with `GET /{id}/sdp` and rebuild the answer.

---

## 8. Polling fallback

If the WebSocket isn't available (background, no network, etc.), the
client can poll `GET /api/whatsapp-calls/active?session_id=X` every
3–5 seconds to detect:

- A new inbound call (response goes from `call: null` → ringing call)
- A status transition (ringing → in_progress → completed)
- Termination from the other side (active → `call: null`)

When realtime is back, **stop polling immediately** — duplicate detection
will otherwise show the same call twice.

---

## 9. Quick reference — request/response checklist

| Mobile action            | HTTP                                       | Realtime event you'll then receive       |
|--------------------------|--------------------------------------------|------------------------------------------|
| App startup              | `GET /sessions` → subscribe to channels    | (none until calls happen)                |
| App resume               | `GET /active?session_id=X` per session     | (any active call rehydrated)              |
| User → me (incoming)     | (none)                                     | `incoming_call`                          |
| Tap Accept               | `POST /{id}/accept { sdp_answer }`         | `call_accepted` (+ later `call_terminated`) |
| Tap Reject               | `POST /{id}/reject`                        | `call_rejected`                          |
| Tap Call (outbound)      | `POST /initiate { session_id, to, sdp_offer }` | `call_connected` → `call_ringing` → `call_accepted` |
| Tap Hang up              | `POST /{id}/terminate`                     | `call_terminated`                        |
| User hangs up first      | (none)                                     | `call_terminated`                        |
| View history             | `GET /history?session_id=X`                | —                                        |
| Need permission          | `POST /permissions/request`                | (the user accepts inside their WhatsApp) |

---

## 10. File-by-file reference (for backend developers)

If you need to dig into the implementation:

- **Controller:** `app/Http/Controllers/Api/WhatsAppCallController.php`
- **Resource:** `app/Http/Resources/Api/WhatsAppCallResource.php`
- **Model:** `app/Models/WhatsAppCall.php`
- **Provider (Meta API wrapper):** `app/Services/Providers/WhatsAppCloudProvider.php`
- **Broadcast event:** `app/Events/CallEvent.php`
- **Webhook handler:** `app/Http/Controllers/Crm/WhatsAppCloudWebhookController.php`
- **Channel auth:** `routes/channels.php` (search `calls.{sessionId}`)
- **API routes:** `routes/api.php` (search `whatsapp-calls`)
- **ICE config:** `config/whatsapp_cloud.php`
- **Reference web softphone (uses same Provider):**
  - PHP: `app/Livewire/Dashboard/WhatsAppCloud/WhatsAppCallComponent.php`
  - View: `resources/views/livewire/dashboard/whatsapp-cloud/whatsapp-call-component.blade.php`
  - WebRTC JS: `public/js/whatsapp-webrtc.js`

The web softphone uses the same `WhatsAppCloudProvider` and the same
`call.event` broadcast — anything that works on the web also works on
mobile through this API.
