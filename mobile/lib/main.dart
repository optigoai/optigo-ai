import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'data/api/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/business_repository.dart';
import 'data/repositories/review_repository.dart';
import 'presentation/auth/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light status bar for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Core dependencies
  final apiClient = ApiClient();
  final authRepo = AuthRepository(apiClient);
  final bizRepo = BusinessRepository(apiClient);
  final reviewRepo = ReviewRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<BusinessRepository>.value(value: bizRepo),
        Provider<ReviewRepository>.value(value: reviewRepo),
        ChangeNotifierProvider(
          create: (_) => AppAuthProvider(authRepo, bizRepo)..checkAuth(),
        ),
      ],
      child: const OptigoAIApp(),
    ),
  );
}
