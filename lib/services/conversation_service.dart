import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/messaging_config.dart';
import '../models/api_error.dart';
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
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(_conversationsEndpoint),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get a specific conversation by ID
  Future<Map<String, dynamic>> getConversation(int conversationId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse('$_conversationsEndpoint/$conversationId'),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['data'];
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getConversationMessages(
      int conversationId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final endpoint = useMicroservice
          ? '$_conversationsEndpoint/$conversationId/messages'
          : '${ApiConfig.conversations}/$conversationId/messages';
      
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final endpoint = useMicroservice
          ? '$_conversationsEndpoint/$conversationId/read'
          : '${ApiConfig.conversations}/$conversationId/read';
      
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse(_unreadCountEndpoint),
            headers: ApiConfig.getAuthHeaders(token),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['unread_count'] ?? 0;
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

