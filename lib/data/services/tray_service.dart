import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/dashboard/cubit/live_timer_cubit.dart';

class TrayService with TrayListener {
  TrayService._internal();

  static final TrayService _instance = TrayService._internal();
  static const String _defaultCost = '\u20B10.00';
  static const String _costKey = 'current_cost';
  static const String _pauseResumeKey = 'pause_resume';
  static const String _resetKey = 'reset_session';
  static const String _openKey = 'open_wattwise';
  static const String _quitKey = 'quit_wattwise';

  factory TrayService() => _instance;

  LiveTimerCubit? _timerCubit;
  String _currentCost = _defaultCost;
  bool _initialized = false;
  bool _quitRequested = false;

  bool get isInitialized => _initialized;
  bool get isQuitRequested => _quitRequested;

  void resetQuitRequested() {
    _quitRequested = false;
  }

  Future<void> init(LiveTimerCubit timerCubit) async {
    if (!Platform.isWindows) {
      return;
    }

    _timerCubit = timerCubit;
    _quitRequested = false;

    if (!_initialized) {
      trayManager.addListener(this);
      await trayManager.setIcon('assets/tray_icon.ico');
      if (kDebugMode) {
        debugPrint('TrayService: setIcon completed for assets/tray_icon.ico');
      }
      _initialized = true;
    }

    await updateTooltip(timerCubit.formattedCost);
    await rebuildMenu(timerCubit.state.isRunning);
  }

  Future<void> dispose() async {
    if (!Platform.isWindows) {
      return;
    }

    _timerCubit = null;
    _currentCost = _defaultCost;

    if (!_initialized) {
      return;
    }

    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }

  Future<void> updateTooltip(String cost) async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }

    _currentCost = cost;
    await _updateTooltip(cost);
    await _rebuildMenu(_timerCubit?.state.isRunning ?? false);
  }

  Future<void> rebuildMenu(bool isRunning) async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }

    await _rebuildMenu(isRunning);
  }

  Future<void> quitApp() async {
    await _handleQuitAction();
  }

  Future<void> _updateTooltip(String cost) async {
    await trayManager.setToolTip('WattWise - $cost this session');
  }

  Future<void> _rebuildMenu(bool isRunning) async {
    final menu = Menu(
      items: <MenuItem>[
        MenuItem(
          key: _costKey,
          label: 'Current cost: $_currentCost',
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(
          key: _pauseResumeKey,
          label: isRunning ? 'Pause tracking' : 'Resume tracking',
          onClick: (_) {
            unawaited(_handlePauseResumeAction());
          },
        ),
        MenuItem(
          key: _resetKey,
          label: 'Reset session',
          onClick: (_) {
            unawaited(_handleResetAction());
          },
        ),
        MenuItem.separator(),
        MenuItem(
          key: _openKey,
          label: 'Open WattWise',
          onClick: (_) {
            unawaited(_handleOpenAction());
          },
        ),
        MenuItem.separator(),
        MenuItem(
          key: _quitKey,
          label: 'Quit WattWise',
          onClick: (_) {
            unawaited(_handleQuitAction());
          },
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  Future<void> _onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _onTrayMenuItemClick(MenuItem menuItem) async {
    if (kDebugMode) {
      debugPrint(
        'TrayService: onTrayMenuItemClick key=${menuItem.key} label=${menuItem.label}',
      );
    }
    switch (menuItem.key) {
      case _pauseResumeKey:
        await _handlePauseResumeAction();
        break;
      case _resetKey:
        await _handleResetAction();
        break;
      case _openKey:
        await _handleOpenAction();
        break;
      case _quitKey:
        await _handleQuitAction();
        break;
    }
  }

  Future<void> _handlePauseResumeAction() async {
    if (_timerCubit?.state.isRunning ?? false) {
      _timerCubit?.pauseTimer();
      await rebuildMenu(false);
    } else {
      _timerCubit?.startTimer();
      await rebuildMenu(true);
    }
  }

  Future<void> _handleResetAction() async {
    _timerCubit?.resetTimer();
    await updateTooltip(_timerCubit?.formattedCost ?? _defaultCost);
  }

  Future<void> _handleOpenAction() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _handleQuitAction() async {
    _quitRequested = true;
    _timerCubit?.pauseTimer();
    await dispose();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_onTrayIconMouseDown());
  }

  @override
  void onTrayIconRightMouseDown() {
    if (!_initialized) {
      return;
    }

    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    unawaited(_onTrayMenuItemClick(menuItem));
  }
}
