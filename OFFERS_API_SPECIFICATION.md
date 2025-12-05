# Offers/Custom Offers API Specification

## Overview
This document specifies the API endpoints required to implement the offers/custom offers feature in the RENTED marketplace. This feature allows users to make custom offers (rental or purchase) to product owners within conversations, similar to Fiverr's offer system.

### Key Features
- Create custom offers (rental or purchase) within conversations
- Accept/reject offers with automatic rental/purchase creation
- Offer expiration system
- Real-time WebSocket notifications
- Offer history tracking
- Multiple pending offers per conversation

### API Characteristics
- **Architecture**: REST
- **Data Format**: JSON
- **Authentication**: Bearer Token (Sanctum)
- **Version**: v1
- **Database**: PostgreSQL 16

## Database Schema

### Offers Table (PostgreSQL)
```sql
CREATE TABLE offers (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    offer_type VARCHAR(20) NOT NULL DEFAULT 'rental' CHECK (offer_type IN ('rental', 'purchase')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    message TEXT NULL,
    start_date DATE NULL, -- For rental offers
    end_date DATE NULL, -- For rental offers
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL, -- Optional: auto-expire offers after X days
    
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX idx_offers_conversation ON offers(conversation_id);
CREATE INDEX idx_offers_sender ON offers(sender_id);
CREATE INDEX idx_offers_receiver ON offers(receiver_id);
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_created_at ON offers(created_at);
```

### Messages Table Update
Add a foreign key to link messages with offers:
```sql
ALTER TABLE messages ADD COLUMN offer_id BIGINT NULL;
ALTER TABLE messages ADD FOREIGN KEY (offer_id) REFERENCES offers(id) ON DELETE SET NULL;
```

## API Endpoints

### Base URL
All endpoints are under: `/api/v1/conversations/{conversationId}/offers`

**Development**: `http://localhost:8000/api/v1/conversations/{conversationId}/offers`
**Production**: `https://api.rentedmarketplace.com/api/v1/conversations/{conversationId}/offers`

### Common Headers
All authenticated requests require:
```http
Accept: application/json
Content-Type: application/json
Authorization: Bearer {token}
```

---

## 1. Create Offer

**Endpoint:** `POST /conversations/{conversationId}/offers`

**Description:** Creates a new offer in a conversation. This should also create a message automatically to notify the other party.

**Authentication:** Required

**Headers:**
```http
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Path Parameters:**
- `conversationId` (integer, required): Conversation ID

**Request Body:**
```json
{
  "amount": 150.00,
  "message": "I can offer $150 for a 3-day rental. Let me know if this works!",
  "offer_type": "rental",
  "start_date": "2025-12-15",
  "end_date": "2025-12-18"
}
```

**cURL Example:**
```bash
curl -X POST "http://localhost:8000/api/v1/conversations/45/offers" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 150.00,
    "message": "I can offer $150 for a 3-day rental.",
    "offer_type": "rental",
    "start_date": "2025-12-15",
    "end_date": "2025-12-18"
  }'
```

**Validation Rules:**
- `amount`: required, numeric, min:0.01, decimal(10,2)
- `offer_type`: required, in:rental,purchase
- `message`: nullable, string, max:1000
- `start_date`: required_if:offer_type,rental, date, after_or_equal:today
- `end_date`: required_if:offer_type,rental, date, after:start_date
- User must be a participant in the conversation
- Product must exist and be available (`is_available = true`)
- For rental offers: dates must not conflict with blocked dates (via `/products/{id}/check-availability`)
- For rental offers: dates must not conflict with existing rentals

**Response (201 Created):**
```json
{
  "message": "Offer created successfully",
  "data": {
    "id": 123,
    "conversation_id": 45,
    "sender_id": 10,
    "receiver_id": 15,
    "product_id": 78,
    "amount": "150.00",
    "offer_type": "rental",
    "status": "pending",
    "message": "I can offer $150 for a 3-day rental. Let me know if this works!",
    "start_date": "2025-12-15",
    "end_date": "2025-12-18",
    "created_at": "2025-12-10T10:30:00.000000Z",
    "updated_at": "2025-12-10T10:30:00.000000Z",
    "expires_at": "2025-12-17T10:30:00.000000Z",
    "accepted_at": null,
    "rejected_at": null,
    "sender": {
      "id": 10,
      "name": "John Doe",
      "avatar_url": "http://localhost:8000/storage/avatars/10_abc123.jpg"
    },
    "receiver": {
      "id": 15,
      "name": "Jane Smith",
      "avatar_url": "http://localhost:8000/storage/avatars/15_xyz789.jpg"
    },
    "product": {
      "id": 78,
      "title": "Canon EOS R5 Camera",
      "price_per_day": "200.00",
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/camera1.jpg"
    }
  }
}
```

**Error Responses:**

*400 Bad Request* - Product not available or dates conflict
```json
{
  "message": "Product is not available for the selected dates."
}
```

*401 Unauthorized* - Not authenticated
```json
{
  "message": "Unauthenticated."
}
```

*403 Forbidden* - User is not a participant in the conversation
```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Conversation or product not found
```json
{
  "message": "Resource not found."
}
```

