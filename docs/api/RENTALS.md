# Rentals Endpoints

## Overview

This document covers all endpoints related to product rentals in the Rented Marketplace API.

---

## Create Rental Request

Request to rent a product for specific dates.

**Endpoint**: `POST /rentals`

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
  "start_date": "2025-12-10",
  "end_date": "2025-12-15",
  "notes": "Need for weekend photoshoot event"
}
```

**Validation Rules**:

- `product_id`: required, exists:products,id
- `start_date`: required, date, after_or_equal:today
- `end_date`: required, date, after:start_date
- `notes`: nullable, string, max:500

**Response** (201 Created):

```json
{
  "message": "Rental request created successfully",
  "data": {
    "id": 10,
    "product": {
      "id": 25,
      "title": "Canon EOS R5 Camera",
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
      "price_per_day": "50.00",
      "owner": {
        "id": 5,
        "name": "Jane Smith",
        "avatar_url": "http://localhost:8000/storage/avatars/5_xyz789.jpg"
      }
    },
    "renter": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/1_abc123.jpg"
    },
    "start_date": "2025-12-10",
    "end_date": "2025-12-15",
    "total_price": "300.00",
    "status": "pending",
    "notes": "Need for weekend photoshoot event",
    "created_at": "2025-12-03T14:30:45.000000Z"
  }
}
```

**Error Responses**:

*400 Bad Request* - Product not available

```json
{
  "message": "Product is not available for rent."
}
```

*400 Bad Request* - Date conflict

```json
{
  "message": "Product is not available for the selected dates."
}
```

---

## Update Rental Status

Update the status of a rental request. **Only product owner can update**.

**Endpoint**: `PUT /rentals/{id}`

**Authentication**: Required (Product owner only)

**Headers**:

```http
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:

- `id` (integer, required): Rental ID

**Request Body**:

```json
{
  "status": "approved",
  "notes": "Rental approved. Please contact for pickup details."
}
```

**Validation Rules**:

- `status`: required, in:approved,active,completed,cancelled
- `notes`: nullable, string, max:500

**Possible Status Values**:

- `pending`: Initial status
- `approved`: Owner approved the rental
- `active`: Rental is currently active
- `completed`: Rental completed successfully
- `cancelled`: Rental was cancelled

**Response** (200 OK):

```json
{
  "message": "Rental status updated successfully",
  "data": {
    "id": 10,
    "product": {
      "id": 25,
      "title": "Canon EOS R5 Camera",
      "owner": {
        "id": 5,
        "name": "Jane Smith"
      }
    },
    "renter": {
      "id": 1,
      "name": "John Doe"
    },
    "start_date": "2025-12-10",
    "end_date": "2025-12-15",
    "total_price": "300.00",
    "status": "approved",
    "notes": "Rental approved. Please contact for pickup details.",
    "updated_at": "2025-12-03T15:30:45.000000Z"
  }
}
```

**Error Responses**:

*403 Forbidden* - Not product owner

```json
{
  "message": "This action is unauthorized."
}
```

---

## Get User's Rentals

Retrieve all rental requests made by the authenticated user.

**Endpoint**: `GET /user/rentals`

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
      "id": 10,
      "product": {
        "id": 25,
        "title": "Canon EOS R5 Camera",
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
        "price_per_day": "50.00",
        "owner": {
          "id": 5,
          "name": "Jane Smith"
        }
      },
      "start_date": "2025-12-10",
      "end_date": "2025-12-15",
      "total_price": "300.00",
      "status": "approved",
      "created_at": "2025-12-03T14:30:45.000000Z"
    }
  ]
}
```

---

## Get Product's Rentals

Retrieve all rental requests for a specific product.

**Endpoint**: `GET /products/{productId}/rentals`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Path Parameters**:

- `productId` (integer, required): Product ID

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 10,
      "renter": {
        "id": 1,
        "name": "John Doe",
        "email": "john.doe@example.com",
        "avatar_url": "http://localhost:8000/storage/avatars/1_abc123.jpg"
      },
      "start_date": "2025-12-10",
      "end_date": "2025-12-15",
      "total_price": "300.00",
      "status": "approved",
      "notes": "Need for weekend photoshoot event",
      "created_at": "2025-12-03T14:30:45.000000Z"
    }
  ]
}
```

---
