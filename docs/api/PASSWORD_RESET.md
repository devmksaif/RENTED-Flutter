# Password Reset API

## Overview

This document covers password reset functionality that allows users to reset their forgotten passwords via email.

---

## Password Reset Endpoints

### Request Password Reset

Send password reset email to user.

**Endpoint**: `POST /api/v1/forgot-password`

**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john@example.com"
}
```

**Validation Rules**:

- `email`: required, valid email format, must exist in database

**Request Example**:

```bash
curl -X POST "http://localhost:8000/api/v1/forgot-password" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com"
  }'
```

**Response** (200 OK):

```json
{
  "message": "Password reset link sent to your email"
}
```

**Response Fields**:

- `message` (string): Success message confirming email was sent

**Error Responses**:

*422 Unprocessable Entity* - Validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email field is required.",
      "The email must be a valid email address.",
      "We can't find a user with that email address."
    ]
  }
}
```

**Notes**:

- **Security**: The API always returns success message even if email doesn't exist (prevents email enumeration)
- **Reset Link Expiry**: Reset link expires after 60 minutes
- **Email Delivery**: Check spam folder if email not received
- **Rate Limiting**: This endpoint is rate-limited to prevent abuse

**Flutter Implementation Example**:

```dart
Future<bool> requestPasswordReset(String email) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Show success message to user
      return true;
    } else {
      final error = json.decode(response.body);
      // Handle validation errors
      return false;
    }
  } catch (e) {
    // Handle network error
    return false;
  }
}
```

**Usage in Widget**:

```dart
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _requestReset() async {
    if (!_emailController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await requestPasswordReset(_emailController.text);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to your email'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestReset,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Reset Password

Reset user password using token from email.

**Endpoint**: `POST /api/v1/reset-password`

**Authentication**: Not required

**Request Body**:

```json
{
  "email": "john@example.com",
  "token": "reset-token-from-email",
  "password": "NewSecurePassword123!",
  "password_confirmation": "NewSecurePassword123!"
}
```

**Validation Rules**:

- `email`: required, valid email format
- `token`: required, valid reset token (from email link)
- `password`: required, string, min:8 characters, confirmed
- `password_confirmation`: required, must match password

**Request Example**:

```bash
curl -X POST "http://localhost:8000/api/v1/reset-password" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "token": "abc123def456",
    "password": "NewSecurePassword123!",
    "password_confirmation": "NewSecurePassword123!"
  }'
```

**Response** (200 OK):

```json
{
  "message": "Password has been reset successfully"
}
```

**Response Fields**:

- `message` (string): Success message confirming password was reset

**Error Responses**:

*422 Unprocessable Entity* - Invalid token or validation failed

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "We can't find a user with that email address."
    ],
    "token": [
      "This password reset token is invalid."
    ],
    "password": [
      "The password must be at least 8 characters.",
      "The password confirmation does not match."
    ]
  }
}
```

**Notes**:

- **Token Expiry**: Reset tokens expire after 60 minutes
- **One-Time Use**: Tokens are invalidated after successful password reset
- **Password Requirements**: Must be at least 8 characters
- **Auto-Login**: User is NOT automatically logged in after password reset (must login separately)

**Flutter Implementation Example**:

```dart
Future<bool> resetPassword({
  required String email,
  required String token,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reset-password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      // Handle validation errors
      throw Exception(error['message'] ?? 'Password reset failed');
    }
  } catch (e) {
    rethrow;
  }
}
```

**Usage in Widget**:

```dart
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  ResetPasswordScreen({required this.email, required this.token});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await resetPassword(
        email: widget.email,
        token: widget.token,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Password Reset Flow

```
1. User requests password reset: POST /forgot-password
   ↓
2. Server sends email with reset link containing token
   ↓
3. User clicks link in email (expires in 60 minutes)
   ↓
4. App extracts email and token from URL
   ↓
5. User enters new password
   ↓
6. App submits: POST /reset-password with email, token, password
   ↓
7. Server validates and updates password
   ↓
8. User logs in with new password
```

---

## Security Considerations

1. **Token Expiry**: Reset tokens expire after 60 minutes
2. **One-Time Use**: Tokens are invalidated after use
3. **Email Enumeration**: API doesn't reveal if email exists
4. **Rate Limiting**: Endpoints are rate-limited to prevent abuse
5. **HTTPS**: Always use HTTPS in production
6. **Password Strength**: Enforce minimum 8 characters

---

## Best Practices

1. **User Experience**: 
   - Show clear success/error messages
   - Provide instructions on checking spam folder
   - Indicate token expiry time

2. **Error Handling**:
   - Handle invalid/expired tokens gracefully
   - Show field-specific validation errors
   - Provide retry options

3. **Security**:
   - Never log or expose reset tokens
   - Validate tokens server-side
   - Use secure token generation

4. **Email Handling**:
   - Parse reset URL correctly
   - Handle deep linking properly
   - Extract email and token from URL parameters

---

## Common Issues

### Issue: "This password reset token is invalid"

**Possible Causes**:
- Token has expired (60 minutes)
- Token has already been used
- Token is malformed or incorrect

**Solution**: Request a new password reset link

### Issue: Email not received

**Possible Causes**:
- Email in spam folder
- Incorrect email address
- Email delivery delay

**Solution**: Check spam folder, verify email address, wait a few minutes

### Issue: Token expired

**Solution**: Request a new password reset link

---

## Testing

### Test Password Reset Flow

1. Call `POST /forgot-password` with valid email
2. Check email for reset link
3. Extract token from email link
4. Call `POST /reset-password` with email, token, and new password
5. Verify password was changed
6. Attempt login with new password

---

## Related Endpoints

- [Authentication](./AUTHENTICATION.md) - Login and registration
- [User Profile](./USER_PROFILE.md) - Change password while logged in

