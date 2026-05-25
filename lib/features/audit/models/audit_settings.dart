class AuditSettings {
  const AuditSettings({
    this.schemaVersion = currentSchemaVersion,
    this.autoAuditEnabled = true,
    this.autoAuditIntervalDays = 14,
    this.showTipsOnDashboard = true,
    this.defaultSnoozeDays = 7,
  });

  static const int currentSchemaVersion = 2;

  final int schemaVersion;
  final bool autoAuditEnabled;
  final int autoAuditIntervalDays;
  final bool showTipsOnDashboard;
  final int defaultSnoozeDays;

  factory AuditSettings.fromMap(Map<String, dynamic> map) {
    return AuditSettings(
      schemaVersion: _toInt(map['schema_version']) ?? currentSchemaVersion,
      autoAuditEnabled: (map['auto_audit_enabled'] as bool?) ?? true,
      autoAuditIntervalDays: _toInt(map['auto_audit_interval_days']) ?? 14,
      showTipsOnDashboard: (map['show_tips_on_dashboard'] as bool?) ?? true,
      defaultSnoozeDays: _toInt(map['default_snooze_days']) ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': currentSchemaVersion,
      'auto_audit_enabled': autoAuditEnabled,
      'auto_audit_interval_days': autoAuditIntervalDays.clamp(1, 365),
      'show_tips_on_dashboard': showTipsOnDashboard,
      'default_snooze_days': defaultSnoozeDays.clamp(1, 365),
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
