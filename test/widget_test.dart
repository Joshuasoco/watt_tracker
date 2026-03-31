// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:watt_tracker/data/local/hive_boxes.dart';
import 'package:watt_tracker/data/local/hive_adapters.dart';
import 'package:watt_tracker/data/models/component_model.dart';
import 'package:watt_tracker/data/models/device_model.dart';
import 'package:watt_tracker/data/models/session_model.dart';
import 'package:watt_tracker/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('watt_tracker_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DeviceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DeviceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ComponentTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ComponentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SessionModelAdapter());
    }

    await Future.wait([
      Hive.openBox<DeviceModel>(HiveBoxes.devices),
      Hive.openBox<ComponentModel>(HiveBoxes.components),
      Hive.openBox<SessionModel>(HiveBoxes.sessions),
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App boots on calculator page', (WidgetTester tester) async {
    await tester.pumpWidget(const WattTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Device Selector'), findsOneWidget);
  });
}
