import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Lightweight HTTP helper with retry handling and connection pool safeguards.
class HttpService {
  static const int _defaultMaxRetries = 3;
  static const int _connectionPoolMaxRetries = 10;
  static const Duration _initialDelay = Duration(milliseconds: 800);
  static const Duration _maxDelay = Duration(seconds: 8);
  static const Duration _timeout = Duration(seconds: 30);

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    int maxRetries = _defaultMaxRetries,
  }) {
    return _retryRequest(
      () => http.get(uri, headers: headers).timeout(_timeout),
      requestType: 'GET',
      url: uri.toString(),
      maxRetries: maxRetries,
    );
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = _defaultMaxRetries,
  }) {
    return _retryRequest(
      () => http.post(uri, headers: headers, body: body).timeout(_timeout),
      requestType: 'POST',
      url: uri.toString(),
      maxRetries: maxRetries,
    );
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = _defaultMaxRetries,
  }) {
    return _retryRequest(
      () => http.put(uri, headers: headers, body: body).timeout(_timeout),
      requestType: 'PUT',
      url: uri.toString(),
      maxRetries: maxRetries,
    );
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = _defaultMaxRetries,
  }) {
    return _retryRequest(
      () => http.delete(uri, headers: headers, body: body).timeout(_timeout),
      requestType: 'DELETE',
      url: uri.toString(),
      maxRetries: maxRetries,
    );
  }

  static Future<http.Response> _retryRequest(
    Future<http.Response> Function() request, {
    required String requestType,
    required String url,
    required int maxRetries,
  }) async {
    int attempt = 0;
    int allowedRetries = maxRetries;
    Duration delay = _initialDelay;

    while (true) {
      attempt++;
      try {
        final response = await request();

        if (_isConnectionPoolError(response) && attempt < _connectionPoolMaxRetries) {
          allowedRetries = _connectionPoolMaxRetries;
          if (attempt < allowedRetries) {
            _log('$requestType attempt $attempt hit connection pool issue (${_summarizeBody(response.body)}), retrying in ${delay.inMilliseconds}ms: $url');
            await Future.delayed(delay);
            delay = _nextDelay(delay);
            continue;
          }
        }

        if (_shouldRetry(response.statusCode) && attempt < allowedRetries) {
          _log('$requestType attempt $attempt failed with ${response.statusCode} (${_summarizeBody(response.body)}), retrying in ${delay.inMilliseconds}ms: $url');
          await Future.delayed(delay);
          delay = _nextDelay(delay);
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt >= allowedRetries) {
          throw Exception('Request timeout after $attempt attempts. Please try again.');
        }
        _log('$requestType attempt $attempt timed out, retrying in ${delay.inMilliseconds}ms: $url');
        await Future.delayed(delay);
        delay = _nextDelay(delay);
      } on SocketException {
        if (attempt >= allowedRetries) {
          throw Exception('Network error after $attempt attempts. Check your connection.');
        }
        _log('$requestType attempt $attempt failed with network error, retrying in ${delay.inMilliseconds}ms: $url');
        await Future.delayed(delay);
        delay = _nextDelay(delay);
      } on http.ClientException {
        if (attempt >= allowedRetries) {
          throw Exception('Connection error after $attempt attempts. Please try again later.');
        }
        _log('$requestType attempt $attempt failed with client error, retrying in ${delay.inMilliseconds}ms: $url');
        await Future.delayed(delay);
        delay = _nextDelay(delay);
      }
    }
  }

  static Duration _nextDelay(Duration current) {
    final doubled = current * 2;
    return doubled > _maxDelay ? _maxDelay : doubled;
  }

  static bool _shouldRetry(int statusCode) {
    return statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static bool _isConnectionPoolError(http.Response response) {
    if (response.statusCode != 401) return false;
    final body = response.body.toLowerCase().trim();

    // Known authorization failures that should not trigger aggressive retries
    const authFailureKeywords = [
      'invalid email',
      'invalid credentials',
      'invalid token',
      'credentials were not provided',
      'user account is disabled',
      'authentication credentials',
      'unauthorized',
    ];

    for (final keyword in authFailureKeywords) {
      if (body.contains(keyword)) {
        return false;
      }
    }

    if (body.isEmpty) {
      return true;
    }

    return body.contains('connection pool') ||
        body.contains('pool timeout') ||
        body.contains('connection already closed') ||
        body.contains('pool is full') ||
        body.contains('connection aborted') ||
        body.contains('max retries exceeded');
  }

  static void _log(String message) {
    // Keep logging lightweight for debugging during demo runs.
    // ignore: avoid_print
    print('[HttpService] $message');
  }

  static String _summarizeBody(String body) {
    if (body.isEmpty) return 'empty body';
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 80) return clean;
    return clean.substring(0, 77) + '...';
  }
}
