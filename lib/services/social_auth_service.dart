import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/api_error.dart';
import '../models/auth_response.dart';
import '../models/user.dart' as app_user;
import '../utils/logger.dart';
import 'storage_service.dart';

class SocialAuthService {
  final StorageService _storageService = StorageService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google using Firebase Auth
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        throw ApiError(
          message: 'Firebase is not initialized. Please configure Firebase first.',
          statusCode: 500,
        );
      }

      AppLogger.i('🔐 Starting Google Sign-In with Firebase');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        throw ApiError(
          message: 'Google sign-in was cancelled',
          statusCode: 400,
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user; // Firebase User type

      if (firebaseUser == null) {
        throw ApiError(
          message: 'Failed to authenticate with Google',
          statusCode: 401,
        );
      }

      AppLogger.i('✅ Firebase Google Sign-In successful: ${firebaseUser.email}');

      // Get the Firebase ID token
      final String? idToken = await firebaseUser.getIdToken();

      if (idToken == null) {
        throw ApiError(
          message: 'Failed to get authentication token',
          statusCode: 401,
        );
      }

      // Send the Firebase ID token to your backend to create/login user
      final authResponse = await _authenticateWithBackend(
        idToken: idToken,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
      );

      return authResponse;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.e('Firebase Auth Error', e, stackTrace);
      throw ApiError(
        message: _getFirebaseErrorMessage(e.code),
        statusCode: 401,
      );
    } on ApiError catch (e) {
      AppLogger.apiError('signInWithGoogle', e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('signInWithGoogle', e);
      AppLogger.e('Failed to sign in with Google', e, stackTrace);
      throw ApiError(
        message: 'Failed to sign in with Google: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Authenticate with backend using Firebase ID token
  Future<AuthResponse> _authenticateWithBackend({
    required String idToken,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final url = ApiConfig.googleFirebaseAuth;
    
    try {
      AppLogger.apiRequest('POST', url);
      AppLogger.i('🔐 Authenticating with backend using Firebase token');

      final body = {
        'id_token': idToken,
        'email': email,
        'name': name,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response - backend returns user as an object, not nested
        final userData = responseData['user'] as Map<String, dynamic>;
        // Add required fields with defaults if missing
        final userJson = {
          'id': userData['id'],
          'name': userData['name'],
          'email': userData['email'],
          'avatar_url': userData['avatar_url'] ?? userData['avatar'],
          'verification_status': userData['verification_status'] ?? 'pending',
          'verified_at': null,
          'email_verified_at': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        final user = app_user.User.fromJson(userJson); // Our app User model
        final token = responseData['token'] as String;

        // Save token and user BEFORE returning
        await _storageService.saveToken(token);
        await _storageService.saveUser(user);

        AppLogger.i('✅ Backend authentication successful: ${user.name}');
        
        return AuthResponse(
          message: responseData['message'] ?? 'Login successful',
          user: user,
          token: token,
        );
      } else {
        // Log full error details for debugging
        AppLogger.e('Backend authentication failed', 
          Exception('Status: ${response.statusCode}, Body: ${response.body}'),
          StackTrace.current);
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('_authenticateWithBackend', e);
      AppLogger.e('Failed to authenticate with backend', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get Firebase error message from error code
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred during authentication.';
    }
  }

  /// Get Google OAuth redirect URL (Legacy method - kept for backward compatibility)
  Future<String> getGoogleAuthUrl() async {
    final url = ApiConfig.googleAuth;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('🔐 Getting Google OAuth URL');

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Google OAuth URL retrieved');
        return responseData['url'] ?? '';
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getGoogleAuthUrl', e);
      AppLogger.e('Failed to get Google OAuth URL', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Handle Google OAuth callback
  /// Note: This is typically handled by the backend redirect, but this method
  /// can be used if the callback URL returns JSON directly
  Future<Map<String, dynamic>> handleGoogleCallback({
    required String code,
    String? state,
  }) async {
    final uri = Uri.parse(ApiConfig.googleAuthCallback).replace(
      queryParameters: {
        'code': code,
        if (state != null) 'state': state,
      },
    );
    final url = uri.toString();
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('🔐 Handling Google OAuth callback');

      final response = await http
          .get(
            uri,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        // Save token if provided
        if (responseData['token'] != null) {
          await _storageService.saveToken(responseData['token']);
        }

        AppLogger.i('✅ Google OAuth authentication successful');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Successfully authenticated with Google',
          'user': responseData['user'],
          'token': responseData['token'],
        };
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('handleGoogleCallback', e);
      AppLogger.e('Failed to handle Google OAuth callback', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}
