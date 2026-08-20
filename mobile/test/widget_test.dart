import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:optigoai_app/app/app.dart';
import 'package:optigoai_app/presentation/auth/auth_provider.dart';
import 'package:optigoai_app/data/api/api_client.dart';
import 'package:optigoai_app/data/repositories/auth_repository.dart';
import 'package:optigoai_app/data/repositories/business_repository.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final authRepo = AuthRepository(apiClient);
    final bizRepo = BusinessRepository(apiClient);
    final authProvider = AppAuthProvider(authRepo, bizRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppAuthProvider>.value(value: authProvider),
        ],
        child: const OptigoAIApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Welcome to OptigoAI or Sign In appears
    expect(find.text('Welcome to OptigoAI'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
