# RENTED App Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                      UI Layer                             │  │
│  │  ┌────────────┐  ┌──────────────┐  ┌─────────────────┐  │  │
│  │  │  Login     │  │  Register    │  │  Home (Future)  │  │  │
│  │  │  Screen    │  │  Screen      │  │  Screen         │  │  │
│  │  └────────────┘  └──────────────┘  └─────────────────┘  │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                            │                                     │
│                            │ Uses                                │
│                            ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Service Layer                           │  │
│  │  ┌────────────────┐  ┌──────────────────────────────┐   │  │
│  │  │  AuthService   │  │  ProductService (Future)     │   │  │
│  │  │  - register()  │  │  - getProducts()             │   │  │
│  │  │  - login()     │  │  - createProduct()           │   │  │
│  │  │  - logout()    │  │  - updateProduct()           │   │  │
│  │  │  - getUser()   │  │  - deleteProduct()           │   │  │
│  │  └────────────────┘  └──────────────────────────────┘   │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                            │                                     │
│                            │ Uses                                │
│                            ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Storage Layer                           │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  StorageService                                      │ │  │
│  │  │  - saveToken() / getToken()                         │ │  │
│  │  │  - saveUser() / getUser()                           │ │  │
│  │  │  - clearAll()                                        │ │  │
│  │  │                                                       │ │  │
│  │  │  Uses: SharedPreferences                             │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Model Layer                             │  │
│  │  ┌──────────┐ ┌────────┐ ┌─────────┐ ┌──────────────┐  │  │
│  │  │   User   │ │ Product│ │Category │ │  AuthResponse│  │  │
│  │  └──────────┘ └────────┘ └─────────┘ └──────────────┘  │  │
│  │  ┌──────────┐                                            │  │
│  │  │ ApiError │                                            │  │
│  │  └──────────┘                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Config Layer                            │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  ApiConfig                                           │ │  │
│  │  │  - baseUrl                                           │ │  │
│  │  │  - endpoints                                         │ │  │
│  │  │  - headers                                           │ │  │
│  │  │  - timeouts                                          │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ HTTP/HTTPS
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Backend API                                 │
│         (Laravel - Railway Production)                           │
├─────────────────────────────────────────────────────────────────┤
│  Base URL: https://rented-backend-api-production.up.railway.app │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Endpoints:                                              │   │
│  │  • POST /api/v1/register                                │   │
│  │  • POST /api/v1/login                                   │   │
│  │  • POST /api/v1/logout                                  │   │
│  │  • GET  /api/v1/user                                    │   │
│  │  • PUT  /api/v1/user/profile                           │   │
│  │  • GET  /api/v1/products                               │   │
│  │  • POST /api/v1/products                               │   │
│  │  • GET  /api/v1/categories                             │   │
│  │  • ... (and more)                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow - Login Example

```
┌─────────────┐
│ User enters │
│ credentials │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ LoginScreen (UI)                            │
│ • Validates form                            │
│ • Shows loading indicator                   │
└──────┬──────────────────────────────────────┘
       │ Calls login()
       ▼
┌─────────────────────────────────────────────┐
│ AuthService (Service Layer)                 │
│ • Builds request body                       │
│ • Adds headers from ApiConfig              │
│ • Makes HTTP POST request                   │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ Backend API                                  │
│ • Validates credentials                      │
│ • Generates token                            │
│ • Returns user data + token                  │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ AuthService (Service Layer)                 │
│ • Parses response JSON                      │
│ • Creates AuthResponse model                │
│ • Calls StorageService to save token        │
│ • Returns AuthResponse to UI                │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ StorageService (Storage Layer)              │
│ • Saves token to SharedPreferences          │
│ • Saves user data to SharedPreferences      │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ LoginScreen (UI)                            │
│ • Hides loading indicator                   │
│ • Shows success toast                       │
│ • Navigates to home screen                  │
└─────────────────────────────────────────────┘
```

## Error Flow

```
┌─────────────┐
│   API Call  │
└──────┬──────┘
       │
       ▼
   ╔═══════╗
   ║Success?║
   ╚═══╤═══╝
       │
   ┌───┴───┐
   │       │
  Yes     No
   │       │
   ▼       ▼
┌─────┐ ┌────────────────┐
│Parse│ │ Throw ApiError │
│Model│ └────────┬───────┘
└──┬──┘          │
   │             ▼
   │     ┌────────────────┐
   │     │ UI Catches     │
   │     │ ApiError       │
   │     └────────┬───────┘
   │              │
   │              ▼
   │     ┌────────────────────┐
   │     │ Check statusCode:  │
   │     │ • 401 → Login      │
   │     │ • 422 → Validation │
   │     │ • 500 → Server     │
   │     │ • 0   → Network    │
   │     └────────┬───────────┘
   │              │
   │              ▼
   │     ┌────────────────┐
   │     │ Show error     │
   │     │ toast/dialog   │
   │     └────────────────┘
   │
   ▼
┌──────────────┐
│ Return model │
│ to UI        │
└──────────────┘
```

