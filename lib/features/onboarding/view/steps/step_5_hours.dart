import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/usage_profile.dart';
import '../../cubit/onboarding_cubit.dart';

class Step5Hours extends StatefulWidget {
  const Step5Hours({super.key, required this.onContinue});

  final void Function(double hours, UsageProfile usageProfile) onContinue;

  @override
  State<Step5Hours> createState() => _Step5HoursState();
}

class _Step5HoursState extends State<Step5Hours> {
  late double _hours;
  late UsageProfile _usageProfile;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingCubit>().state;
    _hours = state.dailyHours;
    _usageProfile = state.usageProfile;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 700;

                  return Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Chip(
                              avatar: Icon(Icons.schedule_rounded),
                              label: Text('Usage pattern'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How many hours a day do you use this device?',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This helps shape your daily and monthly projections. Think in terms of typical usage, not your heaviest day.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'What best matches this PC most days?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: UsageProfile.values.map((profile) {
                                final selected = profile == _usageProfile;
                                return ChoiceChip(
                                  label: Text(profile.label),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() => _usageProfile = profile);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _usageProfile.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    _hours.toStringAsFixed(1),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displayLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'hours per day',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Slider(
                              value: _hours,
                              min: 1,
                              max: 24,
                              divisions: 46,
                              label: _hours.toStringAsFixed(1),
                              onChanged: (value) =>
                                  setState(() => _hours = value),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () =>
                                  widget.onContinue(_hours, _usageProfile),
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 24),
                      Expanded(
                        flex: 5,
                        child: _HoursGuide(
                          hours: _hours,
                          usageProfile: _usageProfile,
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
  }
}

class _HoursGuide extends StatelessWidget {
  const _HoursGuide({required this.hours, required this.usageProfile});

  final double hours;
  final UsageProfile usageProfile;

  @override
  Widget build(BuildContext context) {
    final profile = hours < 4
        ? 'Light use'
        : hours < 9
        ? 'Regular use'
        : hours < 15
        ? 'Heavy use'
        : 'Always-on use';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usage readout', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Text(profile, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Used for daily and monthly cost projections. You can update this later if your routine changes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _GuideRow(label: 'Selected profile', text: usageProfile.shortLabel),
          const SizedBox(height: 16),
          const _GuideRow(
            label: '1-4 hrs',
            text: 'Quick checks, office tasks, occasional gaming',
          ),
          const _GuideRow(
            label: '5-8 hrs',
            text: 'Typical daily workstation or home use',
          ),
          const _GuideRow(
            label: '9-14 hrs',
            text: 'Long sessions, streaming, or heavy productivity',
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
