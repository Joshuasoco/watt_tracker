import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/power_estimate.dart';
import '../../../data/models/system_spec_model.dart';
import '../../../data/models/usage_profile.dart';
import '../../../data/repositories/wattage_preset_repository.dart';
import '../../../data/repositories/wattwise_prefs_repository.dart';
import '../../../data/services/power_estimation_service.dart';
import '../../../data/services/tray_service.dart';
import '../../dashboard/cubit/live_timer_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final WattwisePrefsRepository _prefsRepository;
  final WattagePresetRepository _presetRepository = WattagePresetRepository();
  late final TextEditingController _currencyController;
  late final TextEditingController _rateController;
  late final TextEditingController _hoursController;
  late final TextEditingController _milestoneController;
  late UsageProfile _usageProfile;

  @override
  void initState() {
    super.initState();
    _prefsRepository = WattwisePrefsRepository();
    _currencyController = TextEditingController(
      text: _prefsRepository.currencySymbol,
    );
    _rateController = TextEditingController(
      text: _prefsRepository.electricityRate.toStringAsFixed(2),
    );
    _hoursController = TextEditingController(
      text: _prefsRepository.dailyHours.toStringAsFixed(1),
    );
    _usageProfile = _prefsRepository.usageProfile;
    _milestoneController = TextEditingController(
      text: _prefsRepository.sessionMilestoneHours.toStringAsFixed(1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate =
        double.tryParse(_rateController.text.trim()) ??
        _prefsRepository.electricityRate;
    final hours =
        double.tryParse(_hoursController.text.trim()) ??
        _prefsRepository.dailyHours;
    final symbol = _currencyController.text.trim().isEmpty
        ? '\u20B1'
        : _currencyController.text.trim();
    final milestone =
        double.tryParse(_milestoneController.text.trim()) ??
        _prefsRepository.sessionMilestoneHours;
    final spec = _resolvedSpec();
    final estimate = const PowerEstimationService().estimate(
      spec: spec,
      ratePerKwh: rate,
      dailyHours: hours,
      usageProfile: _usageProfile,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 920;
                final primaryPanel = _SettingsPrimaryPanel(
                  currencyController: _currencyController,
                  rateController: _rateController,
                  hoursController: _hoursController,
                  milestoneController: _milestoneController,
                  milestone: milestone,
                  onChanged: () => setState(() {}),
                  usageProfile: _usageProfile,
                  onUsageProfileChanged: (value) {
                    setState(() => _usageProfile = value);
                  },
                  onSave: _save,
                  onMilestoneChanged: _handleMilestoneChanged,
                  onRunAudit: () => context.push('/audit'),
                  onBackToDashboard: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  onRestartOnboarding: _restartOnboarding,
                );
                final secondaryPanel = _SettingsSecondaryPanel(
                  symbol: symbol,
                  rate: rate,
                  hours: hours,
                  estimate: estimate,
                  milestoneHours: milestone,
                  spec: spec,
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 8,
                        child: SingleChildScrollView(child: primaryPanel),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(child: secondaryPanel),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primaryPanel,
                      const SizedBox(height: 16),
                      secondaryPanel,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  SystemSpecModel _resolvedSpec() {
    final saved = _prefsRepository.systemSpec;
    return saved.copyWith(
      cpuTdpWatts: _presetRepository.resolveCpuTdp(saved.cpuName),
      gpuWatts: _presetRepository.resolveGpuWatts(saved.gpuName, saved.gpuType),
      storageWattsEach: saved.storageType == 'HDD' ? 7 : 3,
      rgbWatts: saved.hasRgb ? 10 : 0,
    );
  }

  Future<void> _save() async {
    final rate = double.tryParse(_rateController.text.trim());
    final hours = double.tryParse(_hoursController.text.trim());
    final symbol = _currencyController.text.trim();

    if (rate == null || rate <= 0 || hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values.')),
      );
      return;
    }

    await _prefsRepository.saveUsagePreferences(
      electricityRate: rate,
      currencySymbol: symbol,
      dailyHours: hours,
      usageProfile: _usageProfile,
    );

    if (!mounted) {
      return;
    }

    context.read<LiveTimerCubit>().reloadPreferences();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved.')));
  }

  Future<void> _handleMilestoneChanged(String value) async {
    setState(() {});
    final hours = double.tryParse(value.trim());
    if (hours == null) {
      return;
    }

    await _prefsRepository.saveSessionMilestoneHours(hours);
    if (!mounted) {
      return;
    }

    context.read<LiveTimerCubit>().reloadPreferences();
  }

  Future<void> _restartOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restart onboarding?'),
          content: const Text(
            'This clears your saved hardware and setup preferences so the app opens the onboarding flow again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restart'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await TrayService().dispose();

    if (!mounted) {
      return;
    }

    context.read<LiveTimerCubit>().resetTimer();
    await _prefsRepository.resetOnboarding();

    if (!mounted) {
      return;
    }

    context.read<LiveTimerCubit>().reloadPreferences();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Onboarding reset.')));
    context.go('/onboarding');
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _rateController.dispose();
    _hoursController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }
}

class _SettingsPrimaryPanel extends StatelessWidget {
  const _SettingsPrimaryPanel({
    required this.currencyController,
    required this.rateController,
    required this.hoursController,
    required this.milestoneController,
    required this.milestone,
    required this.onChanged,
    required this.usageProfile,
    required this.onUsageProfileChanged,
    required this.onSave,
    required this.onMilestoneChanged,
    required this.onRunAudit,
    required this.onBackToDashboard,
    required this.onRestartOnboarding,
  });

  final TextEditingController currencyController;
  final TextEditingController rateController;
  final TextEditingController hoursController;
  final TextEditingController milestoneController;
  final double milestone;
  final VoidCallback onChanged;
  final UsageProfile usageProfile;
  final ValueChanged<UsageProfile> onUsageProfileChanged;
  final VoidCallback onSave;
  final ValueChanged<String> onMilestoneChanged;
  final VoidCallback onRunAudit;
  final VoidCallback onBackToDashboard;
  final VoidCallback onRestartOnboarding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Chip(
                  avatar: Icon(Icons.tune_rounded),
                  label: Text('Tracking preferences'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fine-tune your numbers',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'These values affect the live dashboard and all forward-looking cost projections.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currencyController,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Currency symbol',
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Electricity rate',
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Daily hours'),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UsageProfile>(
                  initialValue: usageProfile,
                  decoration: const InputDecoration(labelText: 'Usage profile'),
                  items: UsageProfile.values
                      .map(
                        (profile) => DropdownMenuItem<UsageProfile>(
                          value: profile,
                          child: Text(profile.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    onUsageProfileChanged(value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  usageProfile.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onSave,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use 0 hours if you want to disable milestone alerts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Session milestone alert'),
                  subtitle: Text(
                    'Notify me after ${milestone.toStringAsFixed(1)} hours of tracking',
                  ),
                  trailing: SizedBox(
                    width: 92,
                    child: TextField(
                      controller: milestoneController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        isDense: true,
                        suffixText: 'hrs',
                      ),
                      onChanged: onMilestoneChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset setup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Restart onboarding if your hardware changed or if you want to rescan the device from scratch.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onRunAudit,
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Run Audit Again'),
                    ),
                    OutlinedButton(
                      onPressed: onRestartOnboarding,
                      child: const Text('Restart Onboarding'),
                    ),
                    OutlinedButton(
                      onPressed: onBackToDashboard,
                      child: const Text('Back to Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSecondaryPanel extends StatelessWidget {
  const _SettingsSecondaryPanel({
    required this.symbol,
    required this.rate,
    required this.hours,
    required this.estimate,
    required this.milestoneHours,
    required this.spec,
  });

  final String symbol;
  final double rate;
  final double hours;
  final PowerEstimate estimate;
  final double milestoneHours;
  final SystemSpecModel spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsPreviewCard(
          symbol: symbol,
          rate: rate,
          hours: hours,
          estimate: estimate,
          milestoneHours: milestoneHours,
        ),
        const SizedBox(height: 16),
        _HardwareSummaryCard(spec: spec),
      ],
    );
  }
}

class _SettingsPreviewCard extends StatelessWidget {
  const _SettingsPreviewCard({
    required this.symbol,
    required this.rate,
    required this.hours,
    required this.estimate,
    required this.milestoneHours,
  });

  final String symbol;
  final double rate;
  final double hours;
  final PowerEstimate estimate;
  final double milestoneHours;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              'As you edit your settings, this shows the current model the dashboard will use.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _PreviewRow(
              label: 'Usage profile',
              value: estimate.usageProfile.label,
            ),
            _PreviewRow(
              label: 'Estimated draw',
              value:
                  '${estimate.estimatedWatts.toStringAsFixed(0)} W (${estimate.peakWatts.toStringAsFixed(0)} W peak)',
            ),
            _PreviewRow(
              label: 'Rate',
              value: '$symbol${rate.toStringAsFixed(2)}/kWh',
            ),
            _PreviewRow(
              label: 'Usage',
              value: '${hours.toStringAsFixed(1)} hrs/day',
            ),
            _PreviewRow(
              label: 'Milestone',
              value: milestoneHours == 0
                  ? 'Alerts off'
                  : '${milestoneHours.toStringAsFixed(1)} hrs',
            ),
            _PreviewRow(
              label: 'Per hour',
              value: '$symbol${estimate.costPerHour.toStringAsFixed(2)}',
            ),
            _PreviewRow(
              label: 'Per day',
              value: '$symbol${estimate.costPerDay.toStringAsFixed(2)}',
            ),
            _PreviewRow(label: 'Confidence', value: estimate.confidence.label),
          ],
        ),
      ),
    );
  }
}

class _HardwareSummaryCard extends StatelessWidget {
  const _HardwareSummaryCard({required this.spec});

  final SystemSpecModel spec;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved hardware profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _PreviewRow(label: 'CPU', value: spec.cpuName),
            _PreviewRow(label: 'GPU', value: spec.gpuName),
            _PreviewRow(
              label: 'RAM',
              value: '${spec.ramGb} GB / ${spec.ramSticks} sticks',
            ),
            _PreviewRow(
              label: 'Storage',
              value: '${spec.storageCount} ${spec.storageType}',
            ),
            _PreviewRow(
              label: 'Chassis',
              value: spec.chassisType.replaceAll('_', ' '),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