*422 Unprocessable Entity* - Validation errors
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "amount": [
      "The amount must be greater than 0."
    ],
    "start_date": [
      "The start date must be in the future.",
      "The selected dates conflict with existing rentals."
    ]
  }
}
```

---

## 2. Accept Offer

**Endpoint:** `POST /conversations/{conversationId}/offers/{offerId}/accept`

**Description:** Accepts a pending offer. This should:
- Update offer status to "accepted"
- Create a rental or purchase record based on offer_type
- Send notification to the offer sender
- Optionally create a message in the conversation

**Authentication:** Required

**Headers:**
```http
Authorization: Bearer {token}
Accept: application/json
```

**Path Parameters:**
- `conversationId` (integer, required): Conversation ID
- `offerId` (integer, required): Offer ID

**Request Body:** None

**Validation Rules:**
- Offer must exist and belong to the conversation
- Offer status must be "pending"
- User must be the receiver of the offer (product owner)
- Product must still be available
- For rental offers: dates must still be available

**Response (200 OK):**
```json
{
  "message": "Offer accepted successfully",
  "data": {
    "offer": {
      "id": 123,
      "status": "accepted",
      "accepted_at": "2025-12-10T11:00:00.000000Z",
      "updated_at": "2025-12-10T11:00:00.000000Z"
    },
    "rental": {
      "id": 456,
      "product_id": 78,
      "user_id": 10,
      "start_date": "2025-12-15",
      "end_date": "2025-12-18",
      "total_price": "150.00",
      "status": "pending",
      "created_at": "2025-12-10T11:00:00.000000Z"
    }
  }
}
```

**Note**: For purchase offers, returns `purchase` object instead of `rental`:
```json
{
  "message": "Offer accepted successfully",
  "data": {
    "offer": {
      "id": 123,
      "status": "accepted",
      "accepted_at": "2025-12-10T11:00:00.000000Z"
    },
    "purchase": {
      "id": 789,
      "product_id": 78,
      "user_id": 10,
      "purchase_price": "150.00",
      "status": "pending",
      "created_at": "2025-12-10T11:00:00.000000Z"
    }
  }
}
```

**Error Responses:**

*400 Bad Request* - Offer cannot be accepted
```json
{
  "message": "Product is not available for the selected dates."
}
```

*401 Unauthorized* - Not authenticated
```json
{
  "message": "Unauthenticated."
}
```

*403 Forbidden* - User is not authorized to accept this offer
```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Offer not found
```json
{
  "message": "Resource not found."
}
```

*409 Conflict* - Offer status is not "pending"
```json
{
  "message": "Offer has already been accepted or rejected."
}
```

---

## 3. Reject Offer

**Endpoint:** `POST /conversations/{conversationId}/offers/{offerId}/reject`

**Description:** Rejects a pending offer.

**Authentication:** Required

**Headers:**
```http
Authorization: Bearer {token}
Accept: application/json
```

**Path Parameters:**
- `conversationId` (integer, required): Conversation ID
- `offerId` (integer, required): Offer ID

**Request Body:** None

**Validation Rules:**
- Offer must exist and belong to the conversation
- Offer status must be "pending"
- User must be the receiver of the offer

