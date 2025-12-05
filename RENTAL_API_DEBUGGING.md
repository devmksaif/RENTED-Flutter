# Rental API Debugging & Business Logic

## Current Status: ⚠️ REQUIRES TESTING

### Issues Identified

1. **Network Error on Rental Creation**
   - Error occurs when user tries to rent a product
   - Root cause: Unknown (API server not running during test)
   - Need to test with running API

2. **Business Logic Questions**

   #### Q1: Should products have quantity/inventory?
   **Current**: Each product is treated as a single unit  
   **Proposal**: Add inventory tracking
   
   ```json
   {
     "quantity": 10,
     "available_quantity": 7,
     "rented_quantity": 3
   }
   ```
   
   **Pros**:
   - Sellers can rent multiple units
   - Better for items like chairs, bikes, etc.
   - More flexible for businesses
   
   **Cons**:
   - Adds complexity
   - Requires database schema changes
   - Each unit needs tracking
   
   **Recommendation**: Start without quantity, add later if needed

   #### Q2: How to prevent double-booking?
   **Current**: No date conflict checking  
   **Problem**: Two users can book same product for overlapping dates
   
   **Solution Options**:
   
   A. **API-Side Prevention** (Recommended)
   ```
   1. User submits rental request
   2. API checks for overlapping approved/active rentals
   3. If conflict exists, return 400 error
   4. If no conflict, create rental with "pending" status
   ```
   
   B. **Client-Side Validation**
   ```
   1. Fetch existing rentals before booking
   2. Show blocked dates in calendar
   3. Prevent submission if dates overlap
   4. Still validate on API side
   ```
   
   **Recommendation**: Implement both for best UX

   #### Q3: Rental Status Flow
   **Current Flow**:
   ```
   pending → approved → active → completed
                ↓
            cancelled
   ```
   
   **Questions**:
   - Should "approved" automatically become "active" on start date?
   - Who marks rental as "completed"?
   - Can renter cancel after approval?
   - What about deposits/payments?
   
   **Recommendations**:
   - Keep manual status updates for now
   - Add scheduled tasks for auto-activation later
   - Allow cancellation before "active" status
   - Payment integration is future enhancement

## Improvements Implemented

### 1. Enhanced Rental Service (rental_service.dart)

#### Added Validations:
- ✅ Date format validation (YYYY-MM-DD)
- ✅ End date must be after start date
- ✅ Start date cannot be in the past
- ✅ Empty notes are not sent to API

#### Added Debugging:
- ✅ Request URL logging
- ✅ Request body logging
- ✅ Response status logging
- ✅ Response body logging
- ✅ Error details logging

#### Sample Debug Output:
```
Rental Request: http://localhost:8000/api/v1/rentals
Request Body: {"product_id":1,"start_date":"2025-12-10","end_date":"2025-12-15"}
Rental Response Status: 201
Rental Response Body: {"message":"Rental request created successfully",...}
```

### 2. Date Conflict Prevention (Future Enhancement)

#### Add to RentalService:
```dart
/// Check if product is available for given dates
Future<bool> checkDateAvailability(
  int productId,
  DateTime startDate,
  DateTime endDate,
) async {
  try {
    final rentals = await getProductRentals(productId);
    
    // Filter for approved/active rentals only
    final activeRentals = rentals.where(
      (r) => r.status == 'approved' || r.status == 'active'
    );
    
    // Check for date overlaps
    for (final rental in activeRentals) {
      if (_datesOverlap(
        startDate, endDate,
        rental.startDate, rental.endDate
      )) {
        return false; // Dates conflict
      }
    }
    
    return true; // Dates available
  } catch (e) {
    return false; // Assume unavailable on error
  }
}

bool _datesOverlap(
  DateTime start1, DateTime end1,
  DateTime start2, DateTime end2,
) {
  return start1.isBefore(end2) && end1.isAfter(start2);
}
```

#### Use in ProductDetailScreen:
```dart
Future<void> _createRental(String startDate, String endDate) async {
  final start = DateTime.parse(startDate);
  final end = DateTime.parse(endDate);
  
  // Check availability first
  final isAvailable = await _rentalService.checkDateAvailability(
    _product!.id, start, end
  );
  
  if (!isAvailable) {
    Fluttertoast.showToast(
      msg: 'Product not available for selected dates',
      backgroundColor: Colors.red,
    );
    return;
  }
  
  // Proceed with rental...
}
```

## Testing Checklist

### Basic Rental Creation
- [ ] Create rental with valid dates
- [ ] Verify rental appears in "My Rentals"
- [ ] Check owner receives rental request
- [ ] Owner can approve/reject rental
- [ ] Status updates correctly

### Date Validation
- [ ] Cannot select past dates
- [ ] End date must be after start date
- [ ] Invalid format rejected
- [ ] Proper error messages shown

### Edge Cases
- [ ] Same product, different date ranges
- [ ] Same product, overlapping dates
- [ ] Rental dates in far future
- [ ] Very long rental period (30+ days)
- [ ] Same-day rental

### Network Errors
- [ ] API server down
- [ ] Timeout handling
- [ ] Invalid token
- [ ] Product not found
- [ ] Product not available

## API Contract (from api.md)

### Create Rental Request

**Endpoint**: `POST /api/v1/rentals`

**Request**:
```json
{
  "product_id": 25,
  "start_date": "2025-12-10",
  "end_date": "2025-12-15",
  "notes": "Need for weekend photoshoot event"
}
```

**Validation Rules**:
- `product_id`: required, exists in products
- `start_date`: required, date, after_or_equal:today
- `end_date`: required, date, after:start_date
- `notes`: nullable, string, max:500

**Success Response (201)**:
```json
{
  "message": "Rental request created successfully",
  "data": {
    "id": 10,
    "product": {...},
    "renter": {...},
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

**400 - Product not available**:
```json
{
  "message": "Product is not available for rent."
}
```

**400 - Date conflict**:
```json
{
  "message": "Product is not available for the selected dates."
}
```

## Next Steps

1. **Start API Server**: Test with running backend
   ```bash
   cd rented-api
   php artisan serve
   ```

2. **Test Rental Flow**: Create actual rental with app

3. **Check Logs**: Review debug output in console

4. **Fix Any Issues**: Based on actual API responses

5. **Implement Date Checking**: If API doesn't prevent conflicts

6. **Remove Debug Logs**: Before production

## Future Enhancements

### P1 - High Priority
- [ ] Date conflict prevention (client-side)
- [ ] Calendar view for availability
- [ ] Blocked dates display
- [ ] Price calculation preview

### P2 - Medium Priority
- [ ] Quantity/inventory management
- [ ] Auto-status updates (cron jobs)
- [ ] Rental history
- [ ] Rating system after rental

### P3 - Low Priority
- [ ] Deposit management
- [ ] Payment integration
- [ ] Insurance options
- [ ] Extended rental periods
- [ ] Rental reminders

---

**Status**: Debugging improvements added, awaiting API testing  
**Last Updated**: December 4, 2025
