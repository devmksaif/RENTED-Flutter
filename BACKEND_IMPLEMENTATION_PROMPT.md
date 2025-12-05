# Backend Implementation Prompt for Offers Feature

## Overview
Implement the Offers/Custom Offers feature for the RENTED marketplace API. This allows users to make custom offers (rental or purchase) to product owners within conversations, similar to Fiverr's offer system.

## Implementation Checklist

### 1. Database Migration
- [ ] Create `offers` table migration (PostgreSQL)
- [ ] Add `offer_id` column to `messages` table
- [ ] Create indexes for performance
- [ ] Add foreign key constraints

### 2. Model Creation
- [ ] Create `Offer` model with relationships:
  - `belongsTo`: Conversation, Sender (User), Receiver (User), Product
  - `hasOne`: Message (optional)
- [ ] Add fillable/castable fields
- [ ] Add accessors/mutators if needed
- [ ] Add scopes for filtering (by status, type, etc.)

### 3. Controller Implementation
- [ ] Create `OfferController` with methods:
  - `store()` - Create offer
  - `show()` - Get single offer
  - `index()` - List conversation offers
  - `accept()` - Accept offer
  - `reject()` - Reject offer
- [ ] Add proper authorization checks
- [ ] Implement validation rules
- [ ] Handle business logic (date conflicts, availability, etc.)

### 4. Request Validation
- [ ] Create `StoreOfferRequest` form request
- [ ] Validate amount (required, numeric, min:0.01)
- [ ] Validate offer_type (required, in:rental,purchase)
- [ ] Validate dates for rental offers (required_if, after_or_equal:today, after:start_date)
- [ ] Validate message (nullable, max:1000)
- [ ] Check conversation participation
- [ ] Check product availability
- [ ] Check date availability for rental offers

### 5. Business Logic
- [ ] **Offer Creation**:
  - Validate user is conversation participant
  - Validate product is available
  - For rental offers: check date availability via existing endpoint
  - Set expiration date (optional: 7 days from creation)
  - Create offer record
  - Automatically create message with offer attached
  - Broadcast WebSocket event
  
- [ ] **Offer Acceptance**:
  - Verify offer status is "pending"
  - Verify user is receiver (product owner)
  - For rental offers: verify dates still available
  - Update offer status to "accepted"
  - Create rental or purchase record:
    - Rental: use offer amount as total_price, dates from offer
    - Purchase: use offer amount as purchase_price
  - Set rental/purchase status to "pending"
  - Broadcast WebSocket event
  - Send notifications
  
- [ ] **Offer Rejection**:
  - Verify offer status is "pending"
  - Verify user is receiver
  - Update offer status to "rejected"
  - Broadcast WebSocket event
  - Send notification

### 6. Routes
Add to `routes/api.php`:
```php
Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('conversations/{conversation}')->group(function () {
        Route::get('offers', [OfferController::class, 'index']);
        Route::post('offers', [OfferController::class, 'store']);
        Route::get('offers/{offer}', [OfferController::class, 'show']);
        Route::post('offers/{offer}/accept', [OfferController::class, 'accept']);
        Route::post('offers/{offer}/reject', [OfferController::class, 'reject']);
    });
});
```

### 7. Policies/Authorization
- [ ] Create `OfferPolicy`:
  - `create()` - User must be conversation participant
  - `view()` - User must be conversation participant
  - `accept()` - User must be offer receiver
  - `reject()` - User must be offer receiver

### 8. Resources/Transformers
- [ ] Create `OfferResource` for consistent API responses
- [ ] Include relationships: sender, receiver, product
- [ ] Format dates properly
- [ ] Include status indicators

### 9. WebSocket Events
- [ ] Broadcast `offer.created` event to conversation participants
- [ ] Broadcast `offer.accepted` event
- [ ] Broadcast `offer.rejected` event
- [ ] Include offer data and related message in events

### 10. Notifications
- [ ] Create notification for offer received
- [ ] Create notification for offer accepted
- [ ] Create notification for offer rejected
- [ ] Send via email and push (if implemented)

### 11. Scheduled Jobs (Optional)
- [ ] Create job to expire offers after expiration date
- [ ] Schedule to run daily
- [ ] Update offer status to "expired"
- [ ] Send notification to offer sender

### 12. Testing
- [ ] Unit tests for Offer model
- [ ] Feature tests for all endpoints
- [ ] Test authorization (can't accept/reject others' offers)
- [ ] Test date validation
- [ ] Test availability conflicts
- [ ] Test automatic rental/purchase creation
- [ ] Test WebSocket events
- [ ] Test pagination

## Key Implementation Details

### Database Schema
See `OFFERS_API_SPECIFICATION.md` for complete PostgreSQL schema.

### Response Format
Follow existing API pattern:
- Success: `{"message": "...", "data": {...}}`
- Error: `{"message": "...", "errors": {...}}`
- No `success` boolean field

### Date Validation
For rental offers, use existing availability check:
```php
// Check availability before creating/accepting rental offer
$availabilityResponse = Http::get("{$baseUrl}/products/{$productId}/check-availability", [
    'start_date' => $startDate,
    'end_date' => $endDate,
]);

if (!$availabilityResponse->json()['available']) {
    throw ValidationException::withMessages([
        'dates' => ['Product is not available for the selected dates.'],
    ]);
}
```

### Automatic Message Creation
When offer is created, automatically create message:
```php
$message = Message::create([
    'conversation_id' => $conversation->id,
    'sender_id' => auth()->id(),
    'content' => $request->message ?? 'I\'ve sent you an offer',
    'offer_id' => $offer->id,
]);
```

### Rental/Purchase Creation on Acceptance
```php
if ($offer->offer_type === 'rental') {
    $rental = Rental::create([
        'product_id' => $offer->product_id,
        'user_id' => $offer->sender_id,
        'start_date' => $offer->start_date,
        'end_date' => $offer->end_date,
        'total_price' => $offer->amount,
        'status' => 'pending',
    ]);
} else {
    $purchase = Purchase::create([
        'product_id' => $offer->product_id,
        'user_id' => $offer->sender_id,
        'purchase_price' => $offer->amount,
        'status' => 'pending',
    ]);
}
```

## API Endpoints Summary

1. **POST** `/conversations/{conversationId}/offers` - Create offer
2. **GET** `/conversations/{conversationId}/offers` - List offers (with pagination)
3. **GET** `/conversations/{conversationId}/offers/{offerId}` - Get single offer
4. **POST** `/conversations/{conversationId}/offers/{offerId}/accept` - Accept offer
5. **POST** `/conversations/{conversationId}/offers/{offerId}/reject` - Reject offer

## Reference Documentation
See `OFFERS_API_SPECIFICATION.md` for complete API specification including:
- Request/response formats
- Validation rules
- Error responses
- WebSocket events
- Business logic requirements
- Testing checklist

## Integration Points
- Uses existing `/products/{id}/check-availability` endpoint
- Creates rentals via existing rental system
- Creates purchases via existing purchase system
- Integrates with existing conversation/message system
- Uses existing notification system (if implemented)

