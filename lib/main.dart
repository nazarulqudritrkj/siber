import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/config/supabase_config.dart';
import 'views/landing_page.dart';
import 'core/constants/app_constants.dart';
import 'state/command_center_controller.dart';
import 'widgets/common/scanline_overlay.dart';
import 'widgets/header/command_header.dart';
import 'widgets/navigation/tactical_nav_bar.dart';
import 'views/dashboard_view.dart';
import 'views/satellite_view.dart';
import 'views/ai_intelligence_view.dart';
import 'views/blockchain_view.dart';
import 'views/telemetry_view.dart';
import 'views/field_operations_view.dart';
import 'views/regional_admin_view.dart';
import 'views/user_activity_monitor_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const SiCakrawalaApp());
}

class SiCakrawalaApp extends StatelessWidget {
  const SiCakrawalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-CAKRAWALA | Nanggroe Cakrawala Shield — TNI AD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LandingPage(),
    );
  }
}

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  late final CommandCenterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CommandCenterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Background Gradient Glows (light theme)
              Positioned(
                top: -120,
                left: -120,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x18CC0001), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -180,
                right: -180,
                child: Container(
                  width: 640,
                  height: 640,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x1200C6FF), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Main Application Layout
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Alert Bar
                    _buildAlertBar(),

                    // Tactical Command Header
                    CommandHeader(threatLevel: _controller.threatLevel),

                    // Navigation Tabs Bar
                    TacticalNavBar(
                      selectedIndex: _controller.selectedTabIndex,
                      onTabSelected: _controller.selectTab,
                    ),

                    // Main Content View Body
                    Expanded(
                      child: _buildCurrentView(),
                    ),

                    // Tactical Footer
                    _buildFooter(),
                  ],
                ),
              ),

              // Tactical Scanlines Overlay
              const ScanlineOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFCC0001),
            Color(0xFFE8001A),
            Color(0xFF8B0000),
            Color(0xFF1A3A28),
          ],
        ),
        border: Border(bottom: BorderSide(color: AppColors.merahIndonesia, width: 1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 14),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "SIAGA SIBER NASIONAL: Anomali jaringan terdeteksi di Sektor Tarakan | AI Mitigasi Aktif | Blockchain Konsensus BFT 100% Terverifikasi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_controller.selectedTabIndex) {
      case 0:
        return DashboardView(controller: _controller);
      case 1:
        return SatelliteView(controller: _controller);
      case 2:
        return AiIntelligenceView(controller: _controller);
      case 3:
        return BlockchainView(controller: _controller);
      case 4:
        return TelemetryView(controller: _controller);
      case 5:
        return FieldOperationsView(controller: _controller);
      case 6:
        return const RegionalAdminView();
      case 7:
        return const UserActivityMonitorView();
      default:
        return DashboardView(controller: _controller);
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.35), width: 1.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1B2D),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              "SI-CAKRAWALA ${AppConstants.version} • ${AppConstants.classification}",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'monospace'),
            ),
            SizedBox(width: 24),
            Text(
              "🔐 ${AppConstants.encryptionStandard} • ZERO-TRUST ARCHITECTURE",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.merahVibrant, fontFamily: 'monospace', letterSpacing: 0.5),
            ),
            SizedBox(width: 24),
            Text(
              "${AppConstants.militaryUnit} • MABES TNI ANGKATAN DARAT",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.tniGreenMid, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
