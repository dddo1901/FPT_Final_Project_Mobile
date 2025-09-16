import 'dart:async';
import 'package:http/http.dart' as http;

/// Interceptor tự chèn Authorization, có thể "skip" theo URL.
class TokenClient extends http.BaseClient {
  final http.Client _inner;
  final String? Function() getAccessToken;
  final bool Function(Uri)? shouldSkip;
  final FutureOr<void> Function()? onUnauthorized;

  TokenClient({
    required http.Client inner,
    required this.getAccessToken,
    this.shouldSkip,
    this.onUnauthorized,
  }) : _inner = inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final skip = shouldSkip?.call(request.url) ?? false;

    if (!skip) {
      final token = getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final resp = await _inner.send(request);

    if (resp.statusCode == 401 && onUnauthorized != null) {
      await onUnauthorized!(); // TODO: refresh/logout nếu cần
    }
    return resp;
  }
}
