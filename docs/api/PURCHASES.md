# Purchases Endpoints

## Overview

This document covers all endpoints related to product purchases in the Rented Marketplace API.

---

## Create Purchase Request

Request to purchase a product.

**Endpoint**: `POST /purchases`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "product_id": 25,
  "notes": "Interested in buying. When can I pick up?"
}
```

**Validation Rules**:

- `product_id`: required, exists:products,id
- `notes`: nullable, string, max:500

**Response** (201 Created):

```json
{
  "message": "Purchase request created successfully",
  "data": {
    "id": 5,
    "product": {
      "id": 25,
      "title": "Canon EOS R5 Camera",
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
      "sale_price": "2500.00",
      "owner": {
        "id": 5,
        "name": "Jane Smith",
        "avatar_url": "http://localhost:8000/storage/avatars/5_xyz789.jpg"
      }
    },
    "buyer": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/1_abc123.jpg"
    },
    "purchase_price": "2500.00",
    "status": "pending",
    "notes": "Interested in buying. When can I pick up?",
    "created_at": "2025-12-03T14:30:45.000000Z"
  }
}
```

**Error Responses**:

*400 Bad Request* - Product not for sale

```json
{
  "message": "Product is not available for purchase."
}
```

*400 Bad Request* - Product not available

```json
{
  "message": "Product is no longer available."
}
```

*400 Bad Request* - Already sold

```json
{
  "message": "Product has already been sold."
}
```

---

## Complete Purchase

Mark a purchase as completed. **Only product owner can complete**.

**Endpoint**: `PUT /purchases/{id}/complete`

**Authentication**: Required (Product owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Path Parameters**:

- `id` (integer, required): Purchase ID

**Response** (200 OK):

```json
{
  "message": "Purchase completed successfully",
  "data": {
    "id": 5,
    "product": {
      "id": 25,
      "title": "Canon EOS R5 Camera",
      "owner": {
        "id": 5,
        "name": "Jane Smith"
      }
    },
    "buyer": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com"
    },
    "purchase_price": "2500.00",
    "status": "completed",
    "updated_at": "2025-12-03T16:30:45.000000Z"
  }
}
```

**Note**: When a purchase is completed, the product's `is_available` status is automatically set to `false`.

**Error Responses**:

*403 Forbidden* - Not product owner

```json
{
  "message": "This action is unauthorized."
}
```

---

## Cancel Purchase

Cancel a purchase request. **Product owner or buyer can cancel**.

**Endpoint**: `PUT /purchases/{id}/cancel`

**Authentication**: Required (Product owner or buyer)

**Headers**:

```http
Authorization: Bearer {token}
```

**Path Parameters**:

- `id` (integer, required): Purchase ID

**Response** (200 OK):

```json
{
  "message": "Purchase cancelled successfully",
  "data": {
    "id": 5,
    "product": {
      "id": 25,
      "title": "Canon EOS R5 Camera"
    },
    "purchase_price": "2500.00",
    "status": "cancelled",
    "updated_at": "2025-12-03T16:30:45.000000Z"
  }
}
```

**Note**: When a purchase is cancelled, the product becomes available again (`is_available` set to `true`).

---

## Get User's Purchases

Retrieve all purchase requests made by the authenticated user.

**Endpoint**: `GET /user/purchases`

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
      "id": 5,
      "product": {
        "id": 25,
        "title": "Canon EOS R5 Camera",
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
        "sale_price": "2500.00",
        "owner": {
          "id": 5,
          "name": "Jane Smith"
        }
      },
      "purchase_price": "2500.00",
      "status": "completed",
      "notes": "Interested in buying. When can I pick up?",
      "created_at": "2025-12-03T14:30:45.000000Z",
      "updated_at": "2025-12-03T16:30:45.000000Z"
    }
  ]
}
```

---
