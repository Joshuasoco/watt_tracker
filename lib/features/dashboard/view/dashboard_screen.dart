import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/window_close_handler.dart';
import '../../../data/models/power_estimate.dart';
import '../../../data/models/usage_profile.dart';
import '../../../data/repositories/wattage_repository.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/tray_service.dart';
import '../cubit/live_timer_cubit.dart';
import '../cubit/live_timer_state.dart';
import 'widgets/component_breakdown.dart';
import 'widgets/cost_ticker.dart';
import 'widgets/estimate_cards.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WindowListener, WindowCloseHandler<DashboardScreen> {
  late final LiveTimerCubit _timerCubit;
  late final WattwisePrefsRepository _prefsRepository;
  late final WattageRepository _wattageRepository;
  bool _trackingActivated = false;
  bool _hasPriorSession = false;
  bool _hasActivatedTrackingBefore = false;

  @override
  void initState() {
    super.initState();
    _timerCubit = context.read<LiveTimerCubit>();
    _prefsRepository = WattwisePrefsRepository();
    _wattageRepository = WattageRepository();
    _timerCubit.reloadPreferences();
    _trackingActivated = TrayService().isInitialized;
    _hasPriorSession = _wattageRepository.getSavedSessions().isNotEmpty;
    _hasActivatedTrackingBefore = _prefsRepository.trackingActivatedOnce;
    initCloseHandler(_timerCubit);
  }

  Future<void> _handleTrackingToggle() async {
    if (_trackingActivated) {
      _timerCubit.pauseTimer();
      await TrayService().dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _trackingActivated = false;
      });
      return;
    }

    _timerCubit.startTimer();
    await TrayService().init(_timerCubit);
    await _prefsRepository.markTrackingActivated();

    if (!mounted) {
      return;
    }

    setState(() {
      _trackingActivated = true;
      _hasActivatedTrackingBefore = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking active - you can close this window safely.'),
      ),
    );
  }

  void _handlePauseResume() {
    if (!_trackingActivated) {
      return;
    }

    if (_timerCubit.state.isRunning) {
      _timerCubit.pauseTimer();
    } else {
      _timerCubit.startTimer();
    }
  }

  void _handleReset() {
    _timerCubit.resetTimer();
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
      unawaited(windowManager.setPreventClose(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTimerCubit, LiveTimerState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.spec.cpuName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Live electricity tracking for this machine',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Chip(
                  label: Text(state.spec.chassisType.replaceAll('_', ' ')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.push('/audit'),
                icon: const Icon(Icons.insights_rounded),
                tooltip: 'Run energy audit',
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 900;
                    final showFirstActivationBanner =
                        !state.isRunning &&
                        !_trackingActivated &&
                        !_hasPriorSession &&
                        !_hasActivatedTrackingBefore;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _TrackingStatusChip(isRunning: state.isRunning),
                            _TopPill(
                              icon: Icons.schedule_rounded,
                              label:
                                  '${state.dailyHours.toStringAsFixed(1)} hrs/day',
                            ),
                            _TopPill(
                              icon: Icons.receipt_long_rounded,
                              label:
                                  '${state.currencySymbol}${state.ratePerKwh.toStringAsFixed(2)}/kWh',
                            ),
                            _TopPill(
                              icon: Icons.tune_rounded,
                              label: state.usageProfile.shortLabel,
                            ),
                            _TopPill(
                              icon: Icons.verified_user_rounded,
                              label: state.estimate.confidence.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _handleTrackingToggle,
                              style: FilledButton.styleFrom(
                                backgroundColor: _trackingActivated
                                    ? const Color(0x331D9E75)
                                    : const Color(0xFF1D9E75),
                                foregroundColor: _trackingActivated
                                    ? const Color(0xFF156A4F)
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              icon: Icon(
                                _trackingActivated
                                    ? Icons.stop_circle_outlined
                                    : Icons.bolt_rounded,
                              ),
                              label: Text(
                                _trackingActivated
                                    ? 'Stop Tracking'
                                    : 'Activate Tracking',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/audit'),
                              icon: const Icon(Icons.analytics_outlined),
                              label: const Text('Run energy audit'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _trackingActivated
                                  ? _handlePauseResume
                                  : null,
                              icon: Icon(
                                state.isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              label: Text(
                                state.isRunning
                                    ? 'Pause session'
                                    : 'Resume session',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  state.elapsedSeconds > 0 ||
                                      state.totalCostAccumulated > 0
                                  ? _handleReset
                                  : null,
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset session'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (showFirstActivationBanner) ...[
                          const _FirstTrackingBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 10,
                                child: CostTicker(
                                  currencySymbol: state.currencySymbol,
                                  totalCost: state.totalCostAccumulated,
                                  costPerSecond: state.costPerSecond,
                                  estimatedWatts: state.estimate.estimatedWatts,
                                  uncalibratedWatts:
                                      state.estimate.uncalibratedWatts,
                                  peakWatts: state.estimate.peakWatts,
                                  confidenceLabel:
                                      state.estimate.confidence.label,
                                  usageProfileLabel: state.usageProfile.label,
                                  // Falls back to "Model only" whenever the
                                  // Windows CPU poller stops or reports an
                                  // invalid Win32_Processor.LoadPercentage.
                                  loadSourceLabel: state.isLiveLoadActive
                                      ? 'Live load'
                                      : 'Model only',
                                  liveCpuLoadPercent: state.liveCpuLoadPercent,
                                  elapsedSeconds: state.elapsedSeconds,
                                  isRunning: state.isRunning,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _DashboardContextPanel(
                                  state: state,
                                  trackingActivated: _trackingActivated,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          CostTicker(
                            currencySymbol: state.currencySymbol,
                            totalCost: state.totalCostAccumulated,
                            costPerSecond: state.costPerSecond,
                            estimatedWatts: state.estimate.estimatedWatts,
                            uncalibratedWatts: state.estimate.uncalibratedWatts,
                            peakWatts: state.estimate.peakWatts,
                            confidenceLabel: state.estimate.confidence.label,
                            usageProfileLabel: state.usageProfile.label,
                            // Falls back to "Model only" whenever the
                            // Windows CPU poller stops or reports an invalid
                            // Win32_Processor.LoadPercentage.
                            loadSourceLabel: state.isLiveLoadActive
                                ? 'Live load'
                                : 'Model only',
                            liveCpuLoadPercent: state.liveCpuLoadPercent,
                            elapsedSeconds: state.elapsedSeconds,
                            isRunning: state.isRunning,
                          ),
                          const SizedBox(height: 14),
                          _DashboardContextPanel(
                            state: state,
                            trackingActivated: _trackingActivated,
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          'Projection snapshot',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        EstimateCards(
                          currencySymbol: state.currencySymbol,
                          perHour: state.perHour,
                          perDay: state.perDay,
                          perMonth: state.perMonth,
                        ),
                        const SizedBox(height: 22),
                        ComponentBreakdown(
                          estimate: state.estimate,
                          currencySymbol: state.currencySymbol,
                          ratePerKwh: state.ratePerKwh,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FirstTrackingBanner extends StatelessWidget {
  const _FirstTrackingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7DCCE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF156A4F),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tracking is ready — press Activate Tracking to start your first session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF156A4F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContextPanel extends StatelessWidget {
  const _DashboardContextPanel({
    required this.state,
    required this.trackingActivated,
  });

  final LiveTimerState state;
  final bool trackingActivated;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session context',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _ContextRow(
              label: 'Elapsed',
              value: _formatDuration(state.elapsedSeconds),
            ),
            _ContextRow(
              label: 'Power profile',
              value:
                  '${state.estimate.estimatedWatts.toStringAsFixed(0)} W typical',
            ),
            _ContextRow(
              label: 'Calibration',
              value: state.estimate.isCalibrated
                  ? '${state.estimate.calibrationFactor.toStringAsFixed(2)}x'
                  : 'Not set',
            ),
            _ContextRow(
              label: 'Usage profile',
              value: state.usageProfile.label,
            ),
            _ContextRow(
              label: 'Confidence',
              value: state.estimate.confidence.label,
            ),
            _ContextRow(
              label: 'Today estimate',
              value:
                  '${state.currencySymbol}${state.perDay.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How this is calculated',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.estimate.formula,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Updated ${_formatTimestamp(state.estimate.generatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final reason in state.estimate.confidenceReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $reason',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _CalibrationEntryPoint(
                    isCalibrated: state.estimate.isCalibrated,
                    onPressed: () => context.push('/settings'),
                  ),
                  if (state.estimate.confidence != EstimateConfidence.high) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Improve estimate'),
                      ),
                    ),
                  ],
                  if (!state.estimate.isCalibrated ||
                      state.estimate.confidence != EstimateConfidence.high)
                    const SizedBox(height: 8),
                  Text(
                    _buildMessage(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMessage() {
    if (!trackingActivated) {
      return 'Tracking is inactive. Activate it to create a tray icon and keep WattWise alive after closing the window.';
    }

    if (state.isRunning) {
      return 'Tracking is currently live. You can close the window and WattWise will keep updating from the system tray.';
    }

    return 'Tracking stays armed in the tray while paused. Resume whenever you want the live cost ticker to continue.';
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

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day}/${local.year} $hh:$mm';
  }
}

class _CalibrationEntryPoint extends StatelessWidget {
  const _CalibrationEntryPoint({
    required this.isCalibrated,
    required this.onPressed,
  });

  final bool isCalibrated;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCalibrated) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Calibrated · Edit'),
        ),
      );
    }

    const accentColor = Color(0xFF7A5A00);
    const highlightColor = Color(0xFFFFF8E8);
    const borderColor = Color(0xFFE2C56E);

    return Material(
      color: highlightColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Calibrate for better accuracy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Takes 30 seconds with a plug-in watt meter',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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

class _TrackingStatusChip extends StatelessWidget {
  const _TrackingStatusChip({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isRunning
        ? const Color(0xFFE0F4EC)
        : const Color(0xFFE6E7EB);
    final foregroundColor = isRunning
        ? const Color(0xFF156A4F)
        : const Color(0xFF4B5563);

    return Chip(
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      avatar: Icon(
        isRunning ? Icons.bolt_rounded : Icons.pause_circle_filled_rounded,
        color: foregroundColor,
        size: 18,
      ),
      label: Text(
        isRunning ? 'Tracking' : 'Paused',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