## Authentication State Management

```
                  App Start
                      │
                      ▼
              ┌───────────────┐
              │ Check Token   │
              │ in Storage    │
              └───────┬───────┘
                      │
              ┌───────┴────────┐
              │                │
           Token            No Token
           Exists              │
              │                │
              ▼                ▼
      ┌──────────────┐  ┌─────────────┐
      │ Navigate to  │  │ Navigate to │
      │ Home Screen  │  │ Login       │
      └──────────────┘  └─────────────┘
              │                │
              │                ▼
              │         ┌──────────────┐
              │         │ User Logs In │
              │         └──────┬───────┘
              │                │
              │                ▼
              │         ┌──────────────┐
              │         │ Save Token   │
              │         │ in Storage   │
              │         └──────┬───────┘
              │                │
              └────────────────┤
                               │
                               ▼
                        ┌──────────────┐
                        │ Authenticated│
                        │ Session      │
                        └──────┬───────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
            ┌──────────────┐      ┌─────────────┐
            │ Make API     │      │ User Logs   │
            │ Calls with   │      │ Out         │
            │ Token        │      └──────┬──────┘
            └──────────────┘             │
                                         ▼
                                  ┌──────────────┐
                                  │ Clear Token  │
                                  │ from Storage │
                                  └──────┬───────┘
                                         │
                                         ▼
                                  ┌──────────────┐
                                  │ Navigate to  │
                                  │ Login        │
                                  └──────────────┘
```

## File Organization

```
lib/
│
├── config/                    # Configuration files
│   └── api_config.dart        # API endpoints, URLs, headers
│
├── models/                    # Data models
│   ├── user.dart             # User model
│   ├── auth_response.dart    # Auth response wrapper
│   ├── product.dart          # Product model
│   ├── category.dart         # Category model
│   └── api_error.dart        # Error handling model
│
├── services/                  # Business logic & API calls
│   ├── auth_service.dart     # Authentication operations
│   ├── product_service.dart  # Product operations
│   └── storage_service.dart  # Local storage operations
│
├── screens/                   # UI screens (organized)
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   └── products/
│       ├── product_list_screen.dart
│       └── product_detail_screen.dart
│
└── main.dart                  # App entry point
```

## Layer Responsibilities

### 1. UI Layer (Screens)
- **Responsibility**: Display data, handle user interactions
- **What it does**:
  - Render widgets
  - Handle user input
  - Show loading states
  - Display errors
  - Navigate between screens
- **What it does NOT do**:
  - Make HTTP calls directly
  - Parse JSON
  - Store data
  - Business logic

### 2. Service Layer
- **Responsibility**: Business logic, API communication
- **What it does**:
  - Make HTTP requests
  - Parse responses
  - Handle API errors
  - Transform data for UI
  - Coordinate with storage
- **What it does NOT do**:
  - Render UI
  - Navigate screens
  - Directly access SharedPreferences

### 3. Storage Layer
- **Responsibility**: Persist data locally
- **What it does**:
  - Save/retrieve tokens
  - Save/retrieve user data
  - Clear storage
  - Manage SharedPreferences
- **What it does NOT do**:
  - Make API calls
  - Render UI
  - Business logic

### 4. Model Layer
- **Responsibility**: Data structure definitions
- **What it does**:
  - Define data classes
  - JSON serialization
  - Data validation
  - Type safety
- **What it does NOT do**:
  - Make API calls
  - Store data
  - Render UI

### 5. Config Layer
- **Responsibility**: App-wide configuration
- **What it does**:
  - Define constants
  - API endpoints
  - Environment settings
  - Common headers
- **What it does NOT do**:
  - Make API calls
  - Store data
  - Business logic

## Benefits of This Architecture

1. **Separation of Concerns** - Each layer has a single responsibility
2. **Testability** - Services can be mocked easily
3. **Maintainability** - Changes in one layer don't affect others
4. **Scalability** - Easy to add new features
5. **Reusability** - Services can be used across multiple screens
6. **Type Safety** - Models provide compile-time safety
7. **Clean Code** - Easy to understand and navigate

---

**This architecture follows Flutter best practices and industry standards.**
