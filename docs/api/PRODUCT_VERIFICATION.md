# Product Verification Endpoints (Admin/Moderator)

## Overview

This document covers all endpoints related to product verification and approval by administrators and moderators in the Rented Marketplace API.

---

## Get Pending Products

Retrieve all products pending verification approval.

**Endpoint**: `GET /admin/products/pending`

**Authentication**: Required (Admin/Moderator only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 25,
      "title": "Professional Camera",
      "description": "High-quality DSLR...",
      "price_per_day": "50.00",
      "verification_status": "pending",
      "user": {
        "id": 5,
        "name": "John Doe",
        "email": "john@example.com"
      },
      "category": {
        "id": 2,
        "name": "Electronics"
      },
      "created_at": "2025-12-05T10:00:00.000000Z"
    }
  ],
  "links": {},
  "meta": {}
}
```

**Notes**:
- Paginated with 20 items per page
- Ordered by most recent first
- Shows user and category information

---

## Get Approved Products

Retrieve all approved products.

**Endpoint**: `GET /admin/products/approved`

**Authentication**: Required (Admin/Moderator only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 15,
      "title": "Mountain Bike",
      "verification_status": "approved",
      "verified_at": "2025-12-05T09:30:00.000000Z",
      "user": {},
      "category": {}
    }
  ],
  "links": {},
  "meta": {}
}
```

---

## Get Rejected Products

Retrieve all rejected products with rejection reasons.

**Endpoint**: `GET /admin/products/rejected`

**Authentication**: Required (Admin/Moderator only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 30,
      "title": "Suspicious Item",
      "verification_status": "rejected",
      "rejection_reason": "Product description violates community guidelines",
      "verified_at": "2025-12-05T11:00:00.000000Z",
      "user": {},
      "category": {}
    }
  ],
  "links": {},
  "meta": {}
}
```

---

## Approve Product

Approve a pending product for public listing.

**Endpoint**: `POST /admin/products/{product}/approve`

**Authentication**: Required (Admin/Moderator only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "message": "Product approved successfully",
  "product": {
    "id": 25,
    "title": "Professional Camera",
    "verification_status": "approved",
    "verified_at": "2025-12-05T12:30:00.000000Z",
    "rejection_reason": null
  }
}
```

**Notes**:
- Product becomes visible in public listings
- User receives approval notification
- Sets `verified_at` timestamp
- Clears any previous rejection reason

---

## Reject Product

Reject a product with a reason.

**Endpoint**: `POST /admin/products/{product}/reject`

**Authentication**: Required (Admin/Moderator only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "reason": "Product images are unclear. Please upload higher quality photos."
}
```

**Validation Rules**:

- `reason`: required, string, max 500 characters

**Response** (200 OK):

```json
{
  "message": "Product rejected successfully",
  "product": {
    "id": 25,
    "title": "Professional Camera",
    "verification_status": "rejected",
    "rejection_reason": "Product images are unclear. Please upload higher quality photos.",
    "verified_at": "2025-12-05T12:30:00.000000Z"
  }
}
```

**Common Rejection Reasons**:
- Poor image quality
- Incomplete product description
- Prohibited items
- Pricing violations
- Duplicate listings
- Suspected fraud

**Notes**:
- Product removed from public listings
- User receives rejection notification with reason
- User can edit and resubmit product
- Sets `verified_at` timestamp for tracking

---
