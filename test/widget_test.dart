import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_trip_app/main.dart';

void main() {
  testWidgets('Home dashboard shows countdown, journey and quick access',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FamilyTripApp());
    await tester.pump();

    expect(find.textContaining('days to go'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text('AI Travel Assistant'), findsOneWidget);
  });
}
