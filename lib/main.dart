import 'package:flutter/material.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/local/hive_boxes.dart';
import 'data/repositories/wattage_repository.dart';

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
    return MaterialApp.router(
      title: 'Watt Tracker',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