**Response (200 OK):**
```json
{
  "message": "Offer rejected successfully",
  "data": {
    "id": 123,
    "status": "rejected",
    "rejected_at": "2025-12-10T11:30:00.000000Z",
    "updated_at": "2025-12-10T11:30:00.000000Z"
  }
}
```

**Error Responses:**

*401 Unauthorized* - Not authenticated
```json
{
  "message": "Unauthenticated."
}
```

*403 Forbidden* - User is not authorized to reject this offer
```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Offer not found
```json
{
  "message": "Resource not found."
}
```

*409 Conflict* - Offer status is not "pending"
```json
{
  "message": "Offer has already been accepted or rejected."
}
```

---

## 4. Get Conversation Offers

**Endpoint:** `GET /conversations/{conversationId}/offers`

**Description:** Retrieves all offers for a conversation, ordered by creation date (newest first).

**Authentication:** Required

**Headers:**
```http
Authorization: Bearer {token}
Accept: application/json
```

**Path Parameters:**
- `conversationId` (integer, required): Conversation ID

**Query Parameters:**
- `status` (optional): Filter by status (pending, accepted, rejected, expired)
- `offer_type` (optional): Filter by type (rental, purchase)
- `page` (optional): Page number for pagination (default: 1)
- `per_page` (optional): Items per page (default: 20, max: 100)

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 123,
      "conversation_id": 45,
      "sender_id": 10,
      "receiver_id": 15,
      "product_id": 78,
      "amount": "150.00",
      "offer_type": "rental",
      "status": "pending",
      "message": "I can offer $150 for a 3-day rental.",
      "start_date": "2025-12-15",
      "end_date": "2025-12-18",
      "created_at": "2025-12-10T10:30:00.000000Z",
      "updated_at": "2025-12-10T10:30:00.000000Z",
      "expires_at": "2025-12-17T10:30:00.000000Z",
      "accepted_at": null,
      "rejected_at": null,
      "sender": {
        "id": 10,
        "name": "John Doe",
        "avatar_url": "http://localhost:8000/storage/avatars/10_abc123.jpg"
      },
      "receiver": {
        "id": 15,
        "name": "Jane Smith",
        "avatar_url": "http://localhost:8000/storage/avatars/15_xyz789.jpg"
      },
      "product": {
        "id": 78,
        "title": "Canon EOS R5 Camera",
        "price_per_day": "200.00",
        "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/camera1.jpg"
      }
    }
  ],
  "links": {
    "first": "http://localhost:8000/api/v1/conversations/45/offers?page=1",
    "last": "http://localhost:8000/api/v1/conversations/45/offers?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "per_page": 20,
    "to": 1,
    "total": 1
  }
}
```

**Error Responses:**

*401 Unauthorized* - Not authenticated
```json
{
  "message": "Unauthenticated."
}
```

*403 Forbidden* - User is not a participant in the conversation
```json
{
  "message": "This action is unauthorized."
}
```

*404 Not Found* - Conversation not found
```json
{
  "message": "Resource not found."
}
```

---

## 5. Get Single Offer

**Endpoint:** `GET /conversations/{conversationId}/offers/{offerId}`

**Description:** Retrieves details of a specific offer.

**Authentication:** Required

**Headers:**
```http
Authorization: Bearer {token}
Accept: application/json
```

**Path Parameters:**
- `conversationId` (integer, required): Conversation ID
- `offerId` (integer, required): Offer ID

**Response (200 OK):**
```json
{
  "data": {
    "id": 123,
    "conversation_id": 45,
    "sender_id": 10,
    "receiver_id": 15,
    "product_id": 78,
    "amount": "150.00",
    "offer_type": "rental",
    "status": "pending",
    "message": "I can offer $150 for a 3-day rental.",
    "start_date": "2025-12-15",
    "end_date": "2025-12-18",
    "created_at": "2025-12-10T10:30:00.000000Z",
    "updated_at": "2025-12-10T10:30:00.000000Z",
    "expires_at": "2025-12-17T10:30:00.000000Z",
    "accepted_at": null,
    "rejected_at": null,
    "sender": {
      "id": 10,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/10_abc123.jpg"
    },
    "receiver": {
      "id": 15,
      "name": "Jane Smith",
      "email": "jane.smith@example.com",
      "avatar_url": "http://localhost:8000/storage/avatars/15_xyz789.jpg"
    },
    "product": {
      "id": 78,
      "title": "Canon EOS R5 Camera",
      "price_per_day": "200.00",
      "thumbnail_url": "http://localhost:8000/storage/products/thumbnails/camera1.jpg",
      "image_urls": [
        "http://localhost:8000/storage/products/images/camera1-1.jpg",
        "http://localhost:8000/storage/products/images/camera1-2.jpg"
      ]
    }
  }
}
```

