# Authentication API

## Authentication Endpoints

### Register User

Create a new user account.

**Endpoint**: `POST /api/v1/register`

**Authentication**: Not required

**Request Body**:

```json
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!"
}
```

**Validation Rules**:

- `name`: required, string, max:255
- `email`: required, email, unique, max:255
- `password`: required, string, min:8, confirmed

**Response** (201 Created):

```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "avatar_url": null,
    "verification_status": "pending",
    "verified_at": null,
    "created_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T14:30:45.000000Z"
  },
  "token": "1|AbCdEfGhIjKlMnOpQrStUvWxYz1234567890"
}
```

**Error Responses**:

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password confirmation does not match."]
  }
}
```

---

### Login User

Authenticate a user and receive an access token.

**Endpoint**: `POST /api/v1/login`

**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Validation Rules**:

- `email`: required, email
- `password`: required, string

**Response** (200 OK):

```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "avatar_url": "http://localhost:8000/storage/avatars/abc123.jpg",
    "verification_status": "verified",
    "verified_at": "2025-12-03T14:30:45.000000Z"
  },
  "token": "2|XyZaBcDeFgHiJkLmNoPqRsTuVwXy0987654321"
}
```

**Error Responses**:

*422 Unprocessable Entity* - Invalid credentials

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The provided credentials are incorrect."]
  }
}
```

---

### Logout User

Revoke the current access token.

**Endpoint**: `POST /api/v1/logout`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "message": "Logged out successfully"
}
```

**Error Responses**:

*401 Unauthorized* - Invalid or missing token

```json
{
  "message": "Unauthenticated."
}
```

---

### Get Current User

Retrieve the authenticated user's profile.

**Endpoint**: `GET /api/v1/user`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "avatar_url": "http://localhost:8000/storage/avatars/abc123.jpg",
    "verification_status": "verified",
    "verified_at": "2025-12-03T14:30:45.000000Z",
    "created_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T14:30:45.000000Z"
  }
}
```

---

## Google OAuth Endpoints

### Redirect to Google Authentication

Initiate Google OAuth authentication flow.

**Endpoint**: `GET /api/v1/auth/google`

**Authentication**: Not required

**Response** (200 OK):

```json
{
  "url": "https://accounts.google.com/o/oauth2/auth?client_id=..."
}
```

**Description**: The client should redirect the user to the returned URL for Google authentication.

---

### Handle Google OAuth Callback

Process Google OAuth callback and authenticate user.

**Endpoint**: `GET /api/v1/auth/google/callback`

**Authentication**: Not required

**Query Parameters**: Automatically provided by Google

**Response** (200 OK):

```json
{
  "message": "Successfully authenticated with Google",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@gmail.com",
    "avatar_url": "https://lh3.googleusercontent.com/...",
    "verification_status": "unverified",
    "google_id": "1234567890"
  },
  "token": "2|AbCdEfGhIjKlMnOpQrStUvWxYz"
}
```

**Errors**:

- **500 Internal Server Error**: OAuth authentication failed

**Notes**:
- Creates new user if email doesn't exist
- Links Google account to existing user if email matches
- Updates Google tokens for future use

---

## Password Reset Endpoints

### Request Password Reset

Send password reset email to user.

**Endpoint**: `POST /api/v1/forgot-password`

**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john@example.com"
}
```

**Validation Rules**:

- `email`: required, valid email format, must exist in database

**Response** (200 OK):

```json
{
  "message": "Password reset link sent to your email"
}
```

**Errors**:

- **422 Unprocessable Entity**: Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."]
  }
}
```

**Notes**:
- Reset link expires after 60 minutes
- Check spam folder if email not received

---

### Reset Password

Reset user password using token from email.

**Endpoint**: `POST /api/v1/reset-password`

**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john@example.com",
  "token": "reset-token-from-email",
  "password": "NewSecurePassword123!",
  "password_confirmation": "NewSecurePassword123!"
}
```

**Validation Rules**:

- `email`: required, valid email format
- `token`: required, valid reset token
- `password`: required, min 8 characters, confirmed
- `password_confirmation`: required, must match password

**Response** (200 OK):

```json
{
  "message": "Password has been reset successfully"
}
```

**Errors**:

- **422 Unprocessable Entity**: Invalid token or validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["We can't find a user with that email address."],
    "token": ["This password reset token is invalid."]
  }
}
```
