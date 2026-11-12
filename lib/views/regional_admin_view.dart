import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/services/auth_blockchain_service.dart';

class RegionalAdminView extends StatefulWidget {
  final VoidCallback? onBack;

  const RegionalAdminView({super.key, this.onBack});

  @override
  State<RegionalAdminView> createState() => _RegionalAdminViewState();
}

class _RegionalAdminViewState extends State<RegionalAdminView> {
  final AuthBlockchainService _authService = AuthBlockchainService();

  String _selectedRegion = 'SEMUA_WILAYAH';
  bool _isLoading = true;
  List<OperatorProfile> _pendingList = [];
  List<OperatorProfile> _allOperators = [];

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pending = await _authService.fetchPendingOperators(
      regionalCommand: _selectedRegion == 'SEMUA_WILAYAH' ? null : _selectedRegion,
    );
    final all = await _authService.fetchAllOperators(
      regionalCommand: _selectedRegion == 'SEMUA_WILAYAH' ? null : _selectedRegion,
    );

    if (mounted) {
      setState(() {
        _pendingList = pending;
        _allOperators = all;
        _isLoading = false;
      });
    }
  }

  Future<void> _showApproveDialog(OperatorProfile operator) async {
    int selectedClearance = 2;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.tniGreenAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Otorisasi & Persetujuan Personel',
                  style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Konfirmasi verifikasi identitas militer untuk:', style: GoogleFonts.exo2(fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundShade,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(operator.namaLengkap, style: GoogleFonts.exo2(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('NIK: ${operator.nik} • Pangkat: ${operator.pangkat}', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
                    Text('Wilayah: ${operator.regionalCommand}', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.tniGreenDark, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Tetapkan Clearance Level (Tingkat Akses):', style: GoogleFonts.exo2(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedClearance,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Level 1 - Operator Lapangan Dasar', style: GoogleFonts.exo2(fontSize: 12))),
                  DropdownMenuItem(value: 2, child: Text('Level 2 - Operator Taktis Regional', style: GoogleFonts.exo2(fontSize: 12))),
                  DropdownMenuItem(value: 3, child: Text('Level 3 - Perwira Sandi & Radar', style: GoogleFonts.exo2(fontSize: 12))),
                  DropdownMenuItem(value: 4, child: Text('Level 4 - Komandan Batalyon Siber', style: GoogleFonts.exo2(fontSize: 12))),
                  DropdownMenuItem(value: 5, child: Text('Level 5 - Panglima & Staf Ahli Komando', style: GoogleFonts.exo2(fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => selectedClearance = v);
                },
              ),
              const SizedBox(height: 12),
              Text('Catatan: Keputusan ini otomatis di-commit ke Blockchain Ledger dengan tanda tangan digital NIST FIPS 204.',
                  style: GoogleFonts.exo2(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.exo2(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tniGreenAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final currentUid = _authService.currentUserId ?? '00000000-0000-0000-0000-000000000000';
                final success = await _authService.approveOperator(
                  operatorId: operator.id,
                  clearanceLevel: selectedClearance,
                  verifiedByUserId: currentUid,
                );

                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Personel berhasil diverifikasi & terekam di Blockchain!' : 'Gagal memverifikasi personel.'),
                    backgroundColor: success ? AppColors.tniGreenAccent : AppColors.merahIndonesia,
                  ),
                );
                _loadData();
              },
              child: Text('SAHKAN AKUN', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(OperatorProfile operator) async {
    final reasonCtrl = TextEditingController(text: 'Kredensial atau KTA militer tidak sesuai verifikasi wilayah.');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.merahIndonesia, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tolak Pendaftaran Personel',
                style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.merahIndonesia),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menolak akses operasional untuk: ${operator.namaLengkap} (${operator.nik})', style: GoogleFonts.exo2(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: GoogleFonts.exo2(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Alasan Penolakan Taktis',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.exo2(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahIndonesia,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final currentUid = _authService.currentUserId ?? '00000000-0000-0000-0000-000000000000';
              final success = await _authService.rejectOperator(
                operatorId: operator.id,
                reason: reasonCtrl.text.trim(),
                verifiedByUserId: currentUid,
              );

              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Penolakan berhasil dicatat ke Blockchain Ledger.' : 'Gagal menolak akun.'),
                  backgroundColor: AppColors.merahIndonesia,
                ),
              );
              _loadData();
            },
            child: Text('TOLAK PENDAFTARAN', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricsRow(),
                          const SizedBox(height: 24),
                          _buildPendingSection(),
                          const SizedBox(height: 24),
                          _buildAllOperatorsSection(),
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
              color: AppColors.tniGreenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.tniGreenDark, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OTORISASI KOMANDO & VERIFIKASI WILAYAH',
                    style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.5)),
                Text('Panglima Wilayah & Administrator Sistem — Validasi Personel Sesuai Teritorial',
                    style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Filter Wilayah Dropdown
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
                    child: Text(r == 'SEMUA_WILAYAH' ? '🌐 Seluruh Kodam (Nasional)' : '🛡️ $r'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRegion = val);
                    _loadData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.tniGreenDark),
            tooltip: 'Segarkan Antrean',
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final pendingCount = _pendingList.length;
    final activeCount = _allOperators.where((o) => o.verificationStatus == 'APPROVED_ACTIVE').length;
    final rejectedCount = _allOperators.where((o) => o.verificationStatus == 'REJECTED').length;

    return Row(
      children: [
        _metricCard('MENUNGGU VERIFIKASI', pendingCount.toString(), Icons.hourglass_top_rounded, AppColors.goldInsignia),
        const SizedBox(width: 16),
        _metricCard('PERSONEL AKTIF', activeCount.toString(), Icons.verified_rounded, AppColors.tniGreenAccent),
        const SizedBox(width: 16),
        _metricCard('DITOLAK / SUSPEND', rejectedCount.toString(), Icons.block_flipped, AppColors.merahIndonesia),
      ],
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(val, style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment_ind_rounded, color: AppColors.goldInsignia, size: 22),
            const SizedBox(width: 8),
            Text('ANTEAN PENDAFTARAN MENUNGGU PERSETUJUAN',
                style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.2)),
            const Spacer(),
            Text('${_pendingList.length} Personel Menunggu', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.task_alt_rounded, color: AppColors.tniGreenAccent, size: 48),
                const SizedBox(height: 12),
                Text('Semua Pendaftaran Tervalidasi', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tidak ada personel yang menunggu verifikasi di wilayah ini.', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final op = _pendingList[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldInsignia.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.tniGreenDark.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_pin_rounded, color: AppColors.tniGreenDark, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(op.namaLengkap, style: GoogleFonts.exo2(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.goldInsignia.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('PENDING', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldInsignia)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('NIK: ${op.nik} • Pangkat: ${op.pangkat} • Satuan: ${op.satuan}',
                              style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: AppColors.tniGreenDark),
                              const SizedBox(width: 4),
                              Text('Wilayah: ${op.regionalCommand}', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.tniGreenDark, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 14),
                              const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(op.email, style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tniGreenAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () => _showApproveDialog(op),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          label: Text('SETUJUI', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.merahIndonesia),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onPressed: () => _showRejectDialog(op),
                          icon: const Icon(Icons.close_rounded, color: AppColors.merahIndonesia, size: 18),
                          label: Text('TOLAK', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.merahIndonesia)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAllOperatorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.military_tech_rounded, color: AppColors.tniGreenDark, size: 22),
            const SizedBox(width: 8),
            Text('DIREKTORI SELURUH PERSONEL TERDAFTAR',
                style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 1.2)),
            const Spacer(),
            Text('${_allOperators.length} Total Personel', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allOperators.length,
            separatorBuilder: (_, _) => Divider(color: AppColors.glassBorder, height: 1),
            itemBuilder: (context, idx) {
              final op = _allOperators[idx];
              final isApproved = op.verificationStatus == 'APPROVED_ACTIVE';
              final isRejected = op.verificationStatus == 'REJECTED';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isApproved
                      ? AppColors.tniGreenAccent.withValues(alpha: 0.15)
                      : (isRejected ? AppColors.merahIndonesia.withValues(alpha: 0.15) : AppColors.goldInsignia.withValues(alpha: 0.15)),
                  child: Icon(
                    isApproved ? Icons.verified_user : (isRejected ? Icons.cancel : Icons.hourglass_empty),
                    color: isApproved ? AppColors.tniGreenAccent : (isRejected ? AppColors.merahIndonesia : AppColors.goldInsignia),
                    size: 20,
                  ),
                ),
                title: Text(op.namaLengkap, style: GoogleFonts.exo2(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${op.pangkat} • ${op.satuan} • ${op.regionalCommand}', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cyberCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Level ${op.clearanceLevel}', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyberCyan)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isApproved ? AppColors.tniGreenAccent.withValues(alpha: 0.1) : (isRejected ? AppColors.merahIndonesia.withValues(alpha: 0.1) : AppColors.goldInsignia.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        op.verificationStatus.replaceAll('_', ' '),
                        style: GoogleFonts.orbitron(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? AppColors.tniGreenDark : (isRejected ? AppColors.merahIndonesia : AppColors.goldInsignia),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

