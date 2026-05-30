import 'package:flutter/material.dart';

class TipCardWidget extends StatelessWidget {
  final int index;
  final String tip;
  const TipCardWidget({super.key, required this.index, required this.tip});

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFF39FF14), Color(0xFF00B4D8), Color(0xFFFFD700), Color(0xFF39FF14), Color(0xFFFF6B6B)];
    const icons = [Icons.brightness_low_outlined, Icons.bluetooth_disabled_outlined, Icons.apps_outlined, Icons.battery_saver_outlined, Icons.thermostat_outlined];
    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];
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
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(tip, style: TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}
