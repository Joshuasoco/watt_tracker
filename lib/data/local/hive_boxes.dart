import 'package:hive_flutter/hive_flutter.dart';

import '../models/component_model.dart';
import '../models/device_model.dart';
import '../models/session_model.dart';
import 'hive_adapters.dart';
import 'hive_migrations.dart';

class HiveBoxes {
  static const String devices = 'devices_box';
  static const String components = 'components_box';
  static const String sessions = 'sessions_box';
  static const String appPreferences = 'app_preferences_box';
  static const String wattwisePrefs = 'wattwise_prefs';
  static const String energyAudit = 'energy_audit';
}

class HiveBootstrap {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    _registerAdapters();

    await Future.wait([
      Hive.openBox<DeviceModel>(HiveBoxes.devices),
      Hive.openBox<ComponentModel>(HiveBoxes.components),
      Hive.openBox<SessionModel>(HiveBoxes.sessions),
      Hive.openBox<dynamic>(HiveBoxes.appPreferences),
      Hive.openBox<dynamic>(HiveBoxes.wattwisePrefs),
      Hive.openBox<dynamic>(HiveBoxes.energyAudit),
    ]);

    await HiveMigrations.run(
      wattwisePrefsBox: Hive.box<dynamic>(HiveBoxes.wattwisePrefs),
      energyAuditBox: Hive.box<dynamic>(HiveBoxes.energyAudit),
      appPreferencesBox: Hive.box<dynamic>(HiveBoxes.appPreferences),
    );
  }

  static void _registerAdapters() {
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
  }
}
