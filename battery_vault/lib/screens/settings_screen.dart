import "../l10n/app_localizations.dart";
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.language, style: const TextStyle(color: Color(0xFF39FF14), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
            ),
            child: Column(children: [
              RadioListTile<String>(
                title: Row(children: [
                  const Text('🇸🇦', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(l10n.arabic, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ]),
                value: 'ar',
                groupValue: currentLocale,
                onChanged: (v) => BatteryVaultApp.of(context)?.setLocale(Locale(v!)),
                activeColor: const Color(0xFF39FF14),
              ),
              RadioListTile<String>(
                title: Row(children: [
                  const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(l10n.english, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                ]),
                value: 'en',
                groupValue: currentLocale,
                onChanged: (v) => BatteryVaultApp.of(context)?.setLocale(Locale(v!)),
                activeColor: const Color(0xFF39FF14),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text(l10n.about, style: const TextStyle(color: Color(0xFF39FF14), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
            ),
            child: ListTile(
              leading: const Icon(Icons.battery_charging_full, color: Color(0xFF39FF14), size: 36),
              title: Text(l10n.appName, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              subtitle: Text('${l10n.version} $_version', style: const TextStyle(color: Colors.white38, fontFamily: 'Cairo', fontSize: 12)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF39FF14).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.tips_and_updates_outlined, color: Color(0xFF39FF14), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.tapHint, style: const TextStyle(color: Colors.white54, fontFamily: 'Cairo', fontSize: 13))),
            ]),
          ),
        ],
      ),
    );
  }
}
