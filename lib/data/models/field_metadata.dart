enum FieldSource {
  unknown,
  scan,
  user,
  inferred;

  static FieldSource fromStorage(String? raw) {
    return FieldSource.values.firstWhere(
      (item) => item.name == raw,
      orElse: () => FieldSource.unknown,
    );
  }
}

class FieldMetadata {
  const FieldMetadata({
    required this.source,
    required this.confidence,
    this.lastUpdated,
  });

  factory FieldMetadata.unknown() {
    return const FieldMetadata(source: FieldSource.unknown, confidence: 0);
  }

  factory FieldMetadata.scanned({DateTime? lastUpdated}) {
    return FieldMetadata(
      source: FieldSource.scan,
      confidence: 0.9,
      lastUpdated: lastUpdated,
    );
  }

  factory FieldMetadata.user({DateTime? lastUpdated}) {
    return FieldMetadata(
      source: FieldSource.user,
      confidence: 1,
      lastUpdated: lastUpdated,
    );
  }

  factory FieldMetadata.inferred({
    double confidence = 0.55,
    DateTime? lastUpdated,
  }) {
    return FieldMetadata(
      source: FieldSource.inferred,
      confidence: confidence,
      lastUpdated: lastUpdated,
    );
  }

  factory FieldMetadata.fromMap(Map<String, dynamic> map) {
    return FieldMetadata(
      source: FieldSource.fromStorage(map['source'] as String?),
      confidence: _toConfidence(map['confidence']),
      lastUpdated: DateTime.tryParse((map['last_updated'] as String?) ?? ''),
    );
  }

  final FieldSource source;
  final double confidence;
  final DateTime? lastUpdated;

  bool get isUnknown => source == FieldSource.unknown;

  Map<String, dynamic> toMap() {
    return {
      'source': source.name,
      'confidence': confidence.clamp(0, 1).toDouble(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  static double _toConfidence(dynamic raw) {
    if (raw is num) {
      return raw.toDouble().clamp(0, 1).toDouble();
    }
    return 0;
  }
}
