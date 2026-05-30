import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class BatteryIconWidget extends StatelessWidget {
  final int level;
  final bool isCharging;
  final Color color;
  final double size;

  const BatteryIconWidget({
    super.key,
    required this.level,
    required this.isCharging,
    required this.color,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (isCharging) {
      icon = Icons.battery_charging_full;
    } else if (level >= 90) {
      icon = Icons.battery_full;
    } else if (level >= 70) {
      icon = Icons.battery_6_bar;
    } else if (level >= 50) {
      icon = Icons.battery_4_bar;
    } else if (level >= 30) {
      icon = Icons.battery_3_bar;
    } else if (level >= 15) {
      icon = Icons.battery_2_bar;
    } else {
      icon = Icons.battery_1_bar;
    }

    return Icon(
      icon,
      color: color,
      size: size,
      shadows: [
        Shadow(
          color: color.withOpacity(0.6),
          blurRadius: 10,
        ),
      ],
    );
  }
}
