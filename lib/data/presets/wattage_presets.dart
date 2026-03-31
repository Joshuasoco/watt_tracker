import '../models/component_model.dart';
import '../models/device_model.dart';

class WattagePresets {
  static const List<DeviceModel> devices = [
    DeviceModel(
      id: 'device_laptop',
      type: DeviceType.laptop,
      label: 'Laptop',
      wattage: 65,
    ),
    DeviceModel(
      id: 'device_pc',
      type: DeviceType.pc,
      label: 'PC',
      wattage: 180,
    ),
    DeviceModel(
      id: 'device_desktop',
      type: DeviceType.desktop,
      label: 'Desktop',
      wattage: 250,
    ),
    DeviceModel(
      id: 'device_mini',
      type: DeviceType.mini,
      label: 'Mini PC',
      wattage: 90,
    ),
  ];

  static const List<ComponentModel> components = [
    ComponentModel(
      id: 'cmp_gpu_mid',
      type: ComponentType.gpu,
      label: 'GPU Midrange',
      wattage: 180,
    ),
    ComponentModel(
      id: 'cmp_ram_16',
      type: ComponentType.ram,
      label: 'RAM 16GB',
      wattage: 8,
    ),
    ComponentModel(
      id: 'cmp_storage_ssd',
      type: ComponentType.storage,
      label: 'Storage SSD',
      wattage: 5,
    ),
    ComponentModel(
      id: 'cmp_fans_3',
      type: ComponentType.fans,
      label: 'Fans x3',
      wattage: 9,
    ),
    ComponentModel(
      id: 'cmp_rgb_std',
      type: ComponentType.rgb,
      label: 'RGB Strip',
      wattage: 12,
    ),
  ];
}
