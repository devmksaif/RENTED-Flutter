# Reviews Endpoints

## Overview

This document covers all endpoints related to product reviews and ratings in the Rented Marketplace API.

---

## Get Product Reviews

Retrieve all reviews for a specific product.

**Endpoint**: `GET /products/{productId}/reviews`

**Authentication**: Not required

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "rating": 5,
      "comment": "Excellent product! Highly recommend.",
      "user": {
        "id": 2,
        "name": "Jane Doe",
        "avatar_url": "http://localhost:8000/storage/avatars/xyz789.jpg"
      },
      "created_at": "2025-12-04T10:30:00.000000Z"
    }
  ]
}
```

---

## Get Product Rating Statistics

Get average rating and review count for a product.

**Endpoint**: `GET /products/{productId}/rating`

**Authentication**: Not required

**Response** (200 OK):

```json
{
  "average_rating": 4.5,
  "review_count": 42
}
```

**Notes**:
- Returns 0 for both values if no reviews exist
- Rating rounded to 1 decimal place

---

## Get User's Reviews

Retrieve all reviews written by authenticated user.

**Endpoint**: `GET /user/reviews`

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
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/abc123.jpg"
      },
      "rating": 5,
      "comment": "Great product, exactly as described!",
      "created_at": "2025-12-04T10:30:00.000000Z",
      "updated_at": "2025-12-04T10:30:00.000000Z"
    }
  ]
}
```

---

## Create Review

Create a new review for a product.

**Endpoint**: `POST /reviews`

**Authentication**: Required

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "product_id": 5,
  "rating": 5,
  "comment": "Excellent product! Highly recommend."
}
```

**Validation Rules**:

- `product_id`: required, must exist
- `rating`: required, integer between 1 and 5
- `comment`: optional, string, max 1000 characters

**Response** (201 Created):

```json
{
  "data": {
    "id": 1,
    "rating": 5,
    "comment": "Excellent product! Highly recommend.",
    "user": {
      "id": 1,
      "name": "John Doe"
    },
    "product": {
      "id": 5,
      "title": "Professional Camera"
    },
    "created_at": "2025-12-04T10:30:00.000000Z"
  }
}
```

**Errors**:

- **422 Unprocessable Entity**: Validation failed or duplicate review

```json
{
  "message": "You have already reviewed this product."
}
```

**Notes**:
- Users can only submit one review per product
- Cannot review own products

---

## Update Review

Update an existing review.

**Endpoint**: `PUT /reviews/{id}`

**Authentication**: Required (Owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "rating": 4,
  "comment": "Updated review comment"
}
```

**Validation Rules**:

- `rating`: optional, integer between 1 and 5
- `comment`: optional, string, max 1000 characters

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "rating": 4,
    "comment": "Updated review comment",
    "updated_at": "2025-12-04T11:00:00.000000Z"
  }
}
```

**Errors**:

- **403 Forbidden**: Not the review owner
- **404 Not Found**: Review doesn't exist

---

## Delete Review

Delete a review.

**Endpoint**: `DELETE /reviews/{id}`

**Authentication**: Required (Owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Response** (204 No Content)

**Errors**:

- **403 Forbidden**: Not the review owner
- **404 Not Found**: Review doesn't exist

---
