import 'package:flutter/material.dart';

class CostTicker extends StatelessWidget {
  const CostTicker({
    super.key,
    required this.currencySymbol,
    required this.totalCost,
    required this.costPerSecond,
    required this.estimatedWatts,
    required this.uncalibratedWatts,
    required this.peakWatts,
    required this.confidenceLabel,
    required this.usageProfileLabel,
    required this.calibrationLabel,
    required this.elapsedSeconds,
    required this.isRunning,
  });

  final String currencySymbol;
  final double totalCost;
  final double costPerSecond;
  final double estimatedWatts;
  final double uncalibratedWatts;
  final double peakWatts;
  final String confidenceLabel;
  final String usageProfileLabel;
  final String calibrationLabel;
  final int elapsedSeconds;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A), Color(0xFF474747)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: _GlowCircle(
              color: Colors.white.withOpacity(0.08),
              size: 170,
            ),
          ),
          Positioned(
            left: -20,
            bottom: -42,
            child: _GlowCircle(color: Colors.white.withOpacity(0.1), size: 190),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatusChip(
                    icon: isRunning
                        ? Icons.play_circle_fill_rounded
                        : Icons.pause_circle_filled_rounded,
                    label: isRunning ? 'Live session' : 'Paused session',
                  ),
                  _StatusChip(
                    icon: Icons.memory_rounded,
                    label:
                        '${estimatedWatts.toStringAsFixed(0)} W estimated draw',
                  ),
                  _StatusChip(
                    icon: Icons.tune_rounded,
                    label: usageProfileLabel,
                  ),
                  _StatusChip(
                    icon: Icons.verified_user_rounded,
                    label: '$confidenceLabel confidence',
                  ),
                  _StatusChip(
                    icon: Icons.straighten_rounded,
                    label: calibrationLabel,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: totalCost),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Text(
                    '$currencySymbol${value.toStringAsFixed(4)}',
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                '$currencySymbol${costPerSecond.toStringAsFixed(4)} per second',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.86),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MicroStat(
                    label: 'Elapsed',
                    value: _formatDuration(elapsedSeconds),
                  ),
                  _MicroStat(
                    label: 'Hardware ceiling',
                    value: '${peakWatts.toStringAsFixed(0)} W',
                  ),
                  _MicroStat(
                    label: 'Model baseline',
                    value: '${uncalibratedWatts.toStringAsFixed(0)} W',
                  ),
                  _MicroStat(
                    label: 'Runtime state',
                    value: isRunning ? 'Accumulating' : 'On hold',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This live ticker updates every second using your saved hardware profile, selected usage profile, manual calibration if available, and electricity rate.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
