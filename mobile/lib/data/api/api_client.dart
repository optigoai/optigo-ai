import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  String? _accessToken;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return ApiConstants.baseUrl;
    return ApiConstants.iosBaseUrl;
  }

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // If memory token is missing, attempt loading from secure storage
    if (_accessToken == null || _accessToken!.isEmpty) {
      _accessToken = await _storage.read(key: 'access_token');
    }

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _buildHeaders();
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _buildHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _buildHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error. Please check your connection.');
    }
  }

  Future<dynamic> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _buildHeaders();
      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error. Please check your connection.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;
    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String errorMessage = 'An unexpected error occurred.';
    if (data is Map && data.containsKey('detail')) {
      final detail = data['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        errorMessage = detail[0]['msg'] ?? errorMessage;
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }
}
