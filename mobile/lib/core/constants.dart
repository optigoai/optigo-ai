/// OptigoAI — API Constants
class ApiConstants {
  ApiConstants._();

  // Base URL — will be configurable per environment
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → host
  static const String iosBaseUrl = 'http://localhost:8000';

  // API version
  static const String apiPrefix = '/api/v1';

  // Endpoints
  static const String health = '$apiPrefix/health';
  static const String login = '$apiPrefix/auth/login';
  static const String signup = '$apiPrefix/auth/signup';
  static const String refreshToken = '$apiPrefix/auth/refresh';
  static const String businesses = '$apiPrefix/businesses';
  static const String reviews = '$apiPrefix/reviews';
  static const String recommendations = '$apiPrefix/recommendations';
  static const String content = '$apiPrefix/content';
  static const String campaigns = '$apiPrefix/campaigns';
  static const String creatives = '$apiPrefix/creatives';
  static const String chat = '$apiPrefix/chat';
  static const String analytics = '$apiPrefix/analytics';
  static const String notifications = '$apiPrefix/notifications';
  static const String seo = '$apiPrefix/seo';
  static const String competitors = '$apiPrefix/competitors';
}
