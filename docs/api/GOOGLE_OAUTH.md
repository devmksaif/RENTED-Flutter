# Google OAuth API

## Overview

This document covers Google OAuth 2.0 authentication endpoints that allow users to sign in using their Google accounts.

---

## Google OAuth Endpoints

### Redirect to Google Authentication

Initiate Google OAuth authentication flow.

**Endpoint**: `GET /api/v1/auth/google`

**Authentication**: Not required

**Request Example**:

```bash
curl -X GET "http://localhost:8000/api/v1/auth/google" \
  -H "Accept: application/json"
```

**Response** (200 OK):

```json
{
  "url": "https://accounts.google.com/o/oauth2/auth?client_id=...&redirect_uri=...&response_type=code&scope=openid%20email%20profile"
}
```

**Response Fields**:

- `url` (string): Google OAuth authorization URL that the client should redirect the user to

**Description**: 

The client should redirect the user to the returned URL for Google authentication. After the user authenticates with Google, they will be redirected back to your application with an authorization code.

**Flutter Implementation Example**:

```dart
Future<void> initiateGoogleAuth() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/google'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final authUrl = data['url'];
      
      // Open URL in browser or WebView
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
      }
    }
  } catch (e) {
    // Handle error
  }
}
```

**Web Implementation Example**:

```javascript
async function initiateGoogleAuth() {
  try {
    const response = await fetch('http://localhost:8000/api/v1/auth/google', {
      headers: { 'Accept': 'application/json' },
    });
    const data = await response.json();
    window.location.href = data.url; // Redirect to Google
  } catch (error) {
    console.error('Failed to initiate Google auth:', error);
  }
}
```

---

### Handle Google OAuth Callback

Process Google OAuth callback and authenticate user.

**Endpoint**: `GET /api/v1/auth/google/callback`

**Authentication**: Not required

**Query Parameters**: 

Automatically provided by Google after user authentication:
- `code` (string, required): Authorization code from Google
- `state` (string, optional): State parameter for CSRF protection

**Request Example**:

```bash
curl -X GET "http://localhost:8000/api/v1/auth/google/callback?code=4/0AeanS0X...&state=xyz123" \
  -H "Accept: application/json"
```

**Response** (200 OK):

```json
{
  "message": "Successfully authenticated with Google",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@gmail.com",
    "avatar_url": "https://lh3.googleusercontent.com/a/default-user=s96-c",
    "verification_status": "unverified",
    "google_id": "1234567890",
    "created_at": "2025-12-03T14:30:45.000000Z",
    "updated_at": "2025-12-03T14:30:45.000000Z"
  },
  "token": "2|AbCdEfGhIjKlMnOpQrStUvWxYz"
}
```

**Response Fields**:

- `message` (string): Success message
- `user` (object): Authenticated user object
  - `id` (integer): User ID
  - `name` (string): User's full name from Google
  - `email` (string): User's email address
  - `avatar_url` (string): User's Google profile picture URL
  - `verification_status` (string): User verification status (always "unverified" for new Google users)
  - `google_id` (string): Google user ID
  - `created_at` (string): Account creation timestamp
  - `updated_at` (string): Last update timestamp
- `token` (string): Laravel Sanctum authentication token

**Error Responses**:

*500 Internal Server Error* - OAuth authentication failed

```json
{
  "message": "OAuth authentication failed. Please try again."
}
```

**Notes**:

- **New Users**: Creates a new user account if the email doesn't exist
- **Existing Users**: Links Google account to existing user if email matches
- **Token Storage**: Updates Google tokens for future use
- **Verification**: New Google users start with `verification_status: "unverified"` and must complete verification to create products
- **Avatar**: Automatically uses Google profile picture as avatar URL

**Flutter Implementation Example**:

```dart
Future<AuthResponse?> handleGoogleCallback(String code, String? state) async {
  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/google/callback')
        .replace(queryParameters: {
      'code': code,
      if (state != null) 'state': state,
    });

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      
      // Save token and user
      await storageService.saveToken(authResponse.token);
      await storageService.saveUser(authResponse.user);
      
      return authResponse;
    } else {
      throw Exception('Google authentication failed');
    }
  } catch (e) {
    // Handle error
    return null;
  }
}
```

**Complete Flutter Flow Example**:

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';

class GoogleAuthService {
  Future<void> signInWithGoogle() async {
    // Step 1: Get Google auth URL
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/google'),
      headers: {'Accept': 'application/json'},
    );
    
    final authUrl = json.decode(response.body)['url'];
    
    // Step 2: Open browser for Google login
    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl));
    }
    
    // Step 3: Listen for callback URL
    uriLinkStream.listen((Uri uri) {
      if (uri.scheme == 'yourapp' && uri.host == 'oauth') {
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        
        if (code != null) {
          handleGoogleCallback(code, state);
        }
      }
    });
  }
}
```

---

## OAuth Flow Diagram

```
1. Client requests: GET /auth/google
   ↓
2. Server returns: { "url": "https://accounts.google.com/..." }
   ↓
3. Client redirects user to Google URL
   ↓
4. User authenticates with Google
   ↓
5. Google redirects to: /auth/google/callback?code=...&state=...
   ↓
6. Server exchanges code for tokens and creates/updates user
   ↓
7. Server returns: { "user": {...}, "token": "..." }
   ↓
8. Client saves token and user data
```

---

## Security Considerations

1. **State Parameter**: Use state parameter for CSRF protection
2. **Token Storage**: Store authentication tokens securely (use Flutter Secure Storage)
3. **HTTPS**: Always use HTTPS in production
4. **Token Expiration**: Handle token expiration gracefully
5. **Error Handling**: Never expose sensitive error details to users

---

## Best Practices

1. **User Experience**: Show loading indicators during OAuth flow
2. **Error Handling**: Provide clear error messages if authentication fails
3. **Token Management**: Implement token refresh if needed
4. **Account Linking**: Handle cases where Google email matches existing account
5. **Verification**: Prompt new Google users to complete verification

---

## Common Issues

### Issue: "OAuth authentication failed"

**Possible Causes**:
- Invalid authorization code
- Expired authorization code
- Google OAuth configuration mismatch
- Network connectivity issues

**Solution**: Retry the authentication flow

### Issue: "Email already exists"

**Behavior**: If a user with the same email already exists, the Google account will be linked to the existing account.

---

## Testing

### Test OAuth Flow

1. Call `GET /auth/google` to get authorization URL
2. Open the URL in a browser
3. Complete Google authentication
4. Capture the callback URL with code parameter
5. Call `GET /auth/google/callback` with the code
6. Verify user and token are returned

---

## Related Endpoints

- [Authentication](./AUTHENTICATION.md) - Standard email/password authentication
- [User Profile](./USER_PROFILE.md) - User profile management
- [User Verification](./USER_PROFILE.md#user-verification-endpoints) - Account verification

