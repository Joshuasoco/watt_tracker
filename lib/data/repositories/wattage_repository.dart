import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/component_model.dart';
import '../models/device_model.dart';
import '../presets/wattage_presets.dart';
import '../models/session_model.dart';

class WattageRepository {
  WattageRepository({
    Box<DeviceModel>? devicesBox,
    Box<ComponentModel>? componentsBox,
    Box<SessionModel>? sessionsBox,
  }) : _devicesBox = devicesBox ?? Hive.box<DeviceModel>(HiveBoxes.devices),
       _componentsBox =
           componentsBox ?? Hive.box<ComponentModel>(HiveBoxes.components),
       _sessionsBox = sessionsBox ?? Hive.box<SessionModel>(HiveBoxes.sessions);

  final Box<DeviceModel> _devicesBox;
  final Box<ComponentModel> _componentsBox;
  final Box<SessionModel> _sessionsBox;

  static const List<DeviceModel> devicePresets = WattagePresets.devices;
  static const List<ComponentModel> componentPresets =
      WattagePresets.components;

  List<DeviceModel> getSavedDevices() =>
      _devicesBox.values.toList(growable: false);

  List<ComponentModel> getSavedComponents() =>
      _componentsBox.values.toList(growable: false);

  List<SessionModel> getSavedSessions() =>
      _sessionsBox.values.toList(growable: false);

  Future<void> seedPresetsIfEmpty() async {
    if (_devicesBox.isEmpty) {
      final deviceMap = {for (final preset in devicePresets) preset.id: preset};
      await _devicesBox.putAll(deviceMap);
    }

    if (_componentsBox.isEmpty) {
      final componentMap = {
        for (final preset in componentPresets) preset.id: preset,
      };
      await _componentsBox.putAll(componentMap);
    }
  }

  Future<void> upsertDevice(DeviceModel device) async {
    await _devicesBox.put(device.id, device);
  }

  Future<void> upsertComponent(ComponentModel component) async {
    await _componentsBox.put(component.id, component);
  }

  Future<void> saveSession(SessionModel session) async {
    await _sessionsBox.put(session.id, session);
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionsBox.delete(sessionId);
  }
}
