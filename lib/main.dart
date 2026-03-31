import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/local/hive_boxes.dart';
import 'data/repositories/wattage_repository.dart';
import 'features/calculator/cubit/cost_calculator_cubit.dart';
import 'features/history/cubit/history_cubit.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/settings/cubit/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBootstrap.initialize();

  final repository = WattageRepository();
  await repository.seedPresetsIfEmpty();

  runApp(const WattTrackerApp());
}

class WattTrackerApp extends StatelessWidget {
  const WattTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = WattageRepository();

    return RepositoryProvider(
      create: (_) => repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit()),
          BlocProvider(
            create: (_) {
              return CostCalculatorCubit()
                ..setDevice(WattageRepository.devicePresets.first)
                ..configureComponentWattage(WattageRepository.componentPresets)
                ..setRatePerKwh(12)
                ..setHours(4);
            },
          ),
          BlocProvider(
            create: (_) {
              final cubit = HistoryCubit(repository);
              cubit.loadSessions();
              return cubit;
            },
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            return MaterialApp.router(
              title: 'Watt Tracker',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settingsState.themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}
