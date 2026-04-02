import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/power_estimate.dart';
import '../../../../data/models/usage_profile.dart';
import '../../../../data/services/power_estimation_service.dart';
import '../../cubit/onboarding_cubit.dart';
import '../../cubit/onboarding_state.dart';

class Step6Complete extends StatefulWidget {
  const Step6Complete({super.key, required this.onStartTracking});

  final Future<void> Function() onStartTracking;

  @override
  State<Step6Complete> createState() => _Step6CompleteState();
}

class _Step6CompleteState extends State<Step6Complete> {
  bool _expanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _expanded = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final estimate = const PowerEstimationService().estimate(
          spec: state.confirmedSpecs,
          ratePerKwh: state.electricityRate,
          dailyHours: state.dailyHours,
          usageProfile: state.usageProfile,
        );
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;

                      return Flex(
                        direction: wide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  width: _expanded ? 104 : 52,
                                  height: _expanded ? 104 : 52,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Chip(
                                  avatar: Icon(Icons.verified_rounded),
                                  label: Text('Setup complete'),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  "You're all set!",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your first power profile is ready. You can start tracking now, then fine-tune any assumptions later in settings if your setup changes.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 24),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _SummaryTile(
                                      label: 'CPU',
                                      value: state.confirmedSpecs.cpuName,
                                      icon: Icons.memory_rounded,
                                    ),
                                    _SummaryTile(
                                      label: 'Estimated draw',
                                      value:
                                          '${estimate.estimatedWatts.toStringAsFixed(0)} W',
                                      icon: Icons.bolt_rounded,
                                    ),
                                    _SummaryTile(
                                      label: 'Rate',
                                      value:
                                          '${state.currencySymbol}${state.electricityRate.toStringAsFixed(2)}/kWh',
                                      icon: Icons.receipt_long_rounded,
                                    ),
                                    _SummaryTile(
                                      label: 'Usage profile',
                                      value: state.usageProfile.shortLabel,
                                      icon: Icons.tune_rounded,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () async {
                                          setState(() => _saving = true);
                                          await widget.onStartTracking();
                                          if (mounted) {
                                            setState(() => _saving = false);
                                          }
                                        },
                                  icon: Icon(
                                    _saving
                                        ? Icons.sync_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    _saving ? 'Saving...' : 'Start Tracking',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: wide ? 26 : 0, height: wide ? 0 : 24),
                          Expanded(
                            flex: 6,
                            child: _ReadyPanel(
                              estimatedWatts: estimate.estimatedWatts,
                              confidenceLabel: estimate.confidence.label,
                              profileLabel: state.usageProfile.label,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({
    required this.estimatedWatts,
    required this.confidenceLabel,
    required this.profileLabel,
  });

  final double estimatedWatts;
  final String confidenceLabel;
  final String profileLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What happens next',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          _PanelItem(
            icon: Icons.toll_rounded,
            title: 'Live ticker starts immediately',
            subtitle:
                'Watch your running electricity spend update every second.',
          ),
          _PanelItem(
            icon: Icons.auto_graph_rounded,
            title: '${estimatedWatts.toStringAsFixed(0)} W estimated draw',
            subtitle:
                'Your dashboard turns that profile into hourly, daily, and monthly views.',
          ),
          _PanelItem(
            icon: Icons.verified_user_rounded,
            title: '$confidenceLabel confidence estimate',
            subtitle: 'Usage profile: $profileLabel',
          ),
          _PanelItem(
            icon: Icons.tune_rounded,
            title: 'You can adjust later',
            subtitle:
                'Rate, hours, and detected hardware can all be refined after setup.',
          ),
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  const _PanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
