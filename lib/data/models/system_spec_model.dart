import 'field_metadata.dart';

class SystemSpecModel {
  const SystemSpecModel({
    required this.cpuName,
    required this.cpuTdpWatts,
    required this.gpuType,
    required this.gpuName,
    required this.gpuWatts,
    required this.ramGb,
    required this.ramSticks,
    this.ramWattsPerStick = 3,
    required this.storageCount,
    required this.storageType,
    required this.storageWattsEach,
    required this.fanCount,
    this.fansWattsEach = 2,
    required this.hasRgb,
    required this.rgbWatts,
    this.motherboardWatts = 50,
    required this.motherboard,
    required this.chassisType,
    this.fieldMetadata = const <String, FieldMetadata>{},
  });

  static const String cpuNameField = 'cpu_name';
  static const String cpuTdpWattsField = 'cpu_tdp_watts';
  static const String gpuTypeField = 'gpu_type';
  static const String gpuNameField = 'gpu_name';
  static const String gpuWattsField = 'gpu_watts';
  static const String ramGbField = 'ram_gb';
  static const String ramSticksField = 'ram_sticks';
  static const String storageCountField = 'storage_count';
  static const String storageTypeField = 'storage_type';
  static const String storageWattsEachField = 'storage_watts_each';
  static const String fanCountField = 'fan_count';
  static const String hasRgbField = 'has_rgb';
  static const String rgbWattsField = 'rgb_watts';
  static const String motherboardField = 'motherboard';
  static const String chassisTypeField = 'chassis_type';

  static const List<String> metadataFields = <String>[
    cpuNameField,
    cpuTdpWattsField,
    gpuTypeField,
    gpuNameField,
    gpuWattsField,
    ramGbField,
    ramSticksField,
    storageCountField,
    storageTypeField,
    storageWattsEachField,
    fanCountField,
    hasRgbField,
    rgbWattsField,
    motherboardField,
    chassisTypeField,
  ];

  factory SystemSpecModel.defaults() {
    return SystemSpecModel(
      cpuName: 'Unknown CPU',
      cpuTdpWatts: 65,
      gpuType: 'integrated',
      gpuName: 'Integrated Graphics',
      gpuWatts: 15,
      ramGb: 8,
      ramSticks: 1,
      storageCount: 1,
      storageType: 'SSD',
      storageWattsEach: 3,
      fanCount: 1,
      hasRgb: false,
      rgbWatts: 0,
      motherboard: 'Unknown Motherboard',
      chassisType: 'desktop',
      fieldMetadata: metadataFields.asMap().map(
        (_, field) => MapEntry(field, FieldMetadata.unknown()),
      ),
    );
  }

  factory SystemSpecModel.fromPrefsMap(Map<String, dynamic> map) {
    final defaults = SystemSpecModel.defaults();

    return defaults.copyWith(
      cpuName: (map[cpuNameField] as String?) ?? defaults.cpuName,
      cpuTdpWatts: _toInt(map[cpuTdpWattsField]) ?? defaults.cpuTdpWatts,
      gpuType: (map[gpuTypeField] as String?) ?? defaults.gpuType,
      gpuName: (map[gpuNameField] as String?) ?? defaults.gpuName,
      gpuWatts: _toInt(map[gpuWattsField]) ?? defaults.gpuWatts,
      ramGb: _toInt(map[ramGbField]) ?? defaults.ramGb,
      ramSticks: _toInt(map[ramSticksField]) ?? defaults.ramSticks,
      storageCount: _toInt(map[storageCountField]) ?? defaults.storageCount,
      storageType: (map[storageTypeField] as String?) ?? defaults.storageType,
      storageWattsEach:
          _toInt(map[storageWattsEachField]) ?? defaults.storageWattsEach,
      fanCount: _toInt(map[fanCountField]) ?? defaults.fanCount,
      hasRgb: (map[hasRgbField] as bool?) ?? defaults.hasRgb,
      rgbWatts: _toInt(map[rgbWattsField]) ?? defaults.rgbWatts,
      motherboard: (map[motherboardField] as String?) ?? defaults.motherboard,
      chassisType: (map[chassisTypeField] as String?) ?? defaults.chassisType,
      fieldMetadata: metadataFromPrefs(map['spec_metadata']),
    );
  }

  final String cpuName;
  final int cpuTdpWatts;
  final String gpuType;
  final String gpuName;
  final int gpuWatts;
  final int ramGb;
  final int ramSticks;
  final int ramWattsPerStick;
  final int storageCount;
  final String storageType;
  final int storageWattsEach;
  final int fanCount;
  final int fansWattsEach;
  final bool hasRgb;
  final int rgbWatts;
  final int motherboardWatts;
  final String motherboard;
  final String chassisType;
  final Map<String, FieldMetadata> fieldMetadata;

