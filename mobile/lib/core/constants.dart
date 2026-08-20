/// OptigoAI — API Constants
class ApiConstants {
  ApiConstants._();

  // Host IP for local device testing (can also be overridden with --dart-define=API_URL=http://...)
  static const String serverHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.51.25.138',
  );
  static const String serverPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8000',
  );

  static const String defaultApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.51.25.138:8000',
  );

  static const String baseUrl = defaultApiUrl;
  static const String iosBaseUrl = defaultApiUrl;

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
