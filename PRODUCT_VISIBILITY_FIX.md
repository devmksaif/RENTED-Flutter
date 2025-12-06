# Product Visibility Issue - Fix Guide

## Problem
Only 34 products showing when there are 35 products in the database.

## Root Cause

The backend filters products with **two conditions**:
1. `is_available = true` 
2. `verification_status = 'approved'`

**Note**: You updated `pickup_available = true`, but that's a different field! The field that matters is `is_available`.

## Solution

### Step 1: Check which product is missing

Run this SQL query to find products that are NOT showing:

```sql
-- Find products that are NOT approved or NOT available
SELECT id, title, is_available, verification_status, pickup_available
FROM products
WHERE is_available = false 
   OR verification_status != 'approved'
   OR verification_status IS NULL;
```

### Step 2: Fix the missing product

Update the product to be both available AND approved:

```sql
-- Replace PRODUCT_ID with the actual ID from Step 1
UPDATE products 
SET 
    is_available = true,
    verification_status = 'approved'
WHERE id = PRODUCT_ID;
```

### Step 3: Clear Laravel Cache

The products are cached for 10 minutes. Clear the cache:

```bash
cd Laravel/rented-api
php artisan cache:clear
```

Or clear specific cache keys:

```bash
php artisan tinker
>>> Cache::forget('products.paginated.page.1.per_page.20');
>>> Cache::forget('products.all');
```

### Step 4: Verify

Check the API response:

```bash
curl http://167.86.87.72:8000/api/v1/products?page=1&per_page=35
```

Should return 35 products now.

---

## Quick Fix (All Products)

If you want to make ALL products visible:

```sql
-- Make all products available and approved
UPDATE products 
SET 
    is_available = true,
    verification_status = 'approved'
WHERE is_available = false 
   OR verification_status != 'approved'
   OR verification_status IS NULL;
```

Then clear cache:
```bash
cd Laravel/rented-api
php artisan cache:clear
```

---

## Important Notes

1. **`pickup_available`** ≠ **`is_available`**
   - `pickup_available`: Whether product can be picked up (delivery option)
   - `is_available`: Whether product is available for rent/sale (visibility)

2. **Cache**: Products are cached for 10 minutes. After updating database, clear cache.

3. **Verification Status**: Products must be `'approved'` to show in public listings. Other statuses:
   - `'pending'` - Waiting for admin approval
   - `'rejected'` - Rejected by admin
   - `NULL` - Not set (won't show)

---

## Backend Filtering Logic

**File**: `Laravel/rented-api/app/Repositories/ProductRepository.php`

```php
public function getAllPaginated(int $perPage = 15): LengthAwarePaginator
{
    return Product::with(['category', 'user'])
        ->where('is_available', true)           // ✅ Must be true
        ->where('verification_status', 'approved') // ✅ Must be 'approved'
        ->latest()
        ->paginate($perPage);
}
```

Both conditions must be met for a product to appear in the list!
