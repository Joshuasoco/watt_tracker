import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../shared/utils/currency.dart';
import '../../../shared/widgets/section_card.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../settings/cubit/settings_state.dart';
import '../cubit/history_cubit.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, historyState) {
          return BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              final sessions = historyState.sessions;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 900;
                  final chartCard = SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Per Session',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: sessions.isEmpty
                              ? const Center(child: Text('No sessions yet'))
                              : BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '#${value.toInt() + 1}',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: [
                                      for (var i = 0; i < sessions.length; i++)
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: sessions[i].totalCost,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              width: 16,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );

                  final listCard = SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Past Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (sessions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('No saved sessions yet.'),
                          )
                        else
                          for (final session in sessions)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                formatCurrency(
                                  settingsState.currencyCode,
                                  session.totalCost,
                                ),
                              ),
                              subtitle: Text(
                                '${session.durationMinutes} min - ${session.createdAt.toLocal()}',
                              ),
                              trailing: IconButton(
                                onPressed: () => context
                                    .read<HistoryCubit>()
                                    .deleteSession(session.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                      ],
                    ),
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: chartCard),
                              const SizedBox(width: 12),
                              Expanded(child: listCard),
                            ],
                          )
                        : Column(children: [chartCard, listCard]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
