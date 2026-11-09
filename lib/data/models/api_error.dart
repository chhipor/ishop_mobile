class ApiErrorResponse {
  const ApiErrorResponse({
    required this.timestamp,
    required this.status,
    required this.error,
    required this.message,
    required this.path,
    this.fieldErrors,
  });

  final String timestamp;
  final int status;
  final String error;
  final String message;
  final String path;
  final Map<String, String>? fieldErrors;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final rawFieldErrors = json['fieldErrors'];
    return ApiErrorResponse(
      timestamp: json['timestamp'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      error: json['error'] as String? ?? '',
      message: json['message'] as String? ?? '',
      path: json['path'] as String? ?? '',
      fieldErrors: rawFieldErrors is Map
          ? rawFieldErrors.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'status': status,
    'error': error,
    'message': message,
    'path': path,
    if (fieldErrors != null) 'fieldErrors': fieldErrors,
  };
}

enum ApiErrorKind {
  network,

  badRequest,

  unauthorized,

  forbidden,

  sessionExpired,

  notFound,

  conflict,

  server,

  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.body,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final ApiErrorResponse? body;

  Map<String, String> get fieldErrors => body?.fieldErrors ?? const {};

  factory ApiException.network(String detail) =>
      ApiException(kind: ApiErrorKind.network, message: detail);

  factory ApiException.sessionExpired() => const ApiException(
    kind: ApiErrorKind.sessionExpired,
    message: 'Your session has expired. Please sign in again.',
  );

  factory ApiException.fromStatus(int status, ApiErrorResponse? body) {
    final ApiErrorKind kind;
    if (status == 400) {
      kind = ApiErrorKind.badRequest;
    } else if (status == 401) {
      kind = ApiErrorKind.unauthorized;
    } else if (status == 403) {
      kind = ApiErrorKind.forbidden;
    } else if (status == 404) {
      kind = ApiErrorKind.notFound;
    } else if (status == 409) {
      kind = ApiErrorKind.conflict;
    } else if (status >= 500) {
      kind = ApiErrorKind.server;
    } else {
      kind = ApiErrorKind.unknown;
    }
    final message = (body != null && body.message.isNotEmpty)
        ? body.message
        : 'Request failed with status $status';
    return ApiException(
      kind: kind,
      message: message,
      statusCode: status,
      body: body,
    );
  }

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