---

## 6. Update Messages to Include Offers

When a message is created with an offer, the message response should include the offer data:

**Message Response Format:**
When a message is created with an offer, the message response should include the offer data:
```json
{
  "data": {
    "id": 789,
    "conversation_id": 45,
    "sender_id": 10,
    "content": "I've sent you an offer",
    "offer": {
      "id": 123,
      "amount": "150.00",
      "offer_type": "rental",
      "status": "pending",
      "message": "I can offer $150 for a 3-day rental.",
      "start_date": "2025-12-15",
      "end_date": "2025-12-18",
      "created_at": "2025-12-10T10:30:00.000000Z"
    },
    "is_read": false,
    "read_at": null,
    "created_at": "2025-12-10T10:30:00.000000Z",
    "sender": {
      "id": 10,
      "name": "John Doe",
      "avatar_url": "http://localhost:8000/storage/avatars/10_abc123.jpg"
    }
  }
}
```

---

## Business Logic Requirements

### Offer Creation
1. **Automatic Message Creation**: When an offer is created, automatically create a message in the conversation with the offer attached.
2. **Date Validation**: For rental offers, validate that:
   - Start date is in the future
   - End date is after start date
   - Dates don't conflict with blocked dates
   - Dates don't conflict with existing rentals
3. **Product Availability**: Ensure product is still available and not sold
4. **Expiration**: Optionally set expiration date (e.g., 7 days from creation)

### Offer Acceptance
1. **Rental Offers**: When accepted, create a rental record with:
   - Product ID
   - Renter ID (offer sender)
   - Start date and end date from offer
   - Total price = offer amount
   - Status = "pending" (awaiting payment/confirmation)
2. **Purchase Offers**: When accepted, create a purchase record with:
   - Product ID
   - Buyer ID (offer sender)
   - Price = offer amount
   - Status = "pending"
3. **Notifications**: Send push/email notifications to both parties
4. **Message Creation**: Optionally create a message confirming acceptance

### Offer Rejection
1. **Status Update**: Update offer status to "rejected"
2. **Notification**: Notify the offer sender
3. **Message Creation**: Optionally create a message confirming rejection

### Offer Expiration
1. **Auto-Expire**: Run a scheduled job to expire offers after expiration date
2. **Status Update**: Change status from "pending" to "expired"
3. **Notification**: Optionally notify the offer sender

---

## WebSocket Events

### Offer Created
When an offer is created, broadcast to conversation participants:
```json
{
  "event": "offer.created",
  "data": {
    "conversation_id": 45,
    "offer": {
      "id": 123,
      "amount": "150.00",
      "offer_type": "rental",
      "status": "pending",
      "sender_id": 10,
      "receiver_id": 15
    },
    "message": {
      "id": 789,
      "content": "I've sent you an offer",
      "conversation_id": 45,
      "sender_id": 10,
      "offer": {
        "id": 123,
        "amount": "150.00",
        "offer_type": "rental",
        "status": "pending"
      }
    }
  }
}
```

### Offer Accepted
```json
{
  "event": "offer.accepted",
  "data": {
    "conversation_id": 45,
    "offer_id": 123,
    "status": "accepted",
    "accepted_at": "2025-12-10T11:00:00.000000Z",
    "rental": {
      "id": 456,
      "product_id": 78,
      "user_id": 10,
      "start_date": "2025-12-15",
      "end_date": "2025-12-18",
      "total_price": "150.00",
      "status": "pending"
    }
  }
}
```

**Note**: For purchase offers, returns `purchase` object instead of `rental`.

### Offer Rejected
```json
{
  "event": "offer.rejected",
  "data": {
    "conversation_id": 45,
    "offer_id": 123,
    "status": "rejected",
    "rejected_at": "2025-12-10T11:30:00.000000Z"
  }
}
```

---

## Error Response Format

