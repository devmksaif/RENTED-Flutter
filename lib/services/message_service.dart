import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/messaging_config.dart';
import '../models/api_error.dart';
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
    try {
      final token = await _storageService.getToken();
      if (token == null) {
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
        throw ApiError(
          message: 'Either conversation_id or (receiver_id and product_id) must be provided',
          statusCode: 400,
        );
      }

      final response = await http
          .post(
            Uri.parse(_messagesEndpoint),
            headers: ApiConfig.getAuthHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData['data'] ?? responseData;
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

