import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

class BatteryInfo {
  final int level;
  final BatteryState state;
  final bool isCharging;

  BatteryInfo({required this.level, required this.state, required this.isCharging});

  Color get levelColor {
    if (level >= 60) return const Color(0xFF39FF14);
    if (level >= 30) return const Color(0xFFFFD700);
    return const Color(0xFFFF4444);
  }
}

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
    _stateSubscription = _battery.onBatteryStateChanged.listen((state) => _emitInfo(state));
    _levelTimer = Timer.periodic(const Duration(seconds: 30), (_) => _emitInfo(null));
    _emitInfo(null);
  }

  static Future<void> _emitInfo(BatteryState? state) async {
    try {
      final level = await _battery.batteryLevel;
      final currentState = state ?? await _battery.batteryState;
      _controller?.add(BatteryInfo(
        level: level,
        state: currentState,
        isCharging: currentState == BatteryState.charging || currentState == BatteryState.full,
      ));
    } catch (e) {
      debugPrint('BatteryService error: $e');
    }
  }

  static void dispose() {
    _stateSubscription?.cancel();
    _levelTimer?.cancel();
    _controller?.close();
    _controller = null;
  }
}
