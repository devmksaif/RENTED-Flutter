# Favourites Endpoints

## Overview

This document covers all endpoints related to user favourites/wishlist functionality in the Rented Marketplace API.

---

## Get User's Favourites

Retrieve all products favourited by authenticated user.

**Endpoint**: `GET /favourites`

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
      "product": {
        "id": 5,
        "title": "Professional Camera",
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg",
        "price_per_day": "50.00",
        "location_city": "New York",
        "location_state": "NY"
      },
      "created_at": "2025-12-04T10:00:00.000000Z"
    }
  ]
}
```

---

## Toggle Favourite

Add or remove a product from favourites.

**Endpoint**: `POST /favourites/toggle`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "product_id": 5
}
```

**Validation Rules**:

- `product_id`: required, must exist

**Response** (200 OK) - Added:

```json
{
  "favourited": true,
  "message": "Product added to favourites"
}
```

**Response** (200 OK) - Removed:

```json
{
  "favourited": false,
  "message": "Product removed from favourites"
}
```

**Errors**:

- **422 Unprocessable Entity**: Invalid product ID

---

## Check if Product is Favourited

Check if a product is in user's favourites.

**Endpoint**: `GET /favourites/check/{productId}`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (200 OK):

```json
{
  "favourited": true
}
```

---

## Remove from Favourites

Remove a product from favourites.

**Endpoint**: `DELETE /favourites/{productId}`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (204 No Content)

**Errors**:

- **404 Not Found**: Product not in favourites

---
