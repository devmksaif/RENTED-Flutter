# User Profile Endpoints

## Overview

This document covers all endpoints related to user profile management, avatar uploads, and user verification in the Rented Marketplace API.

---

## User Profile Endpoints

### Update User Profile

Update the authenticated user's profile information.

**Endpoint**: `PUT /user/profile`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body** (Update Name):

```json
{
  "name": "John Updated Doe"
}
```

**Request Body** (Update Email):

```json
{
  "email": "newemail@example.com"
}
```

**Request Body** (Change Password):

```json
{
  "current_password": "SecurePass123!",
  "password": "NewSecurePass456!",
  "password_confirmation": "NewSecurePass456!"
}
```

**Request Body** (Update Multiple Fields):

```json
{
  "name": "John Updated Doe",
  "email": "newemail@example.com",
  "current_password": "SecurePass123!",
  "password": "NewSecurePass456!",
  "password_confirmation": "NewSecurePass456!"
}
```

**Validation Rules**:

- `name`: sometimes, string, max:255
- `email`: sometimes, email, unique (excluding current user), max:255
- `current_password`: required_with:password, string
- `password`: sometimes, string, min:8, confirmed

**Response** (200 OK):

```json
{
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "name": "John Updated Doe",
    "email": "newemail@example.com",
    "avatar_url": "http://localhost:8000/storage/avatars/abc123.jpg",
    "verification_status": "verified",
    "verified_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T15:20:30.000000Z"
  }
}
```

**Error Responses**:

*400 Bad Request* - Current password incorrect

```json
{
  "message": "Current password is incorrect."
}
```

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email has already been taken."
    ],
    "password": [
      "The password must be at least 8 characters."
    ]
  }
}
```

---

## Avatar Management Endpoints

### Upload/Update Avatar

Upload or update the authenticated user's profile avatar.

**Endpoint**: `POST /user/avatar`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body** (multipart/form-data):

- `avatar` (file, required): Profile avatar image

**Validation Rules**:

- `avatar`: required, image, mimes:jpeg,jpg,png, max:2048 (2MB), dimensions:min_width=100,min_height=100,max_width=2000,max_height=2000

**cURL Example**:

```bash
curl -X POST "http://localhost:8000/api/v1/user/avatar" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json" \
  -F "avatar=@/path/to/avatar.jpg"
```

**Response** (200 OK):

```json
{
  "message": "Avatar updated successfully",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "avatar_url": "http://localhost:8000/storage/avatars/1_abc123def456.jpg",
    "verification_status": "verified",
    "verified_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-04T10:15:30.000000Z"
  }
}
```

**Note**: When updating an avatar, the old avatar file is automatically deleted.

**Error Responses**:

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "avatar": [
      "The avatar must be an image.",
      "The avatar must not be greater than 2048 kilobytes.",
      "The avatar must have minimum dimensions of 100x100 pixels.",
      "The avatar must have maximum dimensions of 2000x2000 pixels."
    ]
  }
}
```

---

### Delete Avatar

Remove the authenticated user's profile avatar.

**Endpoint**: `DELETE /user/avatar`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "message": "Avatar deleted successfully",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "avatar_url": null,
    "verification_status": "verified",
    "verified_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-04T10:20:00.000000Z"
  }
}
```

**Error Responses**:

*404 Not Found* - No avatar to delete

```json
{
  "message": "No avatar found to delete."
}
```

---

## User Verification Endpoints

### Upload Verification Documents

Upload identification documents for user verification. This endpoint accepts up to 3 images: front of ID, back of ID, and a selfie with ID.

**Endpoint**: `POST /verify`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body** (multipart/form-data):

- `id_front` (file, required): Front of ID document (JPEG, JPG, PNG)
- `id_back` (file, required): Back of ID document (JPEG, JPG, PNG)
- `selfie` (file, required): Selfie holding ID document (JPEG, JPG, PNG)
- `document_type` (string, optional): Type of document (passport, national_id, driver_license)

**Validation Rules**:

- `id_front`: required, image, mimes:jpeg,jpg,png, max:5120 (5MB)
- `id_back`: required, image, mimes:jpeg,jpg,png, max:5120 (5MB)
- `selfie`: required, image, mimes:jpeg,jpg,png, max:5120 (5MB)
- `document_type`: nullable, in:passport,national_id,driver_license

**cURL Example**:

```bash
curl -X POST "http://localhost:8000/api/v1/verify" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json" \
  -F "id_front=@/path/to/id_front.jpg" \
  -F "id_back=@/path/to/id_back.jpg" \
  -F "selfie=@/path/to/selfie.jpg" \
  -F "document_type=national_id"
