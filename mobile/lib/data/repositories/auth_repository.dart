import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../models/user_model.dart';
import '../../core/constants.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  AuthRepository(this._apiClient, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getSavedAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
    required String organizationName,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.signup,
      body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'organization_name': organizationName.trim(),
      },
    );

    final user = UserModel.fromJson(response['user']);
    final tokens = response['tokens'];
    final accessToken = tokens['access_token'] as String;
    final refreshToken = tokens['refresh_token'] as String;

    await _saveTokens(accessToken, refreshToken);
    _apiClient.setAccessToken(accessToken);

    return {'user': user, 'tokens': tokens};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final user = UserModel.fromJson(response['user']);
    final tokens = response['tokens'];
    final accessToken = tokens['access_token'] as String;
    final refreshToken = tokens['refresh_token'] as String;

    await _saveTokens(accessToken, refreshToken);
    _apiClient.setAccessToken(accessToken);

    return {'user': user, 'tokens': tokens};
  }

  Future<UserModel> getMe() async {
    final token = await getSavedAccessToken();
    if (token == null) throw ApiException('Not authenticated');
    _apiClient.setAccessToken(token);

    final response = await _apiClient.get('/api/v1/auth/me');
    return UserModel.fromJson(response['user']);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/api/v1/auth/logout');
    } catch (_) {}
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    _apiClient.setAccessToken(null);
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: _keyAccessToken, value: access);
    await _storage.write(key: _keyRefreshToken, value: refresh);
  }
}
