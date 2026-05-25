import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/onboarding_cubit.dart';

class Step4Rate extends StatefulWidget {
  const Step4Rate({super.key, required this.onContinue});

  final void Function(double rate, String symbol) onContinue;

  @override
  State<Step4Rate> createState() => _Step4RateState();
}

class _Step4RateState extends State<Step4Rate> {
  late final TextEditingController _symbolController;
  late final TextEditingController _rateController;
  bool _showRateHelp = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingCubit>().state;
    _symbolController = TextEditingController(text: state.currencySymbol);
    _rateController = TextEditingController(
      text: state.electricityRate.toStringAsFixed(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsedRate = double.tryParse(_rateController.text.trim()) ?? 0;
    final symbol = _symbolController.text.trim().isEmpty
        ? '\u20B1'
        : _symbolController.text.trim();

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
                              avatar: Icon(Icons.receipt_long_rounded),
                              label: Text('Billing input'),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "What's your electricity rate?",
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Use the price from your latest electric bill. This becomes the foundation for every live and projected cost number in the app.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _symbolController,
                              maxLength: 4,
                              decoration: const InputDecoration(
                                labelText: 'Currency symbol',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Rate',
                                hintText: 'e.g. 13.47',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            _RateHelpHint(
                              expanded: _showRateHelp,
                              onToggle: () => setState(
                                () => _showRateHelp = !_showRateHelp,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: parsedRate > 0
                                  ? () => widget.onContinue(parsedRate, symbol)
                                  : null,
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 24),
                      Expanded(
                        flex: 5,
                        child: _RatePreview(
                          symbol: symbol,
                          parsedRate: parsedRate,
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

  @override
  void dispose() {
    _symbolController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}

class _RateHelpHint extends StatelessWidget {
  const _RateHelpHint({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          label: const Text('How to find your rate'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        "On your Meralco bill, look for 'Total Amount Due' "
                        "divided by 'kWh Consumed'. For other utilities "
                        '(VECO, BENECO, etc.) the same method applies. The '
                        'blended rate is typically \u20B110\u2013\u20B113/kWh.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _RatePreview extends StatelessWidget {
  const _RatePreview({required this.symbol, required this.parsedRate});

  final String symbol;
  final double parsedRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF353535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            'At this rate, 1 kWh costs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$symbol${parsedRate.toStringAsFixed(2)}',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'Small changes here noticeably affect every estimate, so it is worth using the exact bill number when you have it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}
