import 'package:equatable/equatable.dart';

import 'audit_finding.dart';
import 'audit_tip.dart';
import 'component_cost_breakdown.dart';

class EnergyAuditResult extends Equatable {
  const EnergyAuditResult({
    required this.id,
    required this.createdAt,
    required this.specSnapshot,
    required this.ratePerKwh,
    required this.currencySymbol,
    required this.dailyHours,
    required this.totalWatts,
    required this.totalMonthlyCost,
    required this.confidence,
    required this.breakdowns,
    required this.findings,
    required this.tips,
    required this.dataCompleteness,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> specSnapshot;
  final double ratePerKwh;
  final String currencySymbol;
  final double dailyHours;
  final double totalWatts;
  final double totalMonthlyCost;
  final String confidence;
  final List<ComponentCostBreakdown> breakdowns;
  final List<AuditFinding> findings;
  final List<AuditTip> tips;
  final double dataCompleteness;

  bool get hasFindings => findings.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result_state': hasFindings ? 'findings' : 'no_findings',
      'created_at': createdAt.toIso8601String(),
      'spec_snapshot': specSnapshot,
      'rate_per_kwh': ratePerKwh,
      'currency_symbol': currencySymbol,
      'daily_hours': dailyHours,
      'total_watts': totalWatts,
      'total_monthly_cost': totalMonthlyCost,
      'confidence': confidence,
      'breakdowns': breakdowns.map((item) => item.toMap()).toList(),
      'findings': findings.map((item) => item.toMap()).toList(),
      'tips': tips.map((item) => item.toMap()).toList(),
      'data_completeness': dataCompleteness,
    };
  }

  factory EnergyAuditResult.fromMap(Map<String, dynamic> map) {
    return EnergyAuditResult(
      id: (map['id'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      specSnapshot: _toMap(map['spec_snapshot']),
      ratePerKwh: _toDouble(map['rate_per_kwh']),
      currencySymbol: (map['currency_symbol'] as String?) ?? '\u20B1',
      dailyHours: _toDouble(map['daily_hours']),
      totalWatts: _toDouble(map['total_watts']),
      totalMonthlyCost: _toDouble(map['total_monthly_cost']),
      confidence: (map['confidence'] as String?) ?? 'low',
      breakdowns: _toBreakdowns(map['breakdowns']),
      findings: _toFindings(map['findings']),
      tips: _toTips(map['tips']),
      dataCompleteness: _toDouble(map['data_completeness']),
    );
  }

  static Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  static double _toDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    return 0;
  }

  static List<ComponentCostBreakdown> _toBreakdowns(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) =>
                ComponentCostBreakdown.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }
    return const <ComponentCostBreakdown>[];
  }

  static List<AuditFinding> _toFindings(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => AuditFinding.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    return const <AuditFinding>[];
  }

  static List<AuditTip> _toTips(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => AuditTip.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    return const <AuditTip>[];
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    specSnapshot,
    ratePerKwh,
    currencySymbol,
    dailyHours,
    totalWatts,
    totalMonthlyCost,
    confidence,
    breakdowns,
    findings,
    tips,
    dataCompleteness,
  ];
}
