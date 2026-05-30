import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatteryInfo {
  final int level;
  final BatteryState state;
  final bool isCharging;
  final String health;

  BatteryInfo({
    required this.level,
    required this.state,
    required this.isCharging,
    required this.health,
  });

  String get healthLabel {
    if (level >= 80) return 'excellent';
    if (level >= 60) return 'good';
    if (level >= 40) return 'fair';
    return 'poor';
  }

  Color get levelColor {
    if (level >= 60) return const Color(0xFF39FF14);
    if (level >= 30) return const Color(0xFFFFD700);
    return const Color(0xFFFF4444);
  }
}

// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart' show Color;

class BatteryService {
  static final Battery _battery = Battery();
  static StreamController<BatteryInfo>? _controller;
  static StreamSubscription? _stateSubscription;
  static Timer? _levelTimer;

  static Stream<BatteryInfo> get batteryStream {
    _controller ??= StreamController<BatteryInfo>.broadcast();
    _startMonitoring();
    return _controller!.stream;
  }

  static void _startMonitoring() {
    _stateSubscription?.cancel();
    _levelTimer?.cancel();

    // Listen to state changes
    _stateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _emitInfo(state);
    });

    // Poll level every 30 seconds
    _levelTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _emitInfo(null);
    });

    // Emit immediately
    _emitInfo(null);
  }

  static Future<void> _emitInfo(BatteryState? state) async {
    try {
      final level = await _battery.batteryLevel;
      final currentState = state ?? await _battery.batteryState;
      _controller?.add(BatteryInfo(
        level: level,
        state: currentState,
        isCharging: currentState == BatteryState.charging ||
            currentState == BatteryState.full,
        health: _getHealth(level),
      ));
    } catch (e) {
      debugPrint('BatteryService error: $e');
    }
  }

  static String _getHealth(int level) {
    if (level >= 80) return 'excellent';
    if (level >= 60) return 'good';
    if (level >= 40) return 'fair';
    return 'poor';
  }

  static Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  static Future<BatteryState> getBatteryState() async {
    return await _battery.batteryState;
  }

  static void dispose() {
    _stateSubscription?.cancel();
    _levelTimer?.cancel();
    _controller?.close();
    _controller = null;
  }
}
