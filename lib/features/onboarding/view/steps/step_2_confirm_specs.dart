import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/system_spec_model.dart';
import '../../../../data/models/field_metadata.dart';
import '../../../../data/repositories/wattage_preset_repository.dart';
import '../../cubit/onboarding_cubit.dart';

class Step2ConfirmSpecs extends StatefulWidget {
  const Step2ConfirmSpecs({super.key, required this.onContinue});

  final ValueChanged<SystemSpecModel> onContinue;

  @override
  State<Step2ConfirmSpecs> createState() => _Step2ConfirmSpecsState();
}

class _Step2ConfirmSpecsState extends State<Step2ConfirmSpecs> {
  final _presetRepository = WattagePresetRepository();

  late final TextEditingController _cpuController;
  late final TextEditingController _gpuController;
  late final TextEditingController _ramGbController;
  late final TextEditingController _motherboardController;
  late int _ramSticks;
  late int _storageCount;
  late double _fanCount;
  late bool _hasRgb;
  late String _chassisType;
  late String _gpuType;
  late String _storageType;

  @override
  void initState() {
    super.initState();
    final specs = context.read<OnboardingCubit>().state.confirmedSpecs;
    _cpuController = TextEditingController(text: specs.cpuName);
    _gpuController = TextEditingController(text: specs.gpuName);
    _ramGbController = TextEditingController(text: specs.ramGb.toString());
    _motherboardController = TextEditingController(text: specs.motherboard);
    _ramSticks = specs.ramSticks;
    _storageCount = specs.storageCount;
    _fanCount = specs.fanCount.toDouble();
    _hasRgb = specs.hasRgb;
    _chassisType = specs.chassisType;
    _gpuType = specs.gpuType;
    _storageType = specs.storageType;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingCubit>().state;
    final specs = state.confirmedSpecs;
    final needsManualHelp =
        _looksUnknown(specs.cpuName) || _looksUnknown(specs.motherboard);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _InfoPill(
                        icon: Icons.edit_note_rounded,
                        label: 'Review before saving',
                      ),
                      _InfoPill(
                        icon: Icons.tune_rounded,
                        label: 'Adjust any detected value',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Confirm your hardware',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This is the last chance to correct your setup before we turn it into a power profile. If Windows blocked something, you can manually look it up below.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (needsManualHelp) ...[
                    const SizedBox(height: 18),
                    _DetectionHelpCard(onCopy: _copyCommand),
                  ],
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SectionCard(
                            width: wide
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth,
                            title: 'Core components',
                            child: Column(
                              children: [
                                TextField(
                                  controller: _cpuController,
                                  decoration: const InputDecoration(
                                    labelText: 'CPU name',
                                  ),
                                ),
                                _FieldMetadataHint(
                                  value: specs.cpuName,
                                  metadata: specs.metadataFor(
                                    SystemSpecModel.cpuNameField,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _gpuController,
                                  decoration: const InputDecoration(
                                    labelText: 'GPU name',
                                  ),
                                ),
                                _FieldMetadataHint(
                                  value: specs.gpuName,
                                  metadata: specs.metadataFor(
                                    SystemSpecModel.gpuNameField,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _ramGbController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'RAM GB',
                                  ),
                                ),
                                _FieldMetadataHint(
                                  value: specs.ramGb.toString(),
                                  metadata: specs.metadataFor(
                                    SystemSpecModel.ramGbField,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _motherboardController,
                                  decoration: const InputDecoration(
                                    labelText: 'Motherboard',
                                  ),
                                ),
                                _FieldMetadataHint(
                                  value: specs.motherboard,
                                  metadata: specs.metadataFor(
                                    SystemSpecModel.motherboardField,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _SectionCard(
                            width: wide
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth,
                            title: 'Power assumptions',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _chassisType,
                                  decoration: const InputDecoration(
                                    labelText: 'Chassis type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'laptop',
                                      child: Text('Laptop'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'desktop',
                                      child: Text('Desktop'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'mini_desktop',
                                      child: Text('Mini Desktop'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _chassisType = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                const Text('GPU type'),
                                const SizedBox(height: 6),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'integrated',
                                      label: Text('Integrated'),
                                    ),
                                    ButtonSegment(
                                      value: 'dedicated',
                                      label: Text('Dedicated'),
                                    ),
                                  ],
                                  selected: {_gpuType},
                                  onSelectionChanged: (selection) => setState(
                                    () => _gpuType = selection.first,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _IntegerField(
                                  label: 'RAM sticks',
                                  initial: _ramSticks,
                                  min: 1,
                                  onChanged: (value) => _ramSticks = value,
                                ),
                                const SizedBox(height: 12),
                                _IntegerField(
                                  label: 'Storage count',
                                  initial: _storageCount,
                                  min: 1,
                                  onChanged: (value) => _storageCount = value,
                                ),
                                const SizedBox(height: 12),
                                const Text('Storage type'),
                                const SizedBox(height: 6),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'SSD',
                                      label: Text('SSD'),
                                    ),
                                    ButtonSegment(
                                      value: 'HDD',
                                      label: Text('HDD'),
                                    ),
                                  ],
                                  selected: {_storageType},
                                  onSelectionChanged: (selection) {
                                    setState(
                                      () => _storageType = selection.first,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text('Fan count: ${_fanCount.round()}'),
                                Slider(
                                  min: 0,
                                  max: 10,
                                  divisions: 10,
                                  value: _fanCount,
                                  label: _fanCount.round().toString(),
                                  onChanged: (value) =>
                                      setState(() => _fanCount = value),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Has RGB lighting'),
                                  value: _hasRgb,
                                  onChanged: (value) =>
                                      setState(() => _hasRgb = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      final cpuName = _fallbackText(
                        _cpuController.text,
                        specs.cpuName,
                      );
                      final gpuName = _fallbackText(
                        _gpuController.text,
                        specs.gpuName,
                      );
                      final motherboard = _fallbackText(
                        _motherboardController.text,
                        specs.motherboard,
                      );
                      final ramGb = int.tryParse(_ramGbController.text.trim());

                      final updated = specs.copyWith(
                        cpuName: cpuName,
                        cpuTdpWatts: _presetRepository.resolveCpuTdp(cpuName),
                        chassisType: _chassisType,
                        gpuType: _gpuType,
                        gpuName: gpuName,
                        gpuWatts: _presetRepository.resolveGpuWatts(
                          gpuName,
                          _gpuType,
                        ),
                        ramGb: ramGb == null || ramGb < 1 ? specs.ramGb : ramGb,
                        ramSticks: _ramSticks,
                        storageCount: _storageCount,
                        storageType: _storageType,
                        storageWattsEach: _storageType == 'HDD' ? 7 : 3,
                        fanCount: _fanCount.round(),
                        hasRgb: _hasRgb,
                        rgbWatts: _hasRgb ? 10 : 0,
                        motherboard: motherboard,
                      );
                      widget.onContinue(updated);
                    },
                    child: const Text('Looks good, continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _looksUnknown(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized.contains('unknown');
  }

  String _fallbackText(String raw, String fallback) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Future<void> _copyCommand(String label, String command) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label command copied.')));
  }

  @override
  void dispose() {
    _cpuController.dispose();
    _gpuController.dispose();
    _ramGbController.dispose();
    _motherboardController.dispose();
    super.dispose();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

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

class _FieldMetadataHint extends StatelessWidget {
  const _FieldMetadataHint({required this.value, required this.metadata});

  final String value;
  final FieldMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final unknown = metadata.isUnknown || _looksUnknown(value);
    final colorScheme = Theme.of(context).colorScheme;
    final label = unknown ? 'Unknown - please confirm' : _sourceLabel(metadata);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            unknown ? Icons.help_outline_rounded : Icons.verified_rounded,
            size: 16,
          ),
          label: Text(label),
          backgroundColor: unknown
              ? colorScheme.errorContainer.withValues(alpha: 0.35)
              : colorScheme.secondaryContainer.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _sourceLabel(FieldMetadata metadata) {
    final confidence = (metadata.confidence * 100).round();
    switch (metadata.source) {
      case FieldSource.scan:
        return 'Detected - $confidence% confidence';
      case FieldSource.user:
        return 'User confirmed';
      case FieldSource.inferred:
        return 'Estimated - $confidence% confidence';
      case FieldSource.unknown:
        return 'Unknown - please confirm';
    }
  }

  bool _looksUnknown(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized.contains('unknown');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.width,
    required this.title,
    required this.child,
  });

  final double width;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetectionHelpCard extends StatelessWidget {
  const _DetectionHelpCard({required this.onCopy});

  final Future<void> Function(String label, String command) onCopy;

  static const _commands = <({String label, String command})>[
    (
      label: 'CPU',
      command:
          'reg query "HKLM\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0" /v ProcessorNameString',
    ),
    (
      label: 'Motherboard',
      command:
          'reg query "HKLM\\HARDWARE\\DESCRIPTION\\System\\BIOS" /v BaseBoardProduct',
    ),
    (
      label: 'RAM',
      command:
          'powershell -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Math]::Ceiling([Microsoft.VisualBasic.Devices.ComputerInfo]::new().TotalPhysicalMemory / 1GB)"',
    ),
    (
      label: 'Storage',
      command:
          'reg query "HKLM\\SYSTEM\\CurrentControlSet\\Services\\disk\\Enum"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need a manual lookup?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Open Command Prompt or PowerShell, run one of these commands, and paste the result into the matching field.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final item in _commands) ...[
              _CommandRow(
                label: item.label,
                command: item.command,
                onCopy: () => onCopy(item.label, item.command),
              ),
              if (item != _commands.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.label,
    required this.command,
    required this.onCopy,
  });

  final String label;
  final String command;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          SelectableText(command),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy command'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegerField extends StatefulWidget {
  const _IntegerField({
    required this.label,
    required this.initial,
    required this.onChanged,
    required this.min,
  });

  final String label;
  final int initial;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  State<_IntegerField> createState() => _IntegerFieldState();
}

class _IntegerFieldState extends State<_IntegerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: widget.label),
      onChanged: (value) {
        final parsed = int.tryParse(value) ?? widget.min;
        widget.onChanged(parsed < widget.min ? widget.min : parsed);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
