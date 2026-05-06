# Reverb Events Reference for Desktop App

This document lists all Laravel Reverb events currently broadcast by this project and explains:

- what each event means
- when it is emitted
- which channel(s) receive it
- who is allowed to subscribe
- what payload shape to expect

Use this as your implementation guide when building a desktop client (Electron, Tauri, native wrapper, etc.).

---

## 1) Connection Basics

The project uses Laravel Echo + Reverb (Pusher protocol compatible).

- Broadcaster: `reverb`
- Private channel auth endpoint: `/broadcasting/auth`
- Channel auth rules are defined in `routes/channels.php`

All channels below are **private channels**, so your desktop app must:

1. authenticate the user first
2. send auth credentials to `/broadcasting/auth`
3. subscribe only to channels the user is authorized for

---

## 2) Channels You Can Subscribe To

### `private-deal.{dealId}`
- **Purpose:** Real-time updates for a specific deal/chat thread.
- **Who can subscribe:**
  - admins/super-admins: any deal
  - agents: only deals assigned to them
- **Auth rule location:** `routes/channels.php` (`Broadcast::channel('deal.{dealId}', ...)`)

### `private-crm.agent.{agentId}`
- **Purpose:** Agent-specific global stream (deal events + message alerts).
- **Who can subscribe:** only the same logged-in user (`user.id === agentId`).
- **Auth rule location:** `routes/channels.php` (`Broadcast::channel('crm.agent.{agentId}', ...)`)

### `private-crm.visualization`
- **Purpose:** Admin visualization stream (deal activity, messages, agent status).
- **Who can subscribe:** admins/super-admins only.
- **Auth rule location:** `routes/channels.php` (`Broadcast::channel('crm.visualization', ...)`)

### `private-user.{userId}`
- **Purpose:** User-scoped events (notification bell updates, nudges, live audio signaling).
- **Who can subscribe:** only the same logged-in user (`user.id === userId`).
- **Auth rule location:** `routes/channels.php` (`Broadcast::channel('user.{id}', ...)`)

---

## 3) Events You Can Listen To

## `message.received`

- **Event class:** `App\Events\MessageReceived`
- **Broadcast mode:** `ShouldBroadcastNow` (immediate)
- **When emitted:** when a new message is received/stored for a deal.
- **Broadcast channels:**
  - always: `private-deal.{dealId}`
  - if incoming message (`from_me === false`) and deal has assigned agent: `private-crm.agent.{userId}`
  - if incoming message (`from_me === false`): `private-crm.visualization`
- **Typical usage in UI:**
  - append message into open deal chat
  - show global sound/toast notifications for agents/admins

**Payload shape**

```json
{
  "message": {
    "id": "msg_123",
    "db_id": 123,
    "from_me": false,
    "message_body": "Hello",
    "message_type": "text",
    "media_url": null,
    "media_type": null,
    "push_name": "Customer",
    "timestamp": 1710000000,
    "time": "14:30",
    "has_media": false,
    "poll_data": null,
    "quoted_message": null,
    "agent_name": "Agent Name"
  },
  "deal": {
    "id": 437,
    "contact_name": "John",
    "contact_phone": "966501234567"
  }
}
```

---

## `deal.history.updated`

- **Event class:** `App\Events\DealHistoryUpdated`
- **Broadcast mode:** `ShouldBroadcastNow` (immediate)
- **When emitted:** on deal lifecycle changes (new assignment, transfer, updates, status changes).
- **Action discriminator:** `action_type` (commonly `new`, `transferred`, `updated`, `status_changed`)
- **Broadcast channels:**
  - always: `private-deal.{dealId}`
  - always: `private-crm.visualization`
  - agent channels for relevant users: `private-crm.agent.{userId}` for new owner, previous owner, and/or current owner
- **Typical usage in UI:**
  - refresh deal lists
  - show assignment/transfer toasts
  - sync admin visualization board

**Payload shape**

```json
{
  "deal_id": 437,
  "action_type": "new",
  "previous_user_id": null,
  "new_user_id": 123,
  "deal": {
    "id": 437,
    "title": "Deal title",
    "contact_name": "John",
    "contact_phone": "966501234567",
    "status": "open",
    "user_id": 123,
    "user_name": "Agent Name",
    "crm_session_name": "WhatsApp",
    "created_at": "2026-05-06T07:00:00.000000Z",
    "assigned_at": "2026-05-06T07:00:00.000000Z"
  }
}
```

