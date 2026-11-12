import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/services/auth_blockchain_service.dart';

class UserActivityMonitorView extends StatefulWidget {
  final VoidCallback? onBack;

  const UserActivityMonitorView({super.key, this.onBack});

  @override
  State<UserActivityMonitorView> createState() => _UserActivityMonitorViewState();
}

class _UserActivityMonitorViewState extends State<UserActivityMonitorView> {
  final AuthBlockchainService _authService = AuthBlockchainService();

  String _selectedRegion = 'SEMUA_WILAYAH';
  String _selectedSeverity = 'SEMUA';
  bool _isLoading = true;
  List<UserActivityLog> _logs = [];

  static const List<String> _regionOptions = [
    'SEMUA_WILAYAH',
    'Kodam Jaya',
    'Kodam I/Bukit Barisan',
    'Kodam II/Sriwijaya',
    'Kodam III/Siliwangi',
    'Kodam IV/Diponegoro',
    'Kodam V/Brawijaya',
    'Kodam VI/Mulawarman',
    'Kodam IX/Udayana',
    'Kodam XII/Tanjungpura',
    'Kodam XIII/Merdeka',
    'Kodam XIV/Hasanuddin',
    'Kodam XVI/Pattimura',
    'Kodam XVII/Cenderawasih',
    'Kodam XVIII/Kasuari',
    'Kodam Iskandar Muda',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final list = await _authService.fetchUserActivityLogs(
      regionalCommand: _selectedRegion == 'SEMUA_WILAYAH' ? null : _selectedRegion,
    );

    if (mounted) {
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _selectedSeverity == 'SEMUA'
        ? _logs
        : _logs.where((l) => l.severityLevel == _selectedSeverity).toList();

    return Container(
      color: const Color(0xFFF4F7F9),
      child: Column(
        children: [
          // ── Header Bar ────────────────────────────────────────────────────────
          _buildHeaderBar(),

          // ── Content ───────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.tniGreenAccent))
                : RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterStatsRow(filteredLogs.length),
                          const SizedBox(height: 18),
                          _buildLogTimeline(filteredLogs),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyberCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.cyberCyan, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENGAWASAN AKTIVITAS PENGGUNA REAL-TIME',
                    style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5)),
                Text('Log Aktivitas Taktis, Sesi Operator & Jejak Audit Kriptografis Wilayah',
                    style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Filter Wilayah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundShade,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRegion,
                style: GoogleFonts.exo2(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                items: _regionOptions.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(r == 'SEMUA_WILAYAH' ? '🌐 Seluruh Kodam' : '🛡️ $r'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRegion = val);
                    _loadLogs();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.cyberCyan),
            tooltip: 'Segarkan Log',
            onPressed: _loadLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStatsRow(int count) {
    return Row(
      children: [
        _severityChip('SEMUA', Icons.list_alt_rounded, Colors.grey.shade700),
        const SizedBox(width: 8),
        _severityChip('INFO', Icons.info_outline_rounded, AppColors.tniGreenAccent),
        const SizedBox(width: 8),
        _severityChip('WARN', Icons.warning_amber_rounded, AppColors.goldInsignia),
        const SizedBox(width: 8),
        _severityChip('CRITICAL', Icons.dangerous_outlined, AppColors.merahIndonesia),
        const Spacer(),
        Text('Menampilkan $count Log Aktivitas Terakhir', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _severityChip(String severity, IconData icon, Color color) {
    final active = _selectedSeverity == severity;
    return InkWell(
      onTap: () => setState(() => _selectedSeverity = severity),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : AppColors.glassBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(severity, style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTimeline(List<UserActivityLog> list) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Belum Ada Log Aktivitas Tercatat', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Aktivitas pengguna di wilayah ini akan muncul otomatis saat operator masuk atau menjalankan aksi taktis.',
                textAlign: TextAlign.center, style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final item = list[idx];
        Color badgeColor = AppColors.tniGreenAccent;
        if (item.severityLevel == 'WARN') badgeColor = AppColors.goldInsignia;
        if (item.severityLevel == 'CRITICAL') badgeColor = AppColors.merahIndonesia;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.activityType == 'LOGIN' ? Icons.login_rounded : (item.activityType == 'LOGOUT' ? Icons.logout_rounded : Icons.terminal_rounded),
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.operatorName ?? 'Operator (${item.operatorNik})',
                          style: GoogleFonts.exo2(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.activityType, style: GoogleFonts.orbitron(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor)),
                        ),
                        const Spacer(),
                        Text(item.createdAt, style: GoogleFonts.shareTechMono(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.actionDetail, style: GoogleFonts.exo2(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: AppColors.tniGreenDark),
                        const SizedBox(width: 4),
                        Text(item.regionalCommand, style: GoogleFonts.exo2(fontSize: 11, color: AppColors.tniGreenDark, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Icon(Icons.lan_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('IP: ${item.ipAddress}', style: GoogleFonts.shareTechMono(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

