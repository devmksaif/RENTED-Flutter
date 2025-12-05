# RENTED App - Implementation Priorities & Roadmap

**Last Updated**: December 4, 2025

---

## 🔴 CRITICAL ISSUES (Fix Immediately)

### 1. Profile Verification Badge Not Working ❌
**Priority**: P0 - CRITICAL  
**Status**: 🔴 BROKEN  
**Issue**: User model checks for `verificationStatus == 'approved'` but API returns `'verified'`  
**Impact**: Users show "Not Verified" even when verified by admin  
**Solution**: Change User model getter from `'approved'` to `'verified'`  
**Files**: `lib/models/user.dart`  
**ETA**: 5 minutes

---

### 2. Rental API Network Errors ❌
**Priority**: P0 - CRITICAL  
**Status**: 🔴 BROKEN  
**Issue**: Rental creation fails with network errors  
**Root Cause**: 
- API endpoint validation errors
- Missing proper error handling
- Date format issues
**Impact**: Users cannot rent products  
**Solution**:
1. Add better error logging
2. Validate date formats before sending
3. Add API response debugging
4. Check if API server is running

**Files**: 
- `lib/services/rental_service.dart`
- `lib/screens/product_detail_screen.dart`

**Business Logic Issues to Address**:
- ❓ Should products have quantity tracking?
- ❓ How to prevent double-booking of same product?
- ❓ Should we check date conflicts before submission?
- ❓ What happens if rental dates overlap?

**ETA**: 30 minutes

---

## 🟠 HIGH PRIORITY (Implement Next)

### 3. Local Favorites Storage 🔄
**Priority**: P1 - HIGH  
**Status**: 🟡 NEEDS IMPLEMENTATION  
**Current**: Uses API calls (requires network)  
**Requested**: Local storage with SharedPreferences  
**Benefits**:
- Works offline
- Faster response
- No API dependency
- Better UX

**Implementation Plan**:
1. Create `LocalFavoritesService` using SharedPreferences
2. Store favorites as JSON array of product IDs
3. Sync with product list to display full details
4. Add/remove favorites instantly
5. Persist across app restarts

**Methods Required**:
```dart
Future<List<int>> getFavoriteIds()
Future<void> addFavorite(int productId)
Future<void> removeFavorite(int productId)
Future<bool> isFavorite(int productId)
Future<void> clearFavorites()
```

**Files to Create/Modify**:
- Create: `lib/services/local_favorites_service.dart`
- Update: `lib/screens/product_detail_screen.dart`
- Update: `lib/screens/favorites_screen.dart`
- Update: `lib/home.dart` (favorite icons)

**ETA**: 45 minutes

---

### 4. Settings Screen Functionalities ⚙️
**Priority**: P1 - HIGH  
**Status**: 🟡 PARTIAL (UI exists, no persistence)  
**Current**: Settings UI without actual functionality  
**Needed**: Persist settings to local storage

**Settings to Implement**:

#### Notifications Settings
- [ ] Push Notifications (toggle)
- [ ] Email Notifications (toggle)
- [ ] SMS Notifications (toggle)
- [ ] Store in SharedPreferences: `settings_notifications`

#### Appearance Settings
- [ ] Dark Mode (toggle)
- [ ] Store in SharedPreferences: `settings_dark_mode`
- [ ] Apply theme across app (requires theme provider)

#### Preferences
- [ ] Language selection (dropdown)
  - Options: English, Spanish, French, German
  - Store in SharedPreferences: `settings_language`
- [ ] Currency selection (dropdown)
  - Options: USD, EUR, GBP, JPY
  - Store in SharedPreferences: `settings_currency`

#### Account Settings
- [ ] Change Password
- [ ] Email Preferences
- [ ] Privacy Settings
- [ ] Delete Account (with confirmation)

#### About Section
- [ ] Terms & Conditions (link/page)
- [ ] Privacy Policy (link/page)
- [ ] App Version display
- [ ] License information

**Files to Modify**:
- `lib/screens/settings_screen.dart` (add persistence)
- Create: `lib/services/settings_service.dart`
- Create: `lib/providers/theme_provider.dart` (for dark mode)

**ETA**: 1.5 hours

---

## 🟢 MEDIUM PRIORITY (Nice to Have)

### 5. Product Quantity Management 📦
**Priority**: P2 - MEDIUM  
**Status**: 🟡 NOT IMPLEMENTED  
**Question**: Should products have inventory quantity?

**Current State**: Each product is treated as single unit  
**Proposal**: Add quantity field to products

**Use Cases**:
- Seller has multiple units of same item
- Track available vs rented quantity
- Prevent overbooking
- Show "X units available" to users

**API Changes Needed**:
```json
{
  "quantity": 10,
  "available_quantity": 7,
  "rented_quantity": 3
}
```

