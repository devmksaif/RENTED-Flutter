# RENTED App Navigation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      App Entry Point                         │
│                      main.dart                               │
│                      initialRoute: /login                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │  LoginScreen   │
        │  /login        │
        └───┬─────────┬──┘
            │         │
    Success │         │ Don't have account?
            │         └──────────┐
            ▼                    ▼
    ┌──────────────┐     ┌──────────────┐
    │    Home      │     │RegisterScreen│
    │MainNavigation│◄────│  /register   │
    │   /home      │     └──────────────┘
    └──────┬───────┘             │
           │                     │ Success
           │                     └─────────┘
           │
┌──────────┴───────────────────────────────────────────┐
│          MainNavigation (Bottom Nav Bar)             │
│  ┌─────────┬─────────┬─────────────┬──────────────┐ │
│  │  Home   │Favorites│ My Products │   Profile    │ │
│  │   🏠    │   ❤️    │     📦      │     👤       │ │
│  └────┬────┴────┬────┴──────┬──────┴──────┬───────┘ │
└───────┼─────────┼───────────┼─────────────┼─────────┘
        │         │           │             │
        ▼         ▼           ▼             ▼
┌──────────────────────────────────────────────────────┐
│                                                       │
│  HomeScreen          FavoritesScreen                 │
│  • Product Grid      • Saved Products                │
│  • Categories        • Empty State                   │
│  • Search                                            │
│  • Filter            MyProductsScreen                │
│                      • User's Listings               │
│  ProductDetailScreen • Edit/Delete                   │
│  • Images            • Toggle Availability           │
│  • Rent Button       • Add New                       │
│  • Buy Button                                        │
│  • Owner Info        ProfileScreen                   │
│                      • User Info                     │
│  RentalDialog        • Verification Badge            │
│  • Date Picker       • Menu Items                    │
│  • Price Calc        • Logout                        │
│                                                       │
└───────────────────────┬───────────────────────────────┘
                        │
        ┌───────────────┴──────────────────┐
        │                                   │
        ▼                                   ▼
┌──────────────────┐            ┌──────────────────────┐
│ AddProductScreen │            │ Navigates to:        │
│ • Title          │            │ • /my-products       │
│ • Category       │            │ • /my-rentals        │
│ • Description    │            │ • /my-purchases      │
│ • Pricing        │            │ • /favorites         │
│ • For Sale?      │            │ • /verification      │
└──────────────────┘            └──────────────────────┘
        │                                   │
        │                                   ▼
        │                       ┌──────────────────────┐
        │                       │  MyRentalsScreen     │
        │                       │  • Rental History    │
        │                       │  • Status Badges     │
        │                       │  • Dates & Pricing   │
        │                       └──────────────────────┘
        │                                   │
        │                                   ▼
        │                       ┌──────────────────────┐
        │                       │ MyPurchasesScreen    │
        │                       │ • Purchase History   │
        │                       │ • Status Tracking    │
        │                       │ • Transaction Info   │
        │                       └──────────────────────┘
        │                                   │
        │                                   ▼
        │                       ┌──────────────────────┐
        └──────────────────────►│ VerificationScreen   │
                                │ • Upload Documents   │
                                │ • ID Verification    │
                                │ • Status Tracking    │
                                └──────────────────────┘
```

## Screen Relationships

### Authentication Flow
```
LoginScreen ──────► MainNavigation
     │                    ▲
     │                    │
     └─► RegisterScreen ──┘
```

### Main Navigation Tabs
```
Tab 0: HomeScreen
Tab 1: FavoritesScreen
Tab 2: MyProductsScreen
Tab 3: ProfileScreen
```

### Deep Navigation Paths
```
HomeScreen
  └─► ProductDetailScreen
       ├─► Rent (RentalDialog)
       └─► Buy (Purchase Confirmation)

MyProductsScreen
  ├─► AddProductScreen
  └─► ProductDetailScreen

ProfileScreen
  ├─► MyProductsScreen
  ├─► MyRentalsScreen
  ├─► MyPurchasesScreen
  ├─► FavoritesScreen
  ├─► VerificationScreen
  └─► Logout → LoginScreen
```

## Route Definitions

| Route | Screen | Authentication Required |
|-------|--------|------------------------|
| `/login` | LoginScreen | No |
| `/register` | RegisterScreen | No |
| `/home` | MainNavigation | Yes |
| `/profile` | ProfileScreen | Yes |
| `/product-detail/:id` | ProductDetailScreen | Optional |
| `/add-product` | AddProductScreen | Yes (Verified) |
| `/my-products` | MyProductsScreen | Yes |
| `/my-rentals` | MyRentalsScreen | Yes |
| `/my-purchases` | MyPurchasesScreen | Yes |
| `/verification` | VerificationScreen | Yes |
| `/favorites` | FavoritesScreen | Yes |

## Navigation Methods Used

### Named Routes
```dart
Navigator.pushNamed(context, '/route-name');
Navigator.pushReplacementNamed(context, '/route-name');
```

### Routes with Arguments
```dart
Navigator.pushNamed(
  context,
  '/product-detail',
  arguments: productId,
);
```

### Back Navigation
```dart
Navigator.pop(context);
Navigator.pop(context, result); // With result
```

## User Journey Examples

### New User Registration
```
1. Open App → LoginScreen
2. Tap "Create one" → RegisterScreen
3. Fill form → Submit
4. Auto-navigate → MainNavigation (Home)
```

### Renting a Product
```
1. Browse → HomeScreen
2. Tap product → ProductDetailScreen
3. Tap "Rent" → RentalDialog
4. Select dates → Confirm
5. Success toast → Stay on detail screen
6. View rental → MyRentalsScreen
```

### Listing a Product
```
1. Profile → ProfileScreen
2. Tap "My Products" → MyProductsScreen
3. Tap "Add Product" → AddProductScreen
4. Fill form → Submit
5. Success → Back to MyProductsScreen
```

### Verification Flow
```
1. Profile → ProfileScreen
2. Tap "Verification" → VerificationScreen
3. Upload documents → Submit
4. Wait for approval → Check status badge
```

## Bottom Navigation State

The `MainNavigation` widget maintains the selected tab index and displays the corresponding screen:

- **Index 0**: HomeScreen
- **Index 1**: FavoritesScreen
- **Index 2**: MyProductsScreen
- **Index 3**: ProfileScreen

State is preserved when switching between tabs.
