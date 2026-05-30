import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'home_screen.dart';
import '../services/vault_service.dart';

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
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  void _changeLanguage(String langCode) {
    BatteryVaultApp.of(context)?.setLocale(Locale(langCode));
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context)!;
    final isPinSet = await VaultService.isPinSet();
    if (!isPinSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vaultLocked, style: const TextStyle())),
      );
      return;
    }

    String oldPin = '';
    String newPin = '';
    String confirmNewPin = '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.changePin,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPinField(l10n.oldPin, (v) => oldPin = v),
            const SizedBox(height: 12),
            _buildPinField(l10n.newPin, (v) => newPin = v),
            const SizedBox(height: 12),
            _buildPinField(l10n.confirmPin, (v) => confirmNewPin = v),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPin != confirmNewPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.pinMismatch,
                          style: const TextStyle())),
                );
                return;
              }
              final ok = await VaultService.changePin(oldPin, newPin);
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? l10n.pinChanged : l10n.wrongOldPin,
                      style: const TextStyle(),
                    ),
                    backgroundColor: ok ? const Color(0xFF39FF14) : const Color(0xFFFF4444),
                  ),
                );
              }
            },
            child: Text(l10n.confirm, style: const TextStyle()),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField(String hint, Function(String) onChanged) {
    return TextField(
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        counterText: '',
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
    );
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
          // Language Section
          _buildSectionHeader(l10n.language),
          _buildCard(
            children: [
              _buildRadioTile(
                title: l10n.arabic,
                value: 'ar',
                groupValue: currentLocale,
                onChanged: _changeLanguage,
                leading: '🇸🇦',
              ),
              _buildRadioTile(
                title: l10n.english,
                value: 'en',
                groupValue: currentLocale,
                onChanged: _changeLanguage,
                leading: '🇺🇸',
              ),
            ],
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 20),

          // Vault Section
          _buildSectionHeader(l10n.vault),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Color(0xFF39FF14)),
                title: Text(l10n.changePin,
                    style: const TextStyle(
                        color: Colors.white)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.white38),
                onTap: _changePin,
              ),
            ],
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader(l10n.about),
          _buildCard(
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/app_icon.png',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.battery_charging_full,
                              color: Color(0xFF39FF14))),
                ),
                title: Text(l10n.appName,
                    style: const TextStyle(
                        color: Colors.white,
                        ,
                        fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${l10n.version} $_version',
                  style: const TextStyle(
                      color: Colors.white38,
                      ,
                      fontSize: 12),
                ),
              ),
            ],
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 32),

          // Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF39FF14).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: Color(0xFF39FF14), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.tapHint,
                    style: const TextStyle(
                      color: Colors.white54,
                      ,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF39FF14),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          ,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF39FF14).withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
    required String leading,
  }) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Text(leading, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white)),
        ],
      ),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      activeColor: const Color(0xFF39FF14),
    );
  }
}
