import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/section_card.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../cubit/cost_calculator_cubit.dart';
import '../cubit/cost_calculator_state.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: BlocBuilder<CostCalculatorCubit, CostCalculatorState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final cards = [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Load',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<PerformanceLoadProfile>(
                        segments: const [
                          ButtonSegment(
                            value: PerformanceLoadProfile.eco,
                            label: Text('Eco'),
                          ),
                          ButtonSegment(
                            value: PerformanceLoadProfile.balanced,
                            label: Text('Balanced'),
                          ),
                          ButtonSegment(
                            value: PerformanceLoadProfile.high,
                            label: Text('High'),
                          ),
                        ],
                        selected: {state.loadProfile},
                        onSelectionChanged: (selected) {
                          context.read<CostCalculatorCubit>().setLoadProfile(
                            selected.first,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Components',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('GPU enabled'),
                        value: state.isGpuEnabled,
                        onChanged: (value) => context
                            .read<CostCalculatorCubit>()
                            .toggleGpu(value),
                      ),
                      _NumberField(
                        label: 'GPU wattage',
                        value: state.gpuWattage,
                        onChanged: (v) => context
                            .read<CostCalculatorCubit>()
                            .setGpuWattage(v),
                      ),
                      const SizedBox(height: 8),
                      _NumberField(
                        label: 'RAM wattage',
                        value: state.ramWattage,
                        onChanged: (v) => context
                            .read<CostCalculatorCubit>()
                            .setRamWattage(v),
                      ),
                      const SizedBox(height: 8),
                      _NumberField(
                        label: 'Storage wattage/drive',
                        value: state.storageWattagePerDrive,
                        onChanged: (v) => context
                            .read<CostCalculatorCubit>()
                            .setStorageWattagePerDrive(v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Text('Number of drives')),
                          IconButton(
                            onPressed: () => context
                                .read<CostCalculatorCubit>()
                                .setStorageDriveCount(
                                  state.storageDriveCount - 1,
                                ),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${state.storageDriveCount}'),
                          IconButton(
                            onPressed: () => context
                                .read<CostCalculatorCubit>()
                                .setStorageDriveCount(
                                  state.storageDriveCount + 1,
                                ),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _NumberField(
                        label: 'Fan wattage/fan',
                        value: state.fanWattagePerFan,
                        onChanged: (v) => context
                            .read<CostCalculatorCubit>()
                            .setFanWattagePerFan(v),
                      ),
                      Row(
                        children: [
                          const Expanded(child: Text('Number of fans')),
                          IconButton(
                            onPressed: () => context
                                .read<CostCalculatorCubit>()
                                .setFanCount(state.fanCount - 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${state.fanCount}'),
                          IconButton(
                            onPressed: () => context
                                .read<CostCalculatorCubit>()
                                .setFanCount(state.fanCount + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('RGB enabled'),
                        value: state.isRgbEnabled,
                        onChanged: (value) => context
                            .read<CostCalculatorCubit>()
                            .toggleRgb(value),
                      ),
                      _NumberField(
                        label: 'RGB wattage',
                        value: state.rgbWattage,
                        onChanged: (v) => context
                            .read<CostCalculatorCubit>()
                            .setRgbWattage(v),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Electricity Rate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NumberField(
                        label: 'Rate per kWh',
                        value: state.ratePerKwh,
                        onChanged: (v) {
                          context.read<CostCalculatorCubit>().setRatePerKwh(v);
                          context.read<SettingsCubit>().setDefaultRatePerKwh(v);
                        },
                      ),
                    ],
                  ),
                ),
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: wide
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final card in cards)
                            SizedBox(
                              width: (constraints.maxWidth - 56) / 2,
                              child: card,
                            ),
                        ],
                      )
                    : Column(children: cards),
              );
            },
          );
        },
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (value) {
        final parsed = double.tryParse(value);
        widget.onChanged(parsed ?? 0);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
