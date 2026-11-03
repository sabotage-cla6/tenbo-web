import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/main.dart';

void main() {
  testWidgets('未設定時はログイン画面を表示する', (WidgetTester tester) async {
    await tester.pumpWidget(const TenboApp(firebaseReady: false));

    expect(find.text('天棒'), findsOneWidget);
    expect(find.text('ログイン'), findsNWidgets(2));
    expect(find.text('Firebase未設定のため、現在はログインできません。設定手順はREADMEを確認してください。'), findsOneWidget);
  });
}
