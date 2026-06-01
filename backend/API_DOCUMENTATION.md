# E-Ticketing API Documentation

**Base URL:** `http://<your-ip>:3000/api`  
**Version:** 1.0.0  
**Last Updated:** 2026-05-28

---

## Table of Contents

1. [Authentication](#1-authentication)
   - [Register](#11-register)
   - [Login](#12-login)
   - [Get Current User](#13-get-current-user)
   - [Logout](#14-logout)
2. [Error Responses](#2-error-responses)
3. [User Roles](#3-user-roles)
4. [Seed Users](#4-seed-users)

---

## 1. Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

The token is returned from the login or register response.

---

### 1.1 Register

Create a new user account. Default role is `user`.

**Endpoint**
```
POST /auth/register
```

**Headers**
| Key | Value |
|-----|-------|
| Content-Type | application/json |

**Request Body**
```json
{
  "name": "Kafuu",
  "email": "user@mail.com",
  "password": "user123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | ✅ | Display name |
| email | string | ✅ | Valid email address |
| password | string | ✅ | Minimum 6 characters |

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

### 1.2 Login

Authenticate an existing user and get a JWT token.

**Endpoint**
```
POST /auth/login
```

**Headers**
| Key | Value |
|-----|-------|
| Content-Type | application/json |

**Request Body**
```json
{
  "email": "user@mail.com",
  "password": "user123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | ✅ | Registered email address |
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

### 1.3 Get Current User

Get the authenticated user's profile. Requires a valid JWT token.

**Endpoint**
```
GET /auth/me
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

### 1.4 Logout

Invalidate the current session. Requires a valid JWT token.

**Endpoint**
```
POST /auth/logout
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

## 2. Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description here"
}
```

| Status Code | Meaning |
|-------------|---------|
| 400 | Bad Request — missing or invalid fields |
| 401 | Unauthorized — missing or invalid token |
| 403 | Forbidden — insufficient role permissions |
| 404 | Not Found — resource doesn't exist |
| 500 | Internal Server Error |

---

## 3. User Roles

| Role | Description | Permissions |
|------|-------------|-------------|
| `user` | Regular user | Create tickets, view own tickets, add comments |
| `helpdesk` | Support staff | View all tickets, update ticket status, add comments |
| `admin` | Administrator | Full access — all of the above + delete tickets, manage users |

---

## 4. Seed Users

Default users for development and testing:

| Name | Email | Password | Role |
|------|-------|----------|------|
| Administrator | admin@mail.com | admin123 | admin |
| Helpdesk | helpdesk@mail.com | helpdesk123 | helpdesk |
| Kafuu | kafuu@gmail.com | user123 | user |

> ⚠️ Change these credentials before deploying to production.

---

## 5. Health Check

Verify the server is running.

**Endpoint**
```
GET /health
```

**Response `200 OK`**
```json
{
  "status": "ok",
  "timestamp": "2026-05-28T12:00:00.000Z"
}
```
