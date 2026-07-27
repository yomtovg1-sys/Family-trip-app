import 'package:flutter_test/flutter_test.dart';

import 'package:family_trip_app/main.dart';

void main() {
  testWidgets('Home screen shows trip name and quick access sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyTripApp());
    await tester.pump();

    expect(find.text('Family Trip Planner'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Itinerary'), findsOneWidget);
    expect(find.text('Packing'), findsOneWidget);
  });
}
