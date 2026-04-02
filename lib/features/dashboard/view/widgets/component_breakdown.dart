import 'package:flutter/material.dart';

import '../../../../data/models/power_estimate.dart';

class ComponentBreakdown extends StatelessWidget {
  const ComponentBreakdown({
    super.key,
    required this.estimate,
    required this.currencySymbol,
    required this.ratePerKwh,
  });

  final PowerEstimate estimate;
  final String currencySymbol;
  final double ratePerKwh;

  @override
  Widget build(BuildContext context) {
    final rows = estimate.components
        .map(
          (component) => _ComponentRowData(
            label: component.label,
            estimatedWatts: component.estimatedWatts,
            peakWatts: component.peakWatts,
            icon: _iconForKey(component.key),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Component breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'See which parts make up the bulk of your typical estimated draw, plus the saved peak hardware values behind it.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RowTile(
                  data: row,
                  totalWatts: estimate.estimatedWatts,
                  costPerHour: (row.estimatedWatts / 1000) * ratePerKwh,
                  currencySymbol: currencySymbol,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.data,
    required this.totalWatts,
    required this.costPerHour,
    required this.currencySymbol,
  });

  final _ComponentRowData data;
  final double totalWatts;
  final double costPerHour;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final ratio = totalWatts == 0 ? 0.0 : data.estimatedWatts / totalWatts;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${(ratio * 100).toStringAsFixed(1)}% of total load',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.estimatedWatts.toStringAsFixed(0)} W est',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${data.peakWatts.toStringAsFixed(0)} W peak | $currencySymbol${costPerHour.toStringAsFixed(2)}/hr',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: ratio,
              backgroundColor: const Color(0xFFE9E9E6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentRowData {
  const _ComponentRowData({
    required this.label,
    required this.estimatedWatts,
    required this.peakWatts,
    required this.icon,
  });

  final String label;
  final double estimatedWatts;
  final double peakWatts;
  final IconData icon;
}

IconData _iconForKey(String key) {
  switch (key) {
    case 'cpu':
      return Icons.memory_rounded;
    case 'gpu':
      return Icons.videogame_asset_rounded;
    case 'ram':
      return Icons.storage_rounded;
    case 'storage':
      return Icons.save_rounded;
    case 'fans':
      return Icons.air_rounded;
    case 'rgb':
      return Icons.light_mode_rounded;
    case 'motherboard':
      return Icons.developer_board_rounded;
    default:
      return Icons.bolt_rounded;
  }
}
