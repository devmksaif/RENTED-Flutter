import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/messaging_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class ConversationService {
  final StorageService _storageService = StorageService();
  
  // Set to true when microservice is deployed
  static const bool useMicroservice = false;
  
  String get _baseUrl => useMicroservice 
      ? MessagingConfig.messagingBaseUrl 
      : ApiConfig.baseUrl;
  
  String get _conversationsEndpoint => useMicroservice
      ? MessagingConfig.conversations
      : ApiConfig.conversations;
  
  String get _unreadCountEndpoint => useMicroservice
      ? MessagingConfig.conversationsUnreadCount
      : ApiConfig.conversationsUnreadCount;

  /// Get all conversations for the authenticated user
  Future<List<Map<String, dynamic>>> getConversations() async {
    final url = _conversationsEndpoint;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('💬 Fetching conversations');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final conversations = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${conversations.length} conversations');
        return conversations;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getConversations', e);
      AppLogger.e('Failed to fetch conversations', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get a specific conversation by ID
  Future<Map<String, dynamic>> getConversation(int conversationId) async {
    final url = '$_conversationsEndpoint/$conversationId';
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('💬 Fetching conversation $conversationId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        AppLogger.i('✅ Retrieved conversation $conversationId');
        return responseData['data'];
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getConversation', e);
      AppLogger.e('Failed to fetch conversation', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
      int conversationId) async {
    final endpoint = useMicroservice
        ? '$_conversationsEndpoint/$conversationId/messages'
        : '${ApiConfig.conversations}/$conversationId/messages';
    final url = endpoint;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('💬 Fetching messages for conversation $conversationId');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final messages = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        AppLogger.i('✅ Retrieved ${messages.length} messages');
        return messages;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getConversationMessages', e);
      AppLogger.e('Failed to fetch messages', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    final endpoint = useMicroservice
        ? '$_conversationsEndpoint/$conversationId/read'
        : '${ApiConfig.conversations}/$conversationId/read';
    final url = endpoint;
    try {
      AppLogger.apiRequest('POST', url);
      AppLogger.i('💬 Marking conversation $conversationId as read');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode != 200) {
        AppLogger.apiError(url, response.statusCode, responseData?['message'] ?? 'Unknown error', errors: responseData?['errors']);
        throw ApiError.fromJson(responseData ?? {}, response.statusCode);
      }
      AppLogger.i('✅ Conversation marked as read');
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('markConversationAsRead', e);
      AppLogger.e('Failed to mark conversation as read', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    final url = _unreadCountEndpoint;
    try {
      AppLogger.apiRequest('GET', url);
      AppLogger.i('💬 Fetching unread count');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 200) {
        final count = responseData['unread_count'] ?? 0;
        AppLogger.i('✅ Unread count: $count');
        return count;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('getUnreadCount', e);
      AppLogger.e('Failed to fetch unread count', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

