import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_error.dart';
import 'storage_service.dart';

class NotificationService {
  final StorageService _storageService = StorageService();

  /// Get notifications for the authenticated user
  Future<List<NotificationItem>> getNotifications() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(ApiConfig.connectionTimeout);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => NotificationItem.fromJson(json)).toList();
      } else {
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'Failed to load notifications', statusCode: 0);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw ApiError(message: 'Authentication required', statusCode: 401);
      }

      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/notifications/$notificationId/read',
            ),
            headers: {...ApiConfig.headers, 'Authorization': 'Bearer $token'},
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw ApiError.fromJson(responseData, response.statusCode);
      }
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(
        message: 'Failed to mark notification as read',
        statusCode: 0,
      );
    }
  }
}

class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
