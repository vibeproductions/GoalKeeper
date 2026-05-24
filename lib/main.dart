// lib/main.dart
// GoalKeeper Flutter — app entry point

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:goalkeeper_flutter/store/goal_store.dart';
import 'package:goalkeeper_flutter/theme/app_theme.dart';
import 'package:goalkeeper_flutter/views/main_scaffold.dart';
import 'package:goalkeeper_flutter/services/keychain_service.dart';

// Global scale notifier — updated from Settings, rebuilds entire app
final ValueNotifier<double> appScale = ValueNotifier(1.0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved display scale before the app renders
  appScale.value = await KeychainService.loadDisplayScale();

  // Window setup (macOS + Windows)
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1200, 780),
    minimumSize: Size(900, 600),
    center: true,
    title: 'GoalKeeper',
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Color(0xFF0D0D12),
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const GoalKeeperApp());
}

class GoalKeeperApp extends StatelessWidget {
  const GoalKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoalStore(),
      child: ValueListenableBuilder<double>(
        valueListenable: appScale,
        builder: (context, scale, child) {
          return MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              title: 'GoalKeeper',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: const MainScaffold(),
            ),
          );
        },
      ),
    );
  }
}