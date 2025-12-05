# Categories Endpoints

## Overview

This document covers all endpoints related to product categories in the Rented Marketplace API.

---

## Get All Categories

Retrieve a list of all active categories.

**Endpoint**: `GET /categories`

**Authentication**: Not required

**Response** (200 OK):

```json
{
  "data": [
    {
      "id": 1,
      "name": "Electronics",
      "slug": "electronics",
      "description": "Electronic devices and gadgets",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Photography",
      "slug": "photography",
      "description": "Cameras, lenses, and photography equipment",
      "is_active": true
    },
    {
      "id": 3,
      "name": "Sports Equipment",
      "slug": "sports-equipment",
      "description": "Sports gear and athletic equipment",
      "is_active": true
    }
  ]
}
```

**Cache**: This endpoint is cached for 1 hour.

---

## Get Single Category

Retrieve details of a specific category.

**Endpoint**: `GET /categories/{id}`

**Authentication**: Not required

**Path Parameters**:

- `id` (integer, required): Category ID

**Response** (200 OK):

```json
{
  "data": {
    "id": 1,
    "name": "Electronics",
    "slug": "electronics",
    "description": "Electronic devices and gadgets",
    "is_active": true
  }
}
```

**Error Responses**:

*404 Not Found* - Category doesn't exist

```json
{
  "message": "Resource not found."
}
```

---