---

## `agent.status.updated`

- **Event class:** `App\Events\AgentStatusUpdated`
- **Broadcast mode:** `ShouldBroadcastNow` (immediate)
- **When emitted:** when an agent status changes (for example online/offline clock-in state).
- **Broadcast channels:**
  - `private-crm.visualization` only
- **Typical usage in UI:**
  - update live agent indicators for admins

**Payload shape**

```json
{
  "agent_id": 123,
  "status": "online"
}
```

---

## `notification.received`

- **Event class:** `App\Events\NotificationReceived`
- **Broadcast mode:** `ShouldBroadcast` (queued/asynchronous unless queue is sync)
- **When emitted:** when a user-targeted app notification is created and broadcast.
- **Broadcast channels:**
  - `private-user.{userId}`
- **Typical usage in UI:**
  - refresh notification center/bell badge
  - show in-app notification preview

**Payload shape**

```json
{
  "notification": {
    "id": "uuid",
    "type": "App\\Notifications\\Types\\SomeNotification",
    "title": "New message",
    "body": "You have a new message",
    "action_url": "/dashboard/crm?deal=437",
    "created_at": "2026-05-06T07:00:00.000000Z"
  }
}
```

---

## `live-audio.signal`

- **Event class:** `App\Events\LiveAudioSignal`
- **Broadcast mode:** `ShouldBroadcastNow` (immediate)
- **When emitted:** during live audio/WebRTC signaling between users.
- **Signal type field:** `type` (for example `offer`, `answer`, `ice-candidate`, `start`, `stop`)
- **Broadcast channels:**
  - `private-user.{targetUserId}`
- **Typical usage in UI:**
  - peer-to-peer call negotiation and control

**Payload shape**

```json
{
  "type": "offer",
  "data": {},
  "from_user_id": 99,
  "from_user_name": "Sender Name",
  "timestamp": "2026-05-06T07:00:00.000000Z"
}
```

---

## `nudge.received`

- **Event class:** `App\Events\NudgeSent`
- **Broadcast mode:** `ShouldBroadcastNow` (immediate)
- **When emitted:** when one user sends a nudge/ping to an agent.
- **Broadcast channels:**
  - `private-user.{agentId}`
- **Typical usage in UI:**
  - play attention sound
  - display a quick prompt "X nudged you"

**Payload shape**

```json
{
  "agent_id": 123,
  "sender_name": "Admin Name",
  "nudge_sound_url": "/assets/sounds/nudge.mp3",
  "timestamp": "2026-05-06T07:00:00.000000Z"
}
```

---

## 4) Quick Subscription Matrix

| Channel | Event(s) |
|---|---|
| `private-deal.{dealId}` | `message.received`, `deal.history.updated` |
| `private-crm.agent.{agentId}` | `message.received`, `deal.history.updated` |
| `private-crm.visualization` | `message.received`, `deal.history.updated`, `agent.status.updated` |
| `private-user.{userId}` | `notification.received`, `live-audio.signal`, `nudge.received` |

---

## 5) Practical Desktop Notes

- Listen with dot-prefix if your client library requires explicit custom event names (example: `.message.received`).
- Deduplicate message events client-side using stable IDs (`message.db_id` is useful).
- Treat `ShouldBroadcastNow` events as low-latency updates; treat `notification.received` as potentially queued.
- Reconnect logic is essential for desktop clients (network changes, sleep/wake).
- Never subscribe to another user channel; server auth will reject it.

---

## 6) Source of Truth in Code

- Event classes: `app/Events`
- Channel authorization: `routes/channels.php`
- Echo/Reverb web config example: `resources/js/app.js`
- Existing listeners:
  - `resources/js/message-notifications.js`
  - `resources/js/deal-notifications.js`
  - `resources/js/live-audio.js`
  - `resources/views/components/layouts/dashboard/dashboard/app.blade.php`
  - `app/Livewire/NotificationsDropdown.php`

