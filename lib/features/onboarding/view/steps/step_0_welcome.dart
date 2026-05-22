import 'package:flutter/material.dart';

class Step0Welcome extends StatelessWidget {
  const Step0Welcome({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;

              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, const Color(0xFFF0F0EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: scheme.outline),
                ),
                child: Padding(
                  padding: EdgeInsets.all(wide ? 36 : 24),
                  child: Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Chip(
                              avatar: Icon(
                                Icons.desktop_windows_rounded,
                                size: 18,
                              ),
                              label: Text('Desktop Power Audit'),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Know what your PC really costs.',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'WattWise scans your hardware, estimates power draw, and turns it into a live electricity cost ticker you can actually understand.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                            const Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _BenefitChip(
                                  icon: Icons.memory_rounded,
                                  label: 'Auto-detect hardware',
                                ),
                                _BenefitChip(
                                  icon: Icons.bolt_rounded,
                                  label: 'Live cost tracking',
                                ),
                                _BenefitChip(
                                  icon: Icons.lock_outline_rounded,
                                  label: 'Stored locally on device',
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: onNext,
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Text('Start Setup'),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Takes about a minute',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: wide ? 28 : 0, height: wide ? 0 : 24),
                      Expanded(
                        flex: 8,
                        child: _WelcomePreviewCard(isWide: wide),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _WelcomePreviewCard extends StatelessWidget {
  const _WelcomePreviewCard({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: isWide ? 420 : 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A), Color(0xFF484848)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: _GlowOrb(
              color: Colors.white.withValues(alpha: 0.08),
              size: 180,
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: _GlowOrb(
              color: Colors.white.withValues(alpha: 0.12),
              size: 200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 46, color: Colors.white),
                const Spacer(),
                Text(
                  'From hardware scan to live cost in one flow.',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                const _PreviewRow(
                  label: 'Scan',
                  description: 'CPU, GPU, RAM, storage, motherboard',
                ),
                const _PreviewRow(
                  label: 'Tune',
                  description: 'Rate, daily hours, hardware corrections',
                ),
                const _PreviewRow(
                  label: 'Track',
                  description: 'Live ticker, daily estimate, monthly cost',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label.substring(0, 1),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

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
