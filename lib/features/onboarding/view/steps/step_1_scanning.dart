import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/onboarding_cubit.dart';
import '../../cubit/onboarding_state.dart';

class Step1Scanning extends StatefulWidget {
  const Step1Scanning({super.key});

  @override
  State<Step1Scanning> createState() => _Step1ScanningState();
}

class _Step1ScanningState extends State<Step1Scanning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingCubit>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.isScanning &&
          !current.isScanning &&
          current.scanError == null,
      listener: (context, state) {
        context.read<OnboardingCubit>().nextStep();
      },
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final specItems = [
            (
              label: 'CPU',
              value: state.scannedSpecs.cpuName,
              isResolved: state.cpuScanned,
            ),
            (
              label: 'GPU',
              value: state.scannedSpecs.gpuName,
              isResolved: state.gpuScanned,
            ),
            (
              label: 'RAM',
              value: '${state.scannedSpecs.ramGb} GB',
              isResolved: state.ramScanned,
            ),
            (
              label: 'Storage',
              value:
                  '${state.scannedSpecs.storageCount} ${state.scannedSpecs.storageType}',
              isResolved: state.storageScanned,
            ),
            (
              label: 'Motherboard',
              value: state.scannedSpecs.motherboard,
              isResolved: state.motherboardScanned,
            ),
          ];
          final resolvedCount = specItems
              .where((item) => item.isResolved)
              .length;
          final progress = resolvedCount / specItems.length;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
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
                                  Chip(
                                    label: Text(
                                      state.isScanning
                                          ? 'Hardware scan in progress'
                                          : 'Scan complete',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.isScanning
                                        ? 'Scanning your system...'
                                        : 'Scan complete',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We are checking your core components and preparing a first-pass power estimate. You can review everything before anything is saved.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          child: LinearProgressIndicator(
                                            minHeight: 10,
                                            value: progress,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '$resolvedCount/${specItems.length}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  Expanded(
                                    // The detected component rows used to be a
                                    // static Column inside this bounded left
                                    // pane, so they forced the parent taller
                                    // than the available scan-card height. The
                                    // scroll view keeps only the component list
                                    // constrained to the remaining space.
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          for (final item in specItems)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              child: _ScanStatusRow(
                                                label: item.label,
                                                value: item.value,
                                                isResolved: item.isResolved,
                                              ),
                                            ),
                                          if (state.scanError != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              state.scanError!,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            FilledButton.tonalIcon(
                                              onPressed: () => context
                                                  .read<OnboardingCubit>()
                                                  .startScan(),
                                              icon: const Icon(
                                                Icons.refresh_rounded,
                                              ),
                                              label: const Text('Retry Scan'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: wide ? 28 : 0,
                              height: wide ? 0 : 24,
                            ),
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: _ScanningVisual(
                                  rotationController: _rotationController,
                                  progress: progress,
                                ),
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
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
}

class _ScanningVisual extends StatelessWidget {
  const _ScanningVisual({
    required this.rotationController,
    required this.progress,
  });

  final AnimationController rotationController;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: rotationController.value * 6.28318,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    value: progress == 0 ? null : progress,
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bolt_rounded, size: 42),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Building your power profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Detected parts will appear one by one so the scan feels transparent instead of guessy.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ScanStatusRow extends StatelessWidget {
  const _ScanStatusRow({
    required this.label,
    required this.value,
    required this.isResolved,
  });

  final String label;
  final String value;
  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isResolved ? Colors.white : const Color(0xFFF6F6F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            isResolved ? Icons.check_circle_rounded : Icons.timelapse_rounded,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  isResolved ? value : 'Detecting...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: isResolved ? FontStyle.normal : FontStyle.italic,
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
