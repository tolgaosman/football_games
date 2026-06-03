import 'package:flutter_test/flutter_test.dart';
import 'package:flyball/main.dart';
import 'package:flyball/screens/football_xox_screen.dart';

void main() {
  testWidgets('Home shows the three game buttons', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    expect(find.text('FOOTBALL XOX'), findsOneWidget);
    expect(find.text('FOOTBALLDLE'), findsOneWidget);
    expect(find.text('1 TEAM 1 COUNTRY'), findsOneWidget);
  });

  testWidgets('Tapping Football XOX opens the grid game', (tester) async {
    await tester.pumpWidget(const FlyballApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('FOOTBALL XOX'));
    await tester.pumpAndSettle();

    expect(find.byType(FootballXoxScreen), findsOneWidget);
    // Score bar starts at 0/9.
    expect(find.text('0/9'), findsOneWidget);
  });
}
