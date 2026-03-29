import 'package:flutter_test/flutter_test.dart';

import 'package:avishu_superapp/app.dart';

void main() {
  testWidgets('shows login shell', (WidgetTester tester) async {
    await tester.pumpWidget(const AvishuAppBootstrap());
    await tester.pumpAndSettle();

    expect(find.text('AVISHU'), findsWidgets);
    expect(find.text('ВХОД'), findsOneWidget);
    expect(find.text('РОЛИ'), findsOneWidget);
  });
}
