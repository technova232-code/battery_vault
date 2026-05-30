import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import 'battery_screen.dart';
import 'vault_screen.dart';
import 'settings_screen.dart';
import '../services/vault_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _vaultUnlocked = false;
  int _batteryTapCount = 0;
  DateTime? _lastTapTime;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
  }

  void _onBatteryIconTapped() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      _batteryTapCount = 0;
    }
    _lastTapTime = now;
    _batteryTapCount++;

    if (_batteryTapCount >= 5) {
      _batteryTapCount = 0;
      _openVault();
    }
  }

  Future<void> _openVault() async {
    final isPinSet = await VaultService.isPinSet();
    if (!mounted) return;

    if (!isPinSet) {
      // First time - set PIN
      _navigateToSetPin();
    } else if (!_vaultUnlocked) {
      _navigateToUnlockVault();
    } else {
      setState(() => _currentIndex = 1);
    }
  }

  void _navigateToSetPin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          onPinSet: () {
            setState(() {
              _vaultUnlocked = true;
              _currentIndex = 1;
            });
          },
        ),
      ),
    );
  }

  void _navigateToUnlockVault() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinUnlockScreen(
          onUnlocked: () {
            setState(() {
              _vaultUnlocked = true;
              _currentIndex = 1;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      BatteryScreen(onBatteryIconTapped: _onBatteryIconTapped),
      if (_vaultUnlocked)
        VaultScreen(
          onLock: () => setState(() {
            _vaultUnlocked = false;
            _currentIndex = 0;
          }),
        )
      else
        const SizedBox.shrink(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF39FF14).withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == 1 && !_vaultUnlocked) {
              _openVault();
            } else {
              setState(() => _currentIndex = index);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.battery_charging_full_outlined),
              selectedIcon: const Icon(
                Icons.battery_charging_full,
                color: Color(0xFF39FF14),
              ),
              label: l10n.battery,
            ),
            NavigationDestination(
              icon: Stack(
                children: [
                  const Icon(Icons.lock_outline),
                  if (_vaultUnlocked)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF39FF14),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: const Icon(Icons.lock_open, color: Color(0xFF39FF14)),
              label: l10n.vault,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: Color(0xFF39FF14)),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// PIN Setup Screen
class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinSet;
  const PinSetupScreen({super.key, required this.onPinSet});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _error = '';

  void _onDigitPressed(String digit) {
    setState(() {
      _error = '';
      if (!_isConfirming) {
        if (_pin.length < 6) {
          _pin += digit;
          if (_pin.length == 6) {
            Future.delayed(const Duration(milliseconds: 200), () {
              setState(() => _isConfirming = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin += digit;
          if (_confirmPin.length == 6) {
            _checkPins();
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _checkPins() async {
    if (_pin == _confirmPin) {
      await VaultService.setPin(_pin);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPinSet();
      }
    } else {
      setState(() {
        _error = AppLocalizations.of(context)!.pinMismatch;
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PinKeypadScreen(
      title: l10n.setPinTitle,
      subtitle: _isConfirming ? l10n.confirmPin : l10n.enterPin,
      currentPin: _isConfirming ? _confirmPin : _pin,
      error: _error,
      onDigit: _onDigitPressed,
      onDelete: _onDelete,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}

// PIN Unlock Screen
class PinUnlockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinUnlockScreen({super.key, required this.onUnlocked});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '';
  String _error = '';
  bool _shaking = false;

  void _onDigitPressed(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _error = '';
      _pin += digit;
    });
    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final valid = await VaultService.verifyPin(_pin);
    if (valid) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onUnlocked();
      }
    } else {
      setState(() {
        _error = AppLocalizations.of(context)!.wrongPin;
        _pin = '';
        _shaking = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _shaking = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PinKeypadScreen(
      title: l10n.vault,
      subtitle: l10n.enterPin,
      currentPin: _pin,
      error: _error,
      shaking: _shaking,
      onDigit: _onDigitPressed,
      onDelete: _onDelete,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}

// Reusable PIN Keypad Widget
class PinKeypadScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String currentPin;
  final String error;
  final bool shaking;
  final Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onBack;

  const PinKeypadScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentPin,
    this.error = '',
    this.shaking = false,
    required this.onDigit,
    required this.onDelete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF39FF14).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xFF39FF14),
                size: 36,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                ,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                ,
              ),
            ),
            const SizedBox(height: 40),
            // PIN dots
            AnimatedContainer(
              duration: 100.ms,
              transform: shaking
                  ? (Matrix4.identity()..translate(10.0, 0, 0))
                  : Matrix4.identity(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < currentPin.length;
                  return AnimatedContainer(
                    duration: 150.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFF39FF14)
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? const Color(0xFF39FF14)
                            : Colors.white30,
                        width: 2,
                      ),
                      boxShadow: filled
                          ? [
                              BoxShadow(
                                color: const Color(0xFF39FF14).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            if (error.isNotEmpty)
              Text(
                error,
                style: const TextStyle(
                  color: Color(0xFFFF4444),
                  fontSize: 13,
                  ,
                ),
              ).animate().shakeX(duration: 300.ms),
            const Spacer(),
            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'del'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((key) {
                        if (key.isEmpty) return const SizedBox(width: 80);
                        return GestureDetector(
                          onTap: () =>
                              key == 'del' ? onDelete() : onDigit(key),
                          child: Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A2E),
                              border: Border.all(
                                color: const Color(0xFF39FF14).withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: key == 'del'
                                  ? const Icon(Icons.backspace_outlined,
                                      color: Colors.white70, size: 22)
                                  : Text(
                                      key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        ,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
