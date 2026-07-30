import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:family_trip_app/main.dart';

/// `flutter test` runs on the host VM, not web, so Hive's bootstrap needs a
/// real filesystem path from `path_provider` — a plugin with no platform
/// channel implementation available in the widget-test environment. This
/// fake stands in for it, pointing Hive at a throwaway temp directory so
/// the same bootstrap code the real app uses can run in a test.
class _FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.createTempSync('easytrip_test_').path;
}

void main() {
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  testWidgets('Home dashboard shows countdown, journey and quick access',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dependencies = await AppDependencies.bootstrap();
    await tester.pumpWidget(FamilyTripApp(dependencies: dependencies));
    await tester.pump();

    expect(find.textContaining('days to go'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Reservations'), findsOneWidget);
    expect(find.text('AI Travel Assistant'), findsOneWidget);
  });
}