All errors should follow this format (consistent with existing API):
```json
{
  "message": "Error description",
  "errors": {
    "field_name": [
      "Validation error message"
    ]
  }
}
```

**Example Validation Error:**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "amount": [
      "The amount must be greater than 0."
    ],
    "start_date": [
      "The start date must be in the future.",
      "The selected dates conflict with existing rentals."
    ]
  }
}
```

**Example Simple Error:**
```json
{
  "message": "Product is not available for the selected dates."
}
```

---

## Testing Checklist

- [ ] Create offer with valid data
- [ ] Create offer with invalid amount (negative, zero, non-numeric)
- [ ] Create rental offer without dates
- [ ] Create rental offer with invalid date range
- [ ] Create offer for non-existent conversation
- [ ] Create offer by non-participant
- [ ] Accept pending offer
- [ ] Accept already accepted/rejected offer
- [ ] Accept offer by non-receiver
- [ ] Reject pending offer
- [ ] Reject already accepted/rejected offer
- [ ] Get offers for conversation
- [ ] Filter offers by status
- [ ] Filter offers by type
- [ ] Pagination works correctly
- [ ] WebSocket events fire correctly
- [ ] Auto-expiration works
- [ ] Date conflict validation works
- [ ] Product availability validation works

---

## Flutter Implementation Example

### Offer Service
```dart
// lib/services/offer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class OfferService {
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> createOffer({
    required int conversationId,
    required double amount,
    String? message,
    String? offerType,
    String? startDate,
    String? endDate,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw ApiError(message: 'Not authenticated', statusCode: 401);
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.conversations}/$conversationId/offers'),
      headers: ApiConfig.getAuthHeaders(token),
      body: jsonEncode({
        'amount': amount,
        if (message != null) 'message': message,
        if (offerType != null) 'offer_type': offerType,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return responseData['data'];
    } else {
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> acceptOffer({
    required int conversationId,
    required int offerId,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw ApiError(message: 'Not authenticated', statusCode: 401);
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.conversations}/$conversationId/offers/$offerId/accept'),
      headers: ApiConfig.getAuthHeaders(token),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData['data'];
    } else {
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<void> rejectOffer({
    required int conversationId,
    required int offerId,
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw ApiError(message: 'Not authenticated', statusCode: 401);
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.conversations}/$conversationId/offers/$offerId/reject'),
      headers: ApiConfig.getAuthHeaders(token),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> getConversationOffers(int conversationId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw ApiError(message: 'Not authenticated', statusCode: 401);
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.conversations}/$conversationId/offers'),
      headers: ApiConfig.getAuthHeaders(token),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
    } else {
      throw ApiError.fromJson(responseData, response.statusCode);
    }
  }
}
```

## Notes

1. **Security**: Ensure users can only create/accept/reject offers in conversations they are part of
2. **Performance**: Index the offers table properly for fast queries (indexes already defined in schema)
3. **Notifications**: Consider implementing real-time notifications for offer events via WebSocket
4. **Expiration**: Consider implementing a background job to auto-expire offers (Laravel scheduled tasks)
5. **History**: Keep offer history even after acceptance/rejection for audit purposes
6. **Multiple Offers**: Users can have multiple pending offers in the same conversation
7. **Offer Updates**: Consider allowing users to update pending offers (optional feature for future)
8. **Database**: Uses PostgreSQL 16 (not MySQL), so use appropriate PostgreSQL syntax
9. **Timestamps**: All timestamps use format `YYYY-MM-DDTHH:mm:ss.000000Z` (6 decimal places)
10. **Response Format**: Follows existing API pattern - no `success` field, just `message` and `data` for success, `message` and optional `errors` for failures
11. **Pagination**: Uses Laravel's standard pagination format with `links` and `meta` objects
12. **Field Naming**: All fields use snake_case consistently
13. **Rental Status**: When offer is accepted and creates rental, rental status should be `pending` (not `confirmed` or `approved`)
14. **Purchase Status**: When offer is accepted and creates purchase, purchase status should be `pending`
15. **Message Integration**: When an offer is created, automatically create a message in the conversation with `offer_id` set
16. **Availability Check**: Before accepting rental offers, verify dates are still available using existing `/products/{id}/check-availability` endpoint

