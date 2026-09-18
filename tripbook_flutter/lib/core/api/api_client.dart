import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();
  
  String? _sessionCookie;
  String? _csrfToken;
  String _baseUrl = ApiEndpoints.defaultLocalBaseUrl;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.responseType = ResponseType.plain;
    
    // Load persisted session on init
    _secureStorage.read(key: 'session_cookie').then((v) => _sessionCookie = v);
    _secureStorage.read(key: 'csrf_token').then((v) => _csrfToken = v);
    
    // Add custom Interceptor for cookie & csrf management
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Enforce Content-Type
        options.headers['Content-Type'] = 'application/json';
        options.headers['Accept'] = 'application/json';
        
        // Attach session cookie if stored
        if (_sessionCookie != null) {
          options.headers['Cookie'] = _sessionCookie;
        } else {
          // Attempt to load from secure storage
          _sessionCookie = await _secureStorage.read(key: 'session_cookie');
          if (_sessionCookie != null) {
            options.headers['Cookie'] = _sessionCookie;
          }
        }

        // Attach CSRF token on POST requests
        if (options.method == 'POST' && _csrfToken != null) {
          options.headers['X-CSRF-Token'] = _csrfToken;
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // Capture session cookie from headers
        final setCookies = response.headers['set-cookie'];
        if (setCookies != null && setCookies.isNotEmpty) {
          for (var cookie in setCookies) {
            if (cookie.contains('PHPSESSID=')) {
              // Extract the PHPSESSID part
              final parts = cookie.split(';');
              for (var part in parts) {
                if (part.trim().startsWith('PHPSESSID=')) {
                  _sessionCookie = part.trim();
                  await _secureStorage.write(key: 'session_cookie', value: _sessionCookie);
                  break;
                }
              }
            }
          }
        }

        // Parse response to capture CSRF token (ResponseType.plain gives String)
        try {
          Map<String, dynamic>? dataMap;
          if (response.data is Map<String, dynamic>) {
            dataMap = response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            dataMap = jsonDecode(response.data as String) as Map<String, dynamic>?;
          }
          if (dataMap != null && dataMap['success'] == true && dataMap['data'] != null) {
            final innerData = dataMap['data'];
            if (innerData is Map<String, dynamic> && innerData['csrf_token'] != null) {
              _csrfToken = innerData['csrf_token'];
              await _secureStorage.write(key: 'csrf_token', value: _csrfToken);
            }
          }
        } catch (_) {}

        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;

  Future<void> clearSession() async {
    _sessionCookie = null;
    _csrfToken = null;
    await _secureStorage.delete(key: 'session_cookie');
    await _secureStorage.delete(key: 'csrf_token');
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$path',
        queryParameters: queryParameters,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '$_baseUrl$path',
        data: data,
      );
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _processResponse(Response response) {
    final raw = response.data;
    Map<String, dynamic> body;
    if (raw is Map<String, dynamic>) {
      body = raw;
    } else if (raw is String) {
      try {
        body = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException('Invalid response: ${raw.substring(0, raw.length > 200 ? 200 : raw.length)}', response.statusCode);
      }
    } else {
      throw ApiException('Invalid JSON response format', response.statusCode);
    }
    if (body['success'] == true) {
      return body;
    } else {
      throw ApiException(body['message'] ?? 'API request failed', response.statusCode);
    }
  }

  Exception _handleDioError(DioException e) {
    print('=== API ERROR ===');
    print('Type: ${e.type}');
    print('Message: ${e.message}');
    print('Error: ${e.error}');
    print('Error runtimeType: ${e.error.runtimeType}');
    if (e.error is Exception) {
      print('Inner: ${(e.error as Exception)}');
    }
    print('URL: ${e.requestOptions.uri}');
    print('=================');
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Network connection timed out. Please try again.');
    }
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 401) {
        clearSession();
        return ApiException('Session expired. Please log in again.', 401);
      }
      final body = e.response!.data;
      if (body is Map<String, dynamic> && body['message'] != null) {
        return ApiException(body['message'], statusCode);
      }
      return ApiException('Server returned error code $statusCode', statusCode);
    }
    return ApiException('Failed to connect to server (${e.type}). Check your network connection.');
  }
}
