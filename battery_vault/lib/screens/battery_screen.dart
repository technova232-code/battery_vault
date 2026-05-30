import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../l10n/app_localizations.dart';
import '../services/battery_service.dart';
import '../services/ads_service.dart';
import '../widgets/battery_icon_widget.dart';
import '../widgets/tip_card_widget.dart';

class BatteryScreen extends StatefulWidget {
  final VoidCallback onBatteryIconTapped;
  const BatteryScreen({super.key, required this.onBatteryIconTapped});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _optimizeController;
  bool _isOptimizing = false;
  bool _optimized = false;
  BatteryInfo? _batteryInfo;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _optimizeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _optimizeController.dispose();
    super.dispose();
  }

  Future<void> _runOptimize() async {
    setState(() {
      _isOptimizing = true;
      _optimized = false;
    });
    _optimizeController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    // Show interstitial ad occasionally
    final rand = math.Random().nextInt(5);
    if (rand == 0) await AdsService.showInterstitial();
    setState(() {
      _isOptimizing = false;
      _optimized = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _optimized = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: StreamBuilder<BatteryInfo>(
        stream: BatteryService.batteryStream,
        builder: (context, snapshot) {
          _batteryInfo = snapshot.data;
          final level = _batteryInfo?.level ?? 0;
          final isCharging = _batteryInfo?.isCharging ?? false;
          final levelColor = _batteryInfo?.levelColor ?? const Color(0xFF39FF14);

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: const Color(0xFF0A0A0A),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/app_icon.png',
                        width: 32, height: 32,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.battery_charging_full,
                                color: Color(0xFF39FF14))),
                    const SizedBox(width: 8),
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        ,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Hint button
                  Tooltip(
                    message: l10n.tapHint,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.info_outline,
                          color: Colors.white38, size: 20),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Battery Circle Widget (tappable for vault)
                      GestureDetector(
                        onTap: widget.onBatteryIconTapped,
                        child: _buildBatteryCircle(
                            level, isCharging, levelColor, l10n),
                      ).animate().scale(
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 8),
                      Text(
                        l10n.tapHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          ,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Status Cards Row
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                            icon: isCharging
                                ? Icons.bolt
                                : Icons.battery_saver_outlined,
                            label: isCharging ? l10n.charging : l10n.notCharging,
                            color: isCharging
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF39FF14),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                            icon: Icons.health_and_safety_outlined,
                            label: _getHealthLabel(level, l10n),
                            color: levelColor,
                          )),
                        ],
                      ).animate().slideY(
                            begin: 0.3,
                            duration: 500.ms,
                            delay: 200.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 20),

                      // Optimize Button
                      _buildOptimizeButton(l10n).animate().slideY(
                            begin: 0.3,
                            duration: 500.ms,
                            delay: 300.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 28),

                      // Tips Section
                      _buildTipsSection(l10n).animate().slideY(
                            begin: 0.3,
                            duration: 500.ms,
                            delay: 400.ms,
                            curve: Curves.easeOut,
                          ),

                      const SizedBox(height: 20),

                      // Banner Ad
                      _buildBannerAd(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBatteryCircle(
      int level, bool isCharging, Color levelColor, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (isCharging)
              Container(
                width: 220 + pulse * 20,
                height: 220 + pulse * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: levelColor.withOpacity(0.03 + pulse * 0.05),
                ),
              ),
            // Circular Progress
            CircularPercentIndicator(
              radius: 110,
              lineWidth: 12,
              percent: level / 100,
              backgroundColor: Colors.white10,
              linearGradient: LinearGradient(
                colors: [levelColor.withOpacity(0.7), levelColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              circularStrokeCap: CircularStrokeCap.round,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BatteryIconWidget(
                    level: level,
                    isCharging: isCharging,
                    color: levelColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$level%',
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      ,
                      shadows: [
                        Shadow(
                          color: levelColor.withOpacity(0.5),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                  Text(
                    l10n.batteryLevel,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      ,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                ,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizeButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: AnimatedBuilder(
        animation: _optimizeController,
        builder: (context, child) {
          return ElevatedButton(
            onPressed: _isOptimizing ? null : _runOptimize,
            style: ElevatedButton.styleFrom(
              backgroundColor: _optimized
                  ? const Color(0xFF00C853)
                  : const Color(0xFF39FF14),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isOptimizing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black54,
                    ),
                  )
                else if (_optimized)
                  const Icon(Icons.check_circle, size: 22)
                else
                  const Icon(Icons.bolt, size: 22),
                const SizedBox(width: 10),
                Text(
                  _isOptimizing
                      ? l10n.optimizing
                      : _optimized
                          ? l10n.optimized
                          : l10n.boostBattery,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    ,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipsSection(AppLocalizations l10n) {
    final tips = [
      l10n.tip1,
      l10n.tip2,
      l10n.tip3,
      l10n.tip4,
      l10n.tip5,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tips,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            ,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map((entry) => TipCardWidget(
              index: entry.key,
              tip: entry.value,
            )),
      ],
    );
  }

  Widget _buildBannerAd() {
    if (!AdsService.isInitialized) return const SizedBox.shrink();
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF111827),
      ),
      clipBehavior: Clip.hardEdge,
      child: UnityBannerAd(
        placementId: AdsService.bannerAdUnitId,
        onLoad: (_) {},
        onClick: (_) {},
        onShown: (_) {},
        onFailed: (_, __, ___) {},
      ),
    );
  }

  String _getHealthLabel(int level, AppLocalizations l10n) {
    if (level >= 80) return l10n.excellent;
    if (level >= 60) return l10n.good;
    if (level >= 40) return l10n.fair;
    return l10n.poor;
  }
}
