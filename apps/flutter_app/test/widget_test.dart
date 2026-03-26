import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:earndash_flutter/app/app.dart';

void main() {
  testWidgets('app shell renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EarnDashApp()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('EarnDash'), findsWidgets);
    expect(find.text('Log in'), findsOneWidget);
  });
}
