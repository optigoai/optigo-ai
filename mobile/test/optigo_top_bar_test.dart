import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:optigoai_app/presentation/shared/optigo_top_bar.dart';
import 'package:optigoai_app/presentation/auth/auth_provider.dart';
import 'package:optigoai_app/data/api/api_client.dart';
import 'package:optigoai_app/data/repositories/auth_repository.dart';
import 'package:optigoai_app/data/repositories/business_repository.dart';
import 'package:optigoai_app/data/repositories/notification_repository.dart';

void main() {
  Widget buildTestWidget({
    bool showBackButton = false,
    VoidCallback? onRefreshTap,
    bool isRefreshing = false,
    String? subtitle,
  }) {
    final apiClient = ApiClient();
    final authRepo = AuthRepository(apiClient);
    final bizRepo = BusinessRepository(apiClient);
    final notifRepo = NotificationRepository(apiClient);
    final authProvider = AppAuthProvider(authRepo, bizRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAuthProvider>.value(value: authProvider),
        Provider<NotificationRepository>.value(value: notifRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OptigoTopBar(
            showBackButton: showBackButton,
            onRefreshTap: onRefreshTap,
            isRefreshing: isRefreshing,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }

  testWidgets('OptigoTopBar renders standard top navigation elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(subtitle: 'Local SEO Visibility'));
    await tester.pump();

    // Menu icon should be rendered by default
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    // Business short brand name and monogram should be present
    expect(find.text('Optigo'), findsOneWidget);
    expect(find.text('OB'), findsOneWidget);

    // AI mascot action button with tooltip should be rendered
    expect(find.byTooltip('Ask AI CMO Copilot'), findsOneWidget);

    // Notification bell should be rendered
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('OptigoTopBar renders back button when showBackButton is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(showBackButton: true));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
  });

  testWidgets(
    'OptigoTopBar renders sync button when onRefreshTap is provided',
    (WidgetTester tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        buildTestWidget(
          onRefreshTap: () => refreshed = true,
          isRefreshing: false,
        ),
      );
      await tester.pump();

      final syncBtn = find.byIcon(Icons.sync_rounded);
      expect(syncBtn, findsOneWidget);

      await tester.tap(syncBtn);
      expect(refreshed, isTrue);
    },
  );

  testWidgets('OptigoTopBar opens business switcher sheet on chip tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Tap the business name chip
    await tester.tap(find.text('Optigo'));
    await tester.pumpAndSettle();

    // The business switcher bottom sheet should appear
    expect(find.text('Store & Business Hub'), findsOneWidget);
    expect(find.text('All Features'), findsOneWidget);
  });
}
