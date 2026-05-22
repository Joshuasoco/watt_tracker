import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/onboarding_cubit.dart';
import '../../cubit/onboarding_state.dart';

class Step3Terms extends StatelessWidget {
  const Step3Terms({super.key, required this.onAgree});

  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 720;

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
                                  avatar: Icon(Icons.info_outline_rounded),
                                  label: Text('Transparency first'),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Before we continue',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'WattWise estimates your electricity cost based on typical hardware wattage values. Results are approximate and not a substitute for a certified energy meter. Actual consumption may vary.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F3F1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      _BulletLine(
                                        text:
                                            'This is an estimate, not a hardware meter reading.',
                                      ),
                                      _BulletLine(
                                        text:
                                            'Manual corrections are available if detection misses something.',
                                      ),
                                      _BulletLine(
                                        text:
                                            'Your setup stays local to this device.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: const Text(
                                    'I understand this is an estimate',
                                  ),
                                  value: state.termsAccepted,
                                  onChanged: (value) {
                                    context
                                        .read<OnboardingCubit>()
                                        .setTermsAccepted(value ?? false);
                                  },
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: state.termsAccepted
                                      ? onAgree
                                      : null,
                                  child: const Text('Agree & Continue'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: wide ? 26 : 0, height: wide ? 0 : 24),
                          const Expanded(flex: 5, child: _TermsSidePanel()),
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

class _TermsSidePanel extends StatelessWidget {
  const _TermsSidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this matters',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          const _PanelPoint(
            title: 'Keeps expectations realistic',
            body:
                'The dashboard reflects modeled power draw, not direct wall-meter measurements.',
          ),
          const _PanelPoint(
            title: 'Protects trust in the numbers',
            body:
                'We would rather be explicit now than let the dashboard feel deceptively precise later.',
          ),
        ],
      ),
    );
  }
}

class _PanelPoint extends StatelessWidget {
  const _PanelPoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