```

**Response** (201 Created):

```json
{
  "message": "Verification documents uploaded successfully",
  "data": {
    "id": 1,
    "user_id": 1,
    "verification_status": "pending",
    "document_type": "national_id",
    "has_id_front": true,
    "has_id_back": true,
    "has_selfie": true,
    "submitted_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T14:30:45.000000Z"
  }
}
```

**Error Responses**:

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "Verification upload failed",
  "errors": {
    "id_front": [
      "The id front must be an image.",
      "The id front must be a file of type: jpeg, jpg, png."
    ],
    "selfie": [
      "The selfie field is required.",
      "The selfie must not be greater than 5120 kilobytes."
    ]
  }
}
```

*422 Unprocessable Entity* - Already verified or pending

```json
{
  "message": "You already have a pending verification request or you are already verified."
}
```

---

### Get Verification Status

Check the status of the user's verification request.

**Endpoint**: `GET /verify/status`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK) - Verified:

```json
{
  "data": {
    "verification_status": "verified",
    "document_type": "national_id",
    "has_id_front": true,
    "has_id_back": true,
    "has_selfie": true,
    "submitted_at": "2025-12-03T14:30:45.000000Z",
    "verified_at": "2025-12-03T16:45:20.000000Z"
  }
}
```

**Response** (200 OK) - Pending:

```json
{
  "data": {
    "verification_status": "pending",
    "document_type": "national_id",
    "has_id_front": true,
    "has_id_back": true,
    "has_selfie": true,
    "submitted_at": "2025-12-03T14:30:45.000000Z",
    "verified_at": null
  }
}
```

**Response** (200 OK) - Rejected:

```json
{
  "data": {
    "verification_status": "rejected",
    "document_type": "passport",
    "has_id_front": true,
    "has_id_back": true,
    "has_selfie": true,
    "submitted_at": "2025-12-03T14:30:45.000000Z",
    "verified_at": null,
    "admin_notes": "Documents are not clear. Please upload higher quality images."
  }
}
```

**Response** (200 OK) - Unverified (No submission):

```json
{
  "data": {
    "verification_status": "unverified",
    "document_type": null,
    "has_id_front": false,
    "has_id_back": false,
    "has_selfie": false,
    "submitted_at": null,
    "verified_at": null
  }
}
```

**Possible Status Values**:

- `unverified`: User has not submitted verification documents
- `pending`: Documents are under review
- `verified`: User is verified
- `rejected`: Verification failed, resubmission required

---

### View Verification Image (Secure)

Securely view a verification image. Only the document owner can access their images. This endpoint is rate-limited to 60 requests per minute.

**Endpoint**: `GET /verify/image/{imageType}`

**Authentication**: Required (Owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Path Parameters**:

- `imageType` (string, required): Type of image to view. Must be one of: `id_front`, `id_back`, `selfie`

**Rate Limiting**: 60 requests per minute

**Request Example**:

```bash
curl -X GET "http://localhost:8000/api/v1/verify/image/id_front" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json"
```

**Response** (200 OK):

Returns the image file directly with appropriate headers:

```
Content-Type: image/jpeg
Content-Disposition: inline
Cache-Control: private, no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
X-Content-Type-Options: nosniff
```

**Error Responses**:

*400 Bad Request* - Invalid image type

```json
{
  "message": "Invalid image type. Must be: id_front, id_back, or selfie."
}
```

*403 Forbidden* - Not authorized (trying to access another user's images)

```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - No verification documents

```json
{
  "message": "No verification documents found."
}
```

*404 Not Found* - Specific image not found

```json
{
  "message": "Image not found."
}
```

*429 Too Many Requests* - Rate limit exceeded

```json
{
  "message": "Too Many Attempts."
}
```

**Flutter Implementation Example**:

```dart
Future<Uint8List?> loadVerificationImage(String imageType) async {
  final response = await http.get(
    Uri.parse('$baseUrl/verify/image/$imageType'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else if (response.statusCode == 404) {
    // Image not found
    return null;
  } else if (response.statusCode == 429) {
    // Rate limit exceeded
    throw Exception('Too many requests. Please try again later.');
  }
  
  throw Exception('Failed to load image');
}

// Usage in Widget
Image.memory(
  imageBytes,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

---