**Implementation**:
1. Add quantity field to Product model
2. Update product creation/edit forms
3. Check available quantity before rental
4. Decrease quantity on rental approval
5. Increase quantity on rental completion

**Files to Modify**:
- `lib/models/product.dart`
- `lib/screens/add_product_screen.dart`
- `lib/services/rental_service.dart`
- API: `products` table schema

**ETA**: 2 hours (requires backend changes)

---

### 6. Rental Date Conflict Prevention 📅
**Priority**: P2 - MEDIUM  
**Status**: 🟡 NOT IMPLEMENTED  
**Current**: No date conflict checking

**Problem**: Two users can book same product for overlapping dates

**Solution**:
1. Fetch existing rentals for product before booking
2. Check if selected dates overlap with approved/active rentals
3. Show calendar with blocked dates
4. Prevent submission if conflict exists

**Implementation**:
```dart
Future<bool> checkDateAvailability(
  int productId, 
  DateTime startDate, 
  DateTime endDate
) async {
  final rentals = await getProductRentals(productId);
  // Check for overlaps
  return !hasDateConflict(rentals, startDate, endDate);
}
```

**Files to Modify**:
- `lib/services/rental_service.dart`
- `lib/screens/product_detail_screen.dart`

**ETA**: 1 hour

---

## 🔵 LOW PRIORITY (Future Enhancements)

### 7. Biometric Authentication 🔐
**Priority**: P3 - LOW  
**Status**: 🟡 NOT STARTED  
**Features**:
- Fingerprint login
- Face ID support
- Quick app unlock

**ETA**: 2 hours

---

### 8. Remember Me Checkbox 💾
**Priority**: P3 - LOW  
**Status**: 🟡 NOT STARTED  
**Current**: Auto-login always enabled  
**Proposal**: Add option to disable auto-login

**ETA**: 30 minutes

---

### 9. Session Timeout Warnings ⏰
**Priority**: P3 - LOW  
**Status**: 🟡 NOT STARTED  
**Features**:
- Show warning before session expires
- Allow session extension
- Auto-logout after inactivity

**ETA**: 1 hour

---

### 10. Multi-Device Session Management 📱
**Priority**: P3 - LOW  
**Status**: 🟡 NOT STARTED  
**Features**:
- View active sessions
- Logout from other devices
- Session activity log

**ETA**: 3 hours

---

## 📊 Implementation Summary

| Priority | Tasks | Estimated Time | Status |
|----------|-------|----------------|--------|
| P0 - Critical | 2 | 35 min | 🔴 In Progress |
| P1 - High | 2 | 2.25 hours | 🟡 Pending |
| P2 - Medium | 2 | 3 hours | 🟡 Pending |
| P3 - Low | 4 | 6.5 hours | ⚪ Future |

**Total Estimated Time**: ~12 hours

---

## 🎯 Immediate Action Items

1. ✅ Fix verification badge (5 min)
2. ✅ Implement local favorites (45 min)
3. ✅ Add settings persistence (1.5 hours)
4. ⏳ Debug rental API issues (30 min)
5. ⏳ Add rental date validation (1 hour)

---

## 📝 Notes & Decisions Needed

### Rental Business Logic Questions:
1. **Quantity Management**: Should we implement inventory tracking?
   - Current: Single unit per product
   - Proposed: Multiple units with availability tracking
   - Decision: Pending user feedback

2. **Date Conflicts**: How to handle overlapping bookings?
   - Option A: First-come-first-served (no conflicts allowed)
   - Option B: Multiple bookings with quantity limits
   - Decision: Implement Option A first (simpler)

3. **Rental Status Flow**:
   - Current: pending → approved → active → completed
   - Question: Should we add "reserved" status?
   - Decision: Keep current flow

4. **Payment Integration**: 
   - Current: No payment processing
   - Future: Integrate Stripe/PayPal
   - Priority: P4 (not urgent)

---

## 🔧 Technical Debt

1. **API Error Handling**: Improve error messages and logging
2. **Network Resilience**: Add retry logic for failed requests
3. **Caching Strategy**: Implement proper caching for products
4. **Code Documentation**: Add comprehensive comments
5. **Unit Tests**: Write tests for critical services
6. **Integration Tests**: Test API interactions

---

## 📈 Progress Tracking

**Completed Features**: ✅
- [x] Session management with token persistence
- [x] Verification status management
- [x] Image picker for products
- [x] Notifications screen
- [x] Product CRUD operations

**In Progress**: 🔄
- [ ] Rental API debugging
- [ ] Local favorites storage
- [ ] Settings persistence

**Planned**: 📋
- [ ] Quantity management
- [ ] Date conflict prevention
- [ ] Dark mode theme
- [ ] Biometric authentication

---

**Review Date**: December 11, 2025  
**Next Milestone**: Complete P0 and P1 tasks by EOW
