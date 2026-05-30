import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class TipCardWidget extends StatelessWidget {
  final int index;
  final String tip;

  const TipCardWidget({super.key, required this.index, required this.tip});

  static const _icons = [
    Icons.brightness_low_outlined,
    Icons.bluetooth_disabled_outlined,
    Icons.apps_outlined,
    Icons.battery_saver_outlined,
    Icons.thermostat_outlined,
  ];

  static const _colors = [
    Color(0xFF39FF14),
    Color(0xFF00B4D8),
    Color(0xFFFFD700),
    Color(0xFF39FF14),
    Color(0xFFFF6B6B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    final icon = _icons[index % _icons.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: Colors.white70,
                ,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
