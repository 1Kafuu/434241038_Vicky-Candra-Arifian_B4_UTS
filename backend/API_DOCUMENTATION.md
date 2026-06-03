# E-Ticketing API Documentation

**Base URL:** `http://<your-ip>:3000/api`
**Version:** 2.1.0
**Last Updated:** 2026-06-03
**Stack:** Node.js + Express + TypeScript + Supabase (PostgreSQL + Auth + Storage)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
   - [Register](#21-register)
   - [Login](#22-login)
   - [Get Current User](#23-get-current-user)
   - [List Helpdesks](#24-list-helpdesks)
   - [Logout](#25-logout)
3. [Tickets](#3-tickets)
   - [List Tickets](#31-list-tickets)
   - [Get Ticket by ID](#32-get-ticket-by-id)
   - [Create Ticket](#33-create-ticket)
   - [Assign Ticket](#34-assign-ticket)
   - [Update Status](#35-update-status)
   - [Resolve Ticket](#36-resolve-ticket)
   - [Close Ticket](#37-close-ticket)
   - [Global History](#38-global-history)
4. [Comments](#4-comments)
   - [List Comments](#41-list-comments)
   - [Add Comment](#42-add-comment)
   - [Delete Comment](#43-delete-comment)
5. [Attachments](#5-attachments)
   - [Upload Attachment](#51-upload-attachment)
6. [System](#6-system)
   - [Health Check](#61-health-check)
7. [Data Models](#7-data-models)
8. [Error Responses](#8-error-responses)
9. [User Roles & Permissions](#9-user-roles--permissions)
10. [Seed Users](#10-seed-users)
11. [Known Issues / Gaps](#11-known-issues--gaps)

---

## 1. Overview

All API responses follow this format:

```json
{
  "success": true,
  "message": "Optional human-readable message",
  "data": { ... }
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error description here"
}
```

### Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

The token is returned from the login or register response. Tokens are issued by Supabase Auth.

### CORS

CORS is configured to allow all origins (`*`) with the following methods:
`GET, POST, PUT, PATCH, DELETE`. Update the `cors` config in `app.ts` before deploying to production.

### Static Files

Uploaded files are served at:

```
GET /uploads/attachments/<filename>
```

---

## 2. Authentication

Routes mounted at `/api/auth`.

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/auth/register` | ❌ | public |
| POST | `/auth/login` | ❌ | public |
| GET | `/auth/me` | ✅ | all |
| GET | `/auth/helpdesks` | ✅ | all (intended for admin) |
| POST | `/auth/logout` | ✅ | all |

---

### 2.1 Register

Create a new user account. Default role is `user`.

**Endpoint**
```
POST /api/auth/register
```

**Request Body**
```json
{
  "name": "Kafuu",
  "email": "user@mail.com",
  "password": "user123",
  "role": "user"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | ✅ | Display name |
| email | string | ✅ | Valid email address |
| password | string | ✅ | Minimum 6 characters |
| role | string | ❌ | One of `user`, `helpdesk`, `admin` (default: `user`) |

**Response `201 Created`**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": "5f8d9aa2-429c-43a2-98c0-596f652a27dd",
      "email": "user@mail.com",
      "name": "Kafuu",
      "role": "user",
      "profileImage": null,
      "createdAt": "2026-05-28T12:06:25.447086+00:00"
    }
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | Name, email and password are required |
| 400 | User already registered |
| 400 | Password should be at least 6 characters |

---

### 2.2 Login

Authenticate an existing user and get a JWT token.

**Endpoint**
```
POST /api/auth/login
```

**Request Body**
```json
{
  "email": "user@mail.com",
  "password": "user123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | ✅ | Registered email |
| password | string | ✅ | Account password |

**Response `200 OK`**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGci...",
    "user": {
      "id": "5f8d9aa2-429c-43a2-98c0-596f652a27dd",
      "email": "user@mail.com",
      "name": "Kafuu",
      "role": "user",
      "profileImage": null,
      "createdAt": "2026-05-28T12:06:25.447086+00:00"
    }
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | Email and password are required |
| 401 | Invalid email or password |

---

### 2.3 Get Current User

Get the authenticated user's profile.

**Endpoint**
```
GET /api/auth/me
```

**Headers**
| Key | Value |
|-----|-------|
| Authorization | Bearer `<token>` |

**Response `200 OK`**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "5f8d9aa2-429c-43a2-98c0-596f652a27dd",
      "email": "user@mail.com",
      "name": "Kafuu",
      "role": "user",
      "profileImage": null,
      "createdAt": "2026-05-28T12:06:25.447086+00:00"
    }
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided |
| 401 | Invalid or expired token |
| 401 | User profile not found |

---

### 2.4 List Helpdesks

List all users with role `helpdesk`. Primarily used by admins when assigning tickets.

**Endpoint**
```
GET /api/auth/helpdesks
```

**Headers**
| Key | Value |
|-----|-------|
| Authorization | Bearer `<token>` |

**Response `200 OK`**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "name": "Helpdesk",
      "role": "helpdesk",
      "profileImage": null,
      "createdAt": "2026-05-28T12:00:00.000Z"
    }
  ]
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided |
| 401 | Invalid or expired token |

---

### 2.5 Logout

Invalidate the current session client-side (Supabase doesn't fully invalidate server-side via this endpoint — the client should also discard the token).

**Endpoint**
```
POST /api/auth/logout
```

**Headers**
| Key | Value |
|-----|-------|
| Authorization | Bearer `<token>` |

**Response `200 OK`**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided |
| 401 | Invalid or expired token |

---

## 3. Tickets

Routes mounted at `/api/tickets`.

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| GET | `/tickets` | ✅ | all (filtered by role) |
| GET | `/tickets/history` | ✅ | all (filtered by role) |
| GET | `/tickets/:id` | ✅ | all (with access check) |
| POST | `/tickets` | ✅ | any |
| POST | `/tickets/:id/assign` | ✅ | admin |
| PUT | `/tickets/:id/status` | ✅ | helpdesk (assigned only), admin |
| POST | `/tickets/:id/resolve` | ✅ | admin |
| POST | `/tickets/:id/close` | ✅ | admin (via `requireRole('admin')` middleware) |

> ⚠️ Route ordering: `GET /tickets/history` MUST be defined before `GET /tickets/:id` to prevent `"history"` from being treated as a ticket ID.

### Status & Priority Enums

```ts
TicketStatus = "Open" | "Assigned" | "In Progress" | "Pending" | "Resolved" | "Closed"
TicketPriority = "Low" | "Medium" | "High" | "Urgent"
```

> ⚠️ Status values use **Title Case** (e.g. `"In Progress"`), not snake_case. The Flutter client uses `TicketStatus.{open, assigned, inProgress, pending, resolved, closed}` which maps to these labels.

---

### 3.1 List Tickets

List tickets accessible to the current user.

**Endpoint**
```
GET /api/tickets
```

**Filtering by role:**
| Role | Filter |
|------|--------|
| `user` | Only tickets they created (`user_id == self`) |
| `helpdesk` | Tickets assigned to them **AND** status is one of `Assigned`, `In Progress`, `Pending`, or `Resolved` |
| `admin` | All tickets |

> 💡 Helpdesk cannot see `Open` (unassigned) tickets or `Closed` (terminal) tickets.

**Response `200 OK`**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "title": "Printer tidak bisa print",
      "description": "Printer di lab 3 macet",
      "status": "Open",
      "priority": "High",
      "userId": "uuid-user",
      "assignedTo": null,
      "createdAt": "2026-05-28T12:00:00.000Z",
      "updatedAt": null,
      "resolvedAt": null,
      "attachments": []
    }
  ]
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 500 | Internal server error |

---

### 3.2 Get Ticket by ID

Get full detail of a single ticket.

**Endpoint**
```
GET /api/tickets/:id
```

**Access checks:**
| Role | Access |
|------|--------|
| `user` | Only own tickets |
| `helpdesk` | Only assigned tickets (unassigned tickets also visible) |
| `admin` | Any ticket |

**Response `200 OK`**
```json
{
  "success": true,
  "data": {
    "id": "uuid-1",
    "title": "Printer tidak bisa print",
    "description": "Printer di lab 3 macet",
    "status": "Open",
    "priority": "High",
    "userId": "uuid-user",
    "assignedTo": null,
    "createdAt": "2026-05-28T12:00:00.000Z",
    "updatedAt": null,
    "resolvedAt": null,
    "attachments": []
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | Access denied |
| 404 | Ticket not found |

---

### 3.3 Create Ticket

Create a new ticket. Initial status is always `Open`.

**Endpoint**
```
POST /api/tickets
```

**Request Body**
```json
{
  "title": "Wifi putus terus",
  "description": "Di ruang dosen, sinyal hilang tiap 5 menit",
  "priority": "Medium"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| title | string | ✅ | Ticket title |
| description | string | ✅ | Detailed description |
| priority | string | ❌ | One of `Low`, `Medium`, `High`, `Urgent` (default: `Medium`) |

**Side effects:**
- Sets `status = "Open"`, `user_id = caller.id`
- Records a `ticket_history` entry with `action = "created"`, `updated_by = caller.id` (UUID)

**Response `201 Created`**
```json
{
  "success": true,
  "data": {
    "id": "uuid-new",
    "title": "Wifi putus terus",
    "description": "Di ruang dosen, sinyal hilang tiap 5 menit",
    "status": "Open",
    "priority": "Medium",
    "userId": "uuid-caller",
    "assignedTo": null,
    "createdAt": "2026-06-02T10:00:00.000Z",
    "updatedAt": null,
    "resolvedAt": null,
    "attachments": []
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | Title and description are required |
| 401 | No token provided / Invalid or expired token |

---

### 3.4 Assign Ticket

Assign a ticket to a helpdesk user. **Admin only.** Pass `assignedTo: null` to unassign (status reverts to `Open`).

**Endpoint**
```
POST /api/tickets/:id/assign
```

**Request Body**
```json
{
  "assignedTo": "uuid-helpdesk-user"
}
```

To unassign:
```json
{
  "assignedTo": null
}
```

**Side effects:**
- Sets `assigned_to` and changes status to `Assigned` (or `Open` if unassigning)
- Records a `ticket_history` entry with `action = "assigned"` or `"unassigned"`
- `updated_by = caller.id` (admin's UUID)
- Clears `resolved_at` if unassigning

**Response `200 OK`**
```json
{
  "success": true,
  "data": { /* updated ticket */ }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | Only admin can assign tickets |
| 404 | Ticket not found |

---

### 3.5 Update Status

Update ticket status.

**Endpoint**
```
PUT /api/tickets/:id/status
```

**Request Body**
```json
{
  "status": "In Progress"
}
```

**Allowed target status per role:**

| Role | Allowed Targets | Restrictions |
|------|-----------------|-------------|
| `helpdesk` | `In Progress`, `Pending`, `Resolved` | Only on tickets assigned to them |
| `admin` | `In Progress`, `Pending`, `Open` (reopen) | Any ticket |
| `user` | ❌ forbidden | — |

> ✅ Helpdesk can now set `Resolved` (new in v2.1.0).
> ❌ Admin must use `/resolve` endpoint (section 3.6) to set `Resolved`, and `/close` endpoint (section 3.7) to set `Closed`.

**Side effects:**
- Records a `ticket_history` entry with action as the new status value
- Clears `resolved_at` when reopening to `Open`

**Response `200 OK`**
```json
{
  "success": true,
  "data": { /* updated ticket */ }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | You can only update tickets assigned to you |
| 403 | You can only update to in_progress, pending, or resolved |
| 403 | Use /resolve endpoint to close ticket |
| 403 | Users cannot update ticket status |
| 404 | Ticket not found |

---

### 3.6 Resolve Ticket

Mark a ticket as resolved. **Admin only.** Sets `status = "Resolved"` and `resolved_at = now()`.

**Endpoint**
```
POST /api/tickets/:id/resolve
```

**Request Body**: _none_

**Side effects:**
- Sets `status = "Resolved"`, `resolved_at = now()`
- Records a `ticket_history` entry with `action = "resolved"`
- `updated_by = caller.id` (admin's UUID)

**Response `200 OK`**
```json
{
  "success": true,
  "data": { /* updated ticket */ }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | Only admin can resolve tickets |
| 403 | Ticket is not assigned |
| 404 | Ticket not found |

---

### 3.7 Close Ticket

Close a resolved ticket. **Admin only** (uses `requireRole('admin')` middleware). Only allowed when current status is `Resolved`.

**Endpoint**
```
POST /api/tickets/:id/close
```

**Request Body**: _none_

**Side effects:**
- Sets `status = "Closed"`
- Records a `ticket_history` entry with `action = "closed"`
- `updated_by = caller.id` (admin's UUID)

**Response `200 OK`**
```json
{
  "success": true,
  "data": { /* updated ticket */ }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | Only resolved tickets can be closed |
| 401 | No token provided / Invalid or expired token |
| 403 | Forbidden (if role is not admin) |
| 404 | Ticket not found |

---

### 3.8 Global History

Get all ticket history across all tickets, filtered by role. **This is the primary history endpoint used by the Flutter app.**

**Endpoint**
```
GET /api/tickets/history
```

**Filtering by role:**
| Role | Filter |
|------|--------|
| `user` | Only history for tickets they created (via `tickets!inner` join on `user_id`) |
| `helpdesk` | Only history for tickets assigned to them (via `tickets!inner` join on `assigned_to`) |
| `admin` | All history entries |

The response includes the actor's name via a `profiles!updated_by(name)` join. The field `updatedByName` contains the display name; `updatedBy` contains the UUID.

**Response `200 OK`**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-h1",
      "ticketId": "uuid-1",
      "action": "created",
      "description": "Ticket has been succesfuly created",
      "updatedBy": "uuid-actor",
      "updatedByName": "Kafuu",
      "timestamp": "2026-05-28T12:00:00.000Z"
    },
    {
      "id": "uuid-h2",
      "ticketId": "uuid-1",
      "action": "assigned",
      "description": "Assigned to Helpdesk",
      "updatedBy": "uuid-admin",
      "updatedByName": "Administrator",
      "timestamp": "2026-05-28T13:00:00.000Z"
    }
  ]
}
```

**History action values:**
| Action | Triggered by | Description template |
|--------|-------------|---------------------|
| `created` | Any user creating a ticket | `"Ticket has been succesfuly created"` |
| `assigned` | Admin assigns helpdesk | `"Assigned to {helpdeskName}"` |
| `unassigned` | Admin unassigns helpdesk | `"Unassigned"` |
| `in_progress` | Helpdesk/admin updates status | `"Status changed from X to Y"` |
| `pending` | Helpdesk/admin updates status | `"Status changed from X to Y"` |
| `resolved` | Admin or helpdesk resolves ticket | `"Ticket resolved by {user.name}"` |
| `closed` | Admin closes resolved ticket | `"Ticket closed by {user.name}"` |

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 500 | Internal server error |

---

## 4. Comments

Routes mounted at `/api/tickets/:id/comments` (nested under ticket).

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| GET | `/tickets/:id/comments` | ✅ | all (with access check) |
| POST | `/tickets/:id/comments` | ✅ | all (with access check) |
| DELETE | `/tickets/:id/comments/:commentId` | ✅ | owner of comment OR admin |

---

### 4.1 List Comments

Get all comments for a ticket, ordered by timestamp ascending. The response includes `senderName` (resolved from profiles).

**Endpoint**
```
GET /api/tickets/:id/comments
```

**Response `200 OK`**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-c1",
      "ticketId": "uuid-1",
      "senderId": "uuid-user",
      "senderName": "Kafuu",
      "message": "Saya sudah coba restart router, masih belum bisa",
      "parentCommentId": null,
      "createdAt": "2026-05-28T14:00:00.000Z"
    },
    {
      "id": "uuid-c2",
      "ticketId": "uuid-1",
      "senderId": "uuid-helpdesk",
      "senderName": "Helpdesk",
      "message": "Baik, akan saya cek langsung",
      "parentCommentId": "uuid-c1",
      "createdAt": "2026-05-28T14:30:00.000Z"
    }
  ]
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | Access denied |
| 404 | Ticket not found |

---

### 4.2 Add Comment

Add a comment to a ticket. Supports nested replies via `parentCommentId`.

**Endpoint**
```
POST /api/tickets/:id/comments
```

**Request Body**
```json
{
  "message": "Saya cek lokasi, mohon tunggu",
  "parentCommentId": "uuid-c1"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| message | string | ✅ | Comment body (trimmed, cannot be empty) |
| parentCommentId | string | ❌ | UUID of the parent comment if this is a reply |

**Response `201 Created`**
```json
{
  "success": true,
  "data": {
    "id": "uuid-c-new",
    "ticketId": "uuid-1",
    "senderId": "uuid-helpdesk",
    "senderName": "Helpdesk",
    "message": "Saya cek lokasi, mohon tunggu",
    "parentCommentId": "uuid-c1",
    "createdAt": "2026-05-28T15:00:00.000Z"
  }
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | Message is required |
| 400 | Parent comment not found |
| 401 | No token provided / Invalid or expired token |
| 403 | Access denied |
| 404 | Ticket not found |

---

### 4.3 Delete Comment

Delete a comment. **Permission:** only the comment owner or an admin can delete.

**Endpoint**
```
DELETE /api/tickets/:id/comments/:commentId
```

**Response `200 OK`**
```json
{
  "success": true,
  "message": "Comment deleted"
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 401 | No token provided / Invalid or expired token |
| 403 | You can only delete your own comments |
| 404 | Comment not found |

> ⚠️ Deleting a parent comment does NOT cascade-delete its replies. Replies become orphans (still in DB with dangling `parent_comment_id`). The client should handle this when rendering the tree.

---

## 5. Attachments

Routes mounted at `/api/tickets/:id/attachments`. Files stored in `/uploads/attachments/`.

> 🔒 All attachment endpoints require authentication (`Authorization: Bearer <token>`).

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/tickets/:id/attachments` | ✅ | all (with access check) |

**File upload constraints:**
- Max size: 10 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `text/plain`
- Field name: `file` (multipart form-data)
- Image auto-compression: max 1200×1200 px, JPEG quality 80%, PNG compression level 9

---

### 5.1 Upload Attachment

Upload a file and attach it to a ticket. The relative path (`uploads/attachments/<filename>`) is appended to the ticket's `attachments` array.

**Endpoint**
```
POST /api/tickets/:id/attachments
```

**Request (multipart/form-data)**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | binary | ✅ | The file to upload |

**Response `201 Created`**
```json
{
  "message": "File uploaded successfully",
  "attachments": [
    "uploads/attachments/1717360000-abc123.jpg",
    "uploads/attachments/1717360001-def456.png"
  ]
}
```

**Error Responses**
| Status | Message |
|--------|---------|
| 400 | No file uploaded |
| 400 | File type not allowed. Allowed: ... |
| 413 | File too large (exceeds 10MB) |
| 500 | Internal server error |

> The full URL for the uploaded file is `<base>/uploads/attachments/<filename>`. The client constructs this from `storageConfig.baseUrl` + filename.

---

## 6. System

### 6.1 Health Check

Verify the server is running.

**Endpoint**
```
GET /health
```

**Response `200 OK`**
```json
{
  "status": "ok",
  "timestamp": "2026-06-02T10:00:00.000Z"
}
```

---

## 7. Data Models

### User

```ts
interface User {
  id: string;                // UUID from Supabase Auth
  email: string;
  name: string;
  role: "admin" | "helpdesk" | "user";
  profileImage?: string | null;
  createdAt?: string;        // ISO 8601
}
```

### Ticket

```ts
interface Ticket {
  id: string;
  title: string;
  description: string;
  status: "Open" | "Assigned" | "In Progress" | "Pending" | "Resolved" | "Closed";
  priority: "Low" | "Medium" | "High" | "Urgent";
  userId: string;            // creator's UUID
  assignedTo?: string;       // helpdesk's UUID (null if unassigned)
  createdAt: string;         // ISO 8601
  updatedAt?: string;        // ISO 8601
  resolvedAt?: string;       // ISO 8601
  attachments: string[];     // relative paths
}
```

### Comment

```ts
interface Comment {
  id: string;
  ticketId: string;
  senderId: string;
  senderName?: string;       // resolved from profile (only on list)
  message: string;
  parentCommentId?: string;  // for nested replies
  createdAt: string;
}
```

### TicketHistory

```ts
interface TicketHistory {
  id: string;
  ticketId: string;
  action: string;              // "created" | "assigned" | "unassigned" | "in_progress" | "pending" | "resolved" | "closed"
  description: string;         // Human-readable description
  updatedBy: string;           // Actor's UUID (from profiles.id)
  updatedByName: string;       // Actor's display name (resolved via join)
  timestamp: string;           // ISO 8601
}
```

---

## 8. Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description here"
}
```

| Status Code | Meaning | Common Causes |
|-------------|---------|---------------|
| 400 | Bad Request | Missing or invalid fields, validation failed, illegal status transition |
| 401 | Unauthorized | Missing or invalid/expired token |
| 403 | Forbidden | Insufficient role permissions, access denied to resource |
| 404 | Not Found | Resource doesn't exist |
| 413 | Payload Too Large | File > 10MB |
| 500 | Internal Server Error | Server-side error (logged in console) |

---

## 9. User Roles & Permissions

| Role | Description | Permissions |
|------|-------------|-------------|
| `user` | Regular user | • Create tickets<br>• View own tickets<br>• Add comments on own tickets<br>• Delete own comments<br>• View global history for own tickets |
| `helpdesk` | Support staff | • View assigned tickets (status: Assigned, In Progress, Pending, Resolved)<br>• Update status of assigned tickets to `In Progress`, `Pending`, or `Resolved`<br>• Add comments on assigned tickets<br>• Delete own comments<br>• View global history for assigned tickets |
| `admin` | Administrator | • All of the above +<br>• View all tickets<br>• Assign tickets to helpdesks<br>• Update any ticket status (In Progress, Pending, Open)<br>• Resolve tickets (POST /resolve)<br>• Close resolved tickets (POST /close)<br>• Delete any comment<br>• View all global history |

### Status Transition Summary

| Current Status | Admin can set via... | Helpdesk can set via... |
|---------------|---------------------|------------------------|
| **Open** | PUT → In Progress/Pending/Open<br>POST → /resolve<br>POST → /assign (→ Assigned) | ❌ (not assigned) |
| **Assigned** | PUT → In Progress/Pending/Open<br>POST → /resolve<br>POST → /close | PUT → In Progress/Pending/Resolved |
| **In Progress** | PUT → Pending/Open<br>POST → /resolve<br>POST → /close | PUT → Pending/Resolved |
| **Pending** | PUT → In Progress/Open<br>POST → /resolve<br>POST → /close | PUT → In Progress/Resolved |
| **Resolved** | PUT → Open (reopen)<br>**POST → /close** ✅ | PUT → In Progress (re-open) |
| **Closed** | POST → /assign (→ Open)<br>PUT → Open (reopen) | ❌ |

> ℹ️ **/close** is only allowed when status is `Resolved` (returns 400 otherwise).

---

## 10. Seed Users

Default users for development and testing (created in Supabase via seed script):

| Name | Email | Password | Role |
|------|-------|----------|------|
| Administrator | admin@mail.com | admin123 | admin |
| Helpdesk | helpdesk@mail.com | helpdesk123 | helpdesk |
| Kafuu | kafuu@gmail.com | user123 | user |

> ⚠️ Change these credentials before deploying to production.

---

## 11. Known Issues / Gaps

These are issues discovered during code review. They should be fixed before production deployment.

### 🟠 API Consistency

| # | Issue | Location | Impact |
|---|-------|----------|--------|
| 1 | **Health endpoint at `/health`, not `/api/health`** — inconsistent with the rest of the API. | `backend/src/app.ts` | Low: minor inconsistency |
| 2 | **Attachment response uses different envelope** — `{"message": ..., "attachments": [...]}` without `success` flag, unlike other endpoints. | `backend/src/controllers/attachment.controller.ts` | Low: breaks the `success`/`data` pattern |
| 3 | **No `requireRole` guard on assign/resolve routes** — controllers do manual role checks which can be missed. | `backend/src/routes/ticket.routes.ts` | Medium: works currently but error-prone |
| 5 | **Comment replies become orphans on parent delete** — no cascade or soft-delete. | `comment.controller.ts` `deleteComment` | Low: client must handle |

### 🟠 Frontend Integration

| # | Issue | Detail |
|---|-------|--------|
| 6 | **No pagination** on `GET /tickets` — can be slow with many tickets. | `ticket.controller.ts` `getTickets` |
| 7 | **No search/filter** on `GET /tickets` — Flutter has a search bar in dashboard but no backend support. | same |

### 🟢 Recommended Fixes (Priority Order)

1. **Add `requireRole('admin')` middleware** to `/assign` and `/resolve` routes
2. **Add pagination params** to `GET /tickets` (`?page=1&limit=20`)
3. **Add search param** to `GET /tickets` (`?q=printer`)
4. **Cascade or soft-delete comment replies** when parent is deleted
5. **Standardize attachment response envelope** to `{ success, message, data }`

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-05-28 | Initial auth endpoints |
| 2.0.0 | 2026-06-02 | Full API surface: tickets, comments, attachments + role matrix + data models + known issues |
| 2.0.1 | 2026-06-02 | **Security fix:** Added `authMiddleware` to all attachment routes |
| **2.1.0** | **2026-06-03** | **New endpoints:** `POST /tickets/:id/close` (admin close resolved tickets), `GET /tickets/history` (global role-filtered history). **Updated:** Helpdesk can now set `Resolved` status. **Data model change:** `TicketHistory` now uses `action`, `description`, `updatedBy` (UUID), `updatedByName` (from join), `timestamp` — replaces old `changedBy`/`oldStatus`/`newStatus`/`createdAt`. **Fixed:** Comment reply bug (`parentCommentId` now correctly used). |

---

*Last reviewed: 2026-06-03*
