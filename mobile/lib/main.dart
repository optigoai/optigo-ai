import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'data/api/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/business_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/recommendation_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/seo_repository.dart';
import 'data/repositories/campaign_repository.dart';
import 'data/repositories/creative_repository.dart';
import 'data/repositories/cmo_chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/gsc_repository.dart';
import 'presentation/auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final apiClient = ApiClient();
  final authRepo = AuthRepository(apiClient);
  final bizRepo = BusinessRepository(apiClient);
  final reviewRepo = ReviewRepository(apiClient);
  final recRepo = RecommendationRepository(apiClient);
  final contentRepo = ContentRepository(apiClient);
  final seoRepo = SeoRepository(apiClient);
  final campaignRepo = CampaignRepository(apiClient);
  final creativeRepo = CreativeRepository(apiClient);
  final cmoChatRepo = CmoChatRepository(apiClient);
  final notificationRepo = NotificationRepository(apiClient);
  final gscRepo = GscRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<BusinessRepository>.value(value: bizRepo),
        Provider<ReviewRepository>.value(value: reviewRepo),
        Provider<RecommendationRepository>.value(value: recRepo),
        Provider<ContentRepository>.value(value: contentRepo),
        Provider<SeoRepository>.value(value: seoRepo),
        Provider<CampaignRepository>.value(value: campaignRepo),
        Provider<CreativeRepository>.value(value: creativeRepo),
        Provider<CmoChatRepository>.value(value: cmoChatRepo),
        Provider<NotificationRepository>.value(value: notificationRepo),
        Provider<GscRepository>.value(value: gscRepo),
        ChangeNotifierProvider<AppAuthProvider>(
          create: (_) => AppAuthProvider(authRepo, bizRepo)..checkAuth(),
        ),
      ],
      child: const OptigoAIApp(),
    ),
  );
}
