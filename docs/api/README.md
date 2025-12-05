# Rented Marketplace API Documentation

This directory contains detailed API documentation organized by feature area.

## Documentation Index

### Core Authentication & User Management

- **[AUTHENTICATION.md](./AUTHENTICATION.md)** - User registration, login, logout, and current user retrieval
- **[USER_PROFILE.md](./USER_PROFILE.md)** - User profile updates, avatar management, and user verification
- **[GOOGLE_OAUTH.md](./GOOGLE_OAUTH.md)** - Google OAuth 2.0 authentication flow
- **[PASSWORD_RESET.md](./PASSWORD_RESET.md)** - Password reset via email

### System & Health

- **[HEALTH_CHECK.md](./HEALTH_CHECK.md)** - API health check and status endpoint

### Products & Categories

- **[CATEGORIES.md](./CATEGORIES.md)** - Product category management
- **[PRODUCTS.md](./PRODUCTS.md)** - Product listing, creation, update, and deletion
- **[PRODUCT_VERIFICATION.md](./PRODUCT_VERIFICATION.md)** - Admin product verification and approval

### Transactions

- **[RENTALS.md](./RENTALS.md)** - Rental requests and management
- **[PURCHASES.md](./PURCHASES.md)** - Product purchase transactions
- **[RENTAL_AVAILABILITY.md](./RENTAL_AVAILABILITY.md)** - Product availability calendar and date blocking

### User Interactions

- **[REVIEWS.md](./REVIEWS.md)** - Product reviews and ratings
- **[FAVOURITES.md](./FAVOURITES.md)** - User favorites/wishlist
- **[CONVERSATIONS.md](./CONVERSATIONS.md)** - User messaging and conversations
- **[DISPUTES.md](./DISPUTES.md)** - Dispute resolution system

## Quick Reference

### Base URL

- **Development**: `http://localhost:8000/api/v1`
- **Production**: `https://api.rentedmarketplace.com/api/v1`

### Authentication

Most endpoints require authentication using Bearer tokens:

```http
Authorization: Bearer {your-token-here}
```

### Common Headers

```http
Accept: application/json
Content-Type: application/json
```

### Response Format

All responses follow a consistent structure:

```json
{
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Format

```json
{
  "message": "Error description",
  "errors": {
    "field_name": ["Validation error message"]
  }
}
```

## Getting Started

1. **Register/Login**: See [AUTHENTICATION.md](./AUTHENTICATION.md)
2. **Verify Account**: See [USER_PROFILE.md](./USER_PROFILE.md#user-verification-endpoints)
3. **Create Product**: See [PRODUCTS.md](./PRODUCTS.md#create-product)
4. **Browse Products**: See [PRODUCTS.md](./PRODUCTS.md#get-all-products)

## Feature Overview

### User Features
- ✅ Email/Password Authentication
- ✅ Google OAuth Login
- ✅ Password Reset
- ✅ Profile Management
- ✅ Avatar Upload
- ✅ Account Verification

### Product Features
- ✅ Product Listings
- ✅ Product Search & Filtering
- ✅ Product Categories
- ✅ Product Reviews & Ratings
- ✅ Favorites/Wishlist
- ✅ Product Verification (Admin)

### Transaction Features
- ✅ Rental Requests
- ✅ Purchase Requests
- ✅ Availability Calendar
- ✅ Date Blocking

### Communication Features
- ✅ User Messaging
- ✅ Conversations
- ✅ Real-time Chat

### Support Features
- ✅ Dispute Resolution
- ✅ Health Check

## Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 204 | No Content | Request succeeded, no content |
| 400 | Bad Request | Invalid request |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## Rate Limiting

- **Public Endpoints**: 60 requests per minute
- **Authenticated Endpoints**: 120 requests per minute
- **Verification Image Endpoint**: 60 requests per minute

## File Uploads

### Supported Formats
- **Images**: JPEG, JPG, PNG
- **Documents**: JPEG, JPG, PNG, PDF

### Size Limits
- **Avatars**: 2 MB, 100x100 to 2000x2000 pixels
- **Product Images**: 2 MB per file, max 5 images
- **Verification Documents**: 5 MB per file

## Pagination

Most list endpoints support pagination:

```
GET /products?page=1&per_page=20
```

Response includes pagination metadata:

```json
{
  "data": [...],
  "links": {
    "first": "...",
    "last": "...",
    "prev": null,
    "next": "..."
  },
  "meta": {
    "current_page": 1,
    "last_page": 10,
    "per_page": 20,
    "total": 200
  }
}
```

## Need Help?

- Check individual documentation files for detailed endpoint information
- Review error responses for troubleshooting
- See Flutter implementation examples in each document

## Related Documentation

- Main API Reference: `../../ap.md`
- Database Schema: See `../../ap.md#database-schema`
- Flutter SDK Guide: See `../../ap.md#flutter-sdk-implementation-guide`

