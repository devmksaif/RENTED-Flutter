# Disputes Endpoints

## Overview

This document covers all endpoints related to dispute management in the Rented Marketplace API.

---

## Get User's Disputes

Retrieve all disputes involving authenticated user.

**Endpoint**: `GET /disputes`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "rental_id": 5,
      "purchase_id": null,
      "dispute_type": "damage",
      "status": "open",
      "description": "Item was returned with scratches on the lens",
      "evidence": [
        "http://localhost:8000/storage/disputes/image1.jpg",
        "http://localhost:8000/storage/disputes/image2.jpg"
      ],
      "reporter": {
        "id": 1,
        "name": "John Doe"
      },
      "reported_user": {
        "id": 2,
        "name": "Jane Doe"
      },
      "resolution": null,
      "created_at": "2025-12-05T09:00:00.000000Z",
      "updated_at": "2025-12-05T09:00:00.000000Z"
    }
  ]
}
```

**Notes**:
- Shows disputes where user is either reporter or reported party
- Ordered by most recent first

---

## Get Dispute by ID

Get details of a specific dispute.

**Endpoint**: `GET /disputes/{id}`

**Authentication**: Required (Involved parties only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "rental": {
      "id": 5,
      "product": {
        "id": 10,
        "title": "Professional Camera"
      }
    },
    "dispute_type": "damage",
    "status": "investigating",
    "description": "Item was returned with scratches on the lens",
    "evidence": [
      "http://localhost:8000/storage/disputes/image1.jpg"
    ],
    "reporter": {
      "id": 1,
      "name": "John Doe"
    },
    "reported_user": {
      "id": 2,
      "name": "Jane Doe"
    },
    "resolution": "Under investigation by support team",
    "created_at": "2025-12-05T09:00:00.000000Z",
    "updated_at": "2025-12-05T10:00:00.000000Z"
  }
}
```

**Errors**:

- **403 Forbidden**: Not involved in dispute

---

## Create Dispute

Create a new dispute for a rental or purchase.

**Endpoint**: `POST /disputes`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "rental_id": 5,
  "reported_against": 2,
  "dispute_type": "damage",
  "description": "The camera lens was scratched when returned. Photos attached as evidence.",
  "evidence": [
    "https://example.com/damage-photo1.jpg",
    "https://example.com/damage-photo2.jpg"
  ]
}
```

**Validation Rules**:

- `rental_id`: required without purchase_id, must exist
- `purchase_id`: required without rental_id, must exist
- `reported_against`: required, must be valid user ID
- `dispute_type`: required, one of: `damage`, `late_return`, `not_as_described`, `payment`, `other`
- `description`: required, string, max 2000 characters
- `evidence`: optional, array of URLs or file paths

**Dispute Types**:
- `damage`: Property damage claims
- `late_return`: Late return issues
- `not_as_described`: Product mismatch or misrepresentation
- `payment`: Payment-related problems
- `other`: Other disputes

**Response** (201 Created):

```json
{
  "data": {
    "id": 1,
    "rental_id": 5,
    "dispute_type": "damage",
    "status": "open",
    "description": "The camera lens was scratched when returned.",
    "created_at": "2025-12-05T11:00:00.000000Z"
  }
}
```

**Errors**:

- **422 Unprocessable Entity**: Validation failed
- **403 Forbidden**: Not authorized to create dispute for this rental/purchase

**Notes**:
- Can only create dispute for rentals/purchases you're involved in
- Evidence URLs should be accessible
- System notifies both parties when dispute is created

---

## Update Dispute Status

Update the status of a dispute (admin/moderator action).

**Endpoint**: `PUT /disputes/{id}/status`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "status": "investigating"
}
```

**Validation Rules**:

- `status`: required, one of: `investigating`, `resolved`, `closed`

**Status Flow**:
- `open` → `investigating` → `resolved` → `closed`

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "status": "investigating",
    "updated_at": "2025-12-05T11:30:00.000000Z"
  }
}
```

**Errors**:

- **403 Forbidden**: Not authorized to update status

---

## Resolve Dispute

Mark dispute as resolved with resolution details.

**Endpoint**: `POST /disputes/{id}/resolve`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "resolution": "Refund of $100 issued to renter. Security deposit retained by owner for lens repair."
}
```

**Validation Rules**:

- `resolution`: required, string, max 2000 characters

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "status": "resolved",
    "resolution": "Refund of $100 issued to renter. Security deposit retained by owner for lens repair.",
    "updated_at": "2025-12-05T12:00:00.000000Z"
  }
}
```

**Errors**:

- **403 Forbidden**: Not authorized to resolve dispute
- **400 Bad Request**: Dispute already resolved

**Notes**:
- Automatically sets status to `resolved`
- Sends notification to both parties
- Resolution is permanent and cannot be edited

---
