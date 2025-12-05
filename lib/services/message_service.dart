import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/messaging_config.dart';
import '../models/api_error.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class MessageService {
  final StorageService _storageService = StorageService();
  
  // Set to true when microservice is deployed
  static const bool useMicroservice = false;
  
  String get _messagesEndpoint => useMicroservice
      ? MessagingConfig.messages
      : ApiConfig.messages;

  /// Send a message (creates conversation if needed)
  Future<Map<String, dynamic>> sendMessage({
    int? conversationId,
    int? receiverId,
    int? productId,
    required String content,
  }) async {
    final url = _messagesEndpoint;
    try {
      AppLogger.apiRequest('POST', url, body: {
        'content': content,
        if (conversationId != null) 'conversation_id': conversationId,
        if (receiverId != null) 'receiver_id': receiverId,
        if (productId != null) 'product_id': productId,
      });
      AppLogger.i('💬 Sending message');

      final token = await _storageService.getToken();
      if (token == null) {
        AppLogger.apiError(url, 401, 'Not authenticated');
        throw ApiError(message: 'Not authenticated', statusCode: 401);
      }

      final body = <String, dynamic>{
        'content': content,
      };

      if (conversationId != null) {
        body['conversation_id'] = conversationId;
      } else if (receiverId != null && productId != null) {
        body['receiver_id'] = receiverId;
        body['product_id'] = productId;
      } else {
        AppLogger.apiError(url, 400, 'Either conversation_id or (receiver_id and product_id) must be provided');
        throw ApiError(
          message: 'Either conversation_id or (receiver_id and product_id) must be provided',
          statusCode: 400,
        );
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);
      AppLogger.apiResponse(response.statusCode, url, body: responseData);

      if (response.statusCode == 201) {
        AppLogger.i('✅ Message sent successfully');
        return responseData['data'] ?? responseData;
      } else {
        AppLogger.apiError(url, response.statusCode, responseData['message'] ?? 'Unknown error', errors: responseData['errors']);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } on ApiError catch (e) {
      AppLogger.apiError(url, e.statusCode, e.message, errors: e.errors);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.networkError('sendMessage', e);
      AppLogger.e('Failed to send message', e, stackTrace);
      throw ApiError(
        message: 'Network error. Please check your connection.',
        statusCode: 0,
      );
    }
  }
}