  int get totalWatts {
    final rgbLoad = hasRgb ? rgbWatts : 0;
    return cpuTdpWatts +
        gpuWatts +
        (ramSticks * ramWattsPerStick) +
        (storageCount * storageWattsEach) +
        (fanCount * fansWattsEach) +
        rgbLoad +
        motherboardWatts;
  }

  double costPerSecond(double rateKwh) {
    return (totalWatts / 1000) * rateKwh / 3600;
  }

  Map<String, dynamic> toPrefsMap() {
    return {
      cpuNameField: cpuName,
      cpuTdpWattsField: cpuTdpWatts,
      gpuTypeField: gpuType,
      gpuNameField: gpuName,
      gpuWattsField: gpuWatts,
      ramGbField: ramGb,
      ramSticksField: ramSticks,
      storageCountField: storageCount,
      storageTypeField: storageType,
      storageWattsEachField: storageWattsEach,
      fanCountField: fanCount,
      hasRgbField: hasRgb,
      rgbWattsField: rgbWatts,
      motherboardField: motherboard,
      chassisTypeField: chassisType,
      'spec_metadata': metadataToPrefs(fieldMetadata),
    };
  }

  FieldMetadata metadataFor(String field) {
    return fieldMetadata[field] ?? FieldMetadata.unknown();
  }

  SystemSpecModel copyWith({
    String? cpuName,
    int? cpuTdpWatts,
    String? gpuType,
    String? gpuName,
    int? gpuWatts,
    int? ramGb,
    int? ramSticks,
    int? ramWattsPerStick,
    int? storageCount,
    String? storageType,
    int? storageWattsEach,
    int? fanCount,
    int? fansWattsEach,
    bool? hasRgb,
    int? rgbWatts,
    int? motherboardWatts,
    String? motherboard,
    String? chassisType,
    Map<String, FieldMetadata>? fieldMetadata,
  }) {
    return SystemSpecModel(
      cpuName: cpuName ?? this.cpuName,
      cpuTdpWatts: cpuTdpWatts ?? this.cpuTdpWatts,
      gpuType: gpuType ?? this.gpuType,
      gpuName: gpuName ?? this.gpuName,
      gpuWatts: gpuWatts ?? this.gpuWatts,
      ramGb: ramGb ?? this.ramGb,
      ramSticks: ramSticks ?? this.ramSticks,
      ramWattsPerStick: ramWattsPerStick ?? this.ramWattsPerStick,
      storageCount: storageCount ?? this.storageCount,
      storageType: storageType ?? this.storageType,
      storageWattsEach: storageWattsEach ?? this.storageWattsEach,
      fanCount: fanCount ?? this.fanCount,
      fansWattsEach: fansWattsEach ?? this.fansWattsEach,
      hasRgb: hasRgb ?? this.hasRgb,
      rgbWatts: rgbWatts ?? this.rgbWatts,
      motherboardWatts: motherboardWatts ?? this.motherboardWatts,
      motherboard: motherboard ?? this.motherboard,
      chassisType: chassisType ?? this.chassisType,
      fieldMetadata: fieldMetadata ?? this.fieldMetadata,
    );
  }

  static Map<String, dynamic> metadataToPrefs(
    Map<String, FieldMetadata> metadata,
  ) {
    return metadata.map((key, value) => MapEntry(key, value.toMap()));
  }

  static Map<String, FieldMetadata> metadataFromPrefs(dynamic raw) {
    final parsed = <String, FieldMetadata>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String && value is Map) {
          parsed[key] = FieldMetadata.fromMap(Map<String, dynamic>.from(value));
        }
      });
    }

    return {
      for (final field in metadataFields)
        field: parsed[field] ?? FieldMetadata.unknown(),
    };
  }

  static Map<String, FieldMetadata> metadataForFields({
    required Iterable<String> scanFields,
    required Iterable<String> inferredFields,
    DateTime? lastUpdated,
  }) {
    final scanFieldSet = scanFields.toSet();
    final inferredFieldSet = inferredFields.toSet();

    return {
      for (final field in metadataFields)
        field: scanFieldSet.contains(field)
            ? FieldMetadata.scanned(lastUpdated: lastUpdated)
            : inferredFieldSet.contains(field)
            ? FieldMetadata.inferred(lastUpdated: lastUpdated)
            : FieldMetadata.unknown(),
    };
  }

  static Map<String, FieldMetadata> userConfirmedMetadata({
    DateTime? lastUpdated,
  }) {
    return {
      for (final field in metadataFields)
        field: FieldMetadata.user(lastUpdated: lastUpdated),
    };
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.round();
    }
    return null;
  }
}
