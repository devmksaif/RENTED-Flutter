# Rental Availability Endpoints

## Overview

This document covers all endpoints related to product rental availability and calendar management in the Rented Marketplace API.

---

## Get Product Availability Calendar

Get blocked dates for a product within a date range.

**Endpoint**: `GET /products/{productId}/availability`

**Authentication**: Not required

**Query Parameters**:

- `start_date`: optional, format YYYY-MM-DD (defaults to today)
- `end_date`: optional, format YYYY-MM-DD (defaults to 30 days from start)

**Example**: `GET /products/5/availability?start_date=2025-12-01&end_date=2025-12-31`

**Response** (200 OK):

```json
{
  "product_id": 5,
  "blocked_dates": [
    {
      "date": "2025-12-10",
      "block_type": "booked",
      "rental_id": 3
    },
    {
      "date": "2025-12-11",
      "block_type": "booked",
      "rental_id": 3
    },
    {
      "date": "2025-12-15",
      "block_type": "maintenance",
      "notes": "Camera servicing scheduled"
    }
  ]
}
```

**Block Types**:
- `booked`: Date reserved by rental
- `maintenance`: Owner-blocked for maintenance/personal use

---

## Check Date Availability

Check if product is available for specific dates.

**Endpoint**: `POST /products/{productId}/check-availability`

**Authentication**: Not required

**Request Body**:

```json
{
  "start_date": "2025-12-20",
  "end_date": "2025-12-25"
}
```

**Validation Rules**:

- `start_date`: required, date format YYYY-MM-DD, today or future
- `end_date`: required, date format YYYY-MM-DD, after start_date

**Response** (200 OK) - Available:

```json
{
  "available": true,
  "message": "Product is available for the selected dates"
}
```

**Response** (200 OK) - Not Available:

```json
{
  "available": false,
  "message": "Product is not available for some dates in the selected range",
  "blocked_dates": ["2025-12-22", "2025-12-23"]
}
```

**Errors**:

- **422 Unprocessable Entity**: Invalid dates

---

## Block Dates for Maintenance

Owner can block dates for maintenance or personal use.

**Endpoint**: `POST /products/{productId}/block-dates`

**Authentication**: Required (Product owner only)

**Headers**:

```http
Authorization: Bearer {token}
```

**Request Body**:

```json
{
  "dates": ["2025-12-15", "2025-12-16", "2025-12-17"],
  "notes": "Camera maintenance and sensor cleaning"
}
```

**Validation Rules**:

- `dates`: required, array of dates in YYYY-MM-DD format
- `notes`: optional, string, max 500 characters

**Response** (201 Created):

```json
{
  "message": "Dates blocked successfully",
  "blocked_count": 3
}
```

**Errors**:

- **403 Forbidden**: Not the product owner
- **422 Unprocessable Entity**: Invalid dates or dates already booked

**Notes**:
- Cannot block dates that are already booked by rentals
- Can override existing maintenance blocks

---
