class ApiError {
  final String message;
  final Map<String, List<String>>? errors;
  final int statusCode;

  ApiError({required this.message, this.errors, required this.statusCode});

  factory ApiError.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiError(
      message: json['message'] ?? 'An error occurred',
      errors: json['errors'] != null
          ? Map<String, List<String>>.from(
              json['errors'].map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            )
          : null,
      statusCode: statusCode,
    );
  }

  String get firstError {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.values.first.first;
    }
    return message;
  }

  String getAllErrors() {
    if (errors == null || errors!.isEmpty) {
      return message;
    }

    final errorMessages = <String>[];
    errors!.forEach((field, messages) {
      errorMessages.addAll(messages);
    });

    return errorMessages.join('\n');
  }
}
