import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../main.dart' show CommandCenterScreen;
import '../core/constants/app_constants.dart';
import '../core/config/supabase_config.dart';
import '../core/services/auth_blockchain_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _cardCtrl.dispose();
    _nikController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // ── Dummy accounts untuk juri/reviewer ─────────────────────────────────────
  static const List<Map<String, String>> _dummyAccounts = [
    {
      'role': 'ADMIN SISTEM',
      'nama': 'Admin Pusat Siber',
      'nik': 'JURI001',
      'email': 'juri001admin@gmail.com',
      'password': 'Admin@Siber2045',
      'wilayah': 'MABES SATSIBER',
      'clearance': 'Level 5 — TOP SECRET',
      'colorHex': 'red',
    },
    {
      'role': 'PANGLIMA WILAYAH',
      'nama': 'Pangdam Jaya',
      'nik': 'JURI002',
      'email': 'juri002@gmail.com',
      'password': 'Jenderal@Siber2045',
      'wilayah': 'Kodam Jaya',
      'clearance': 'Level 4 — SECRET',
      'colorHex': 'gold',
    },
    {
      'role': 'KOMANDAN SATSIBER',
      'nama': 'Komandan Satsiber',
      'nik': 'JURI003',
      'email': 'juri003@gmail.com',
      'password': 'Komandan@Siber2045',
      'wilayah': 'SATSIBER TNI AD',
      'clearance': 'Level 3 — CONFIDENTIAL',
      'colorHex': 'cyan',
    },
    {
      'role': 'OPERATOR (PENDING)',
      'nama': 'Operator Lapangan',
      'nik': 'JURI004',
      'email': 'juri004@gmail.com',
      'password': 'Operator@Siber2045',
      'wilayah': 'Kodam Jaya',
      'clearance': 'Level 1 — PENDING',
      'colorHex': 'grey',
    },
  ];

  void _fillDummyCredentials({required String email, required String password, required String nama}) {
    setState(() {
      _nikController.text = email;
      _passController.text = password;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.key_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data dummy $nama telah diisi otomatis.',
                style: GoogleFonts.exo2(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.tniGreenAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final rawUser = _nikController.text.trim();
    final inputUser = rawUser.replaceAll(' ', '').toUpperCase();
    final inputPass = _passController.text.trim();

    setState(() => _loading = true);

    // Coba otentikasi via Supabase Auth jika service aktif
    if (SupabaseConfig.isConfigured) {
      final res = await AuthBlockchainService().loginOperator(
        identifier: rawUser,
        password: inputPass,
      );

      if (res['success'] == true) {
        // Cari nama akun dari daftar dummy berdasarkan email/NIK yang diinput
        final matchedAcc = _dummyAccounts.firstWhere(
          (acc) => rawUser == acc['email'] || inputUser == acc['nik'],
          orElse: () => {'nama': rawUser, 'role': 'OPERATOR'},
        );
        final loginNama = matchedAcc['nama'] ?? rawUser;
        final loginRole = matchedAcc['role'] ?? 'OPERATOR';

        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AKSES KOMANDO DITERIMA: Selamat Bertugas, $loginRole — $loginNama!',
                    style: GoogleFonts.exo2(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.tniGreenAccent,
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const CommandCenterScreen(),
            transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Cari akun dummy yang cocok berdasarkan email atau NIK
    final matchedAccount = _dummyAccounts.firstWhere(
      (acc) =>
          (rawUser == acc['email'] || inputUser == acc['nik']!) &&
          inputPass == acc['password'],
      orElse: () => {},
    );

    if (matchedAccount.isEmpty) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AKSES DITOLAK! Gunakan salah satu akun demo dari panel di atas (ISI OTOMATIS)',
                  style: GoogleFonts.exo2(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.merahIndonesia,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final loginNama = matchedAccount['nama'] ?? 'Personel';
    final loginRole = matchedAccount['role'] ?? '';

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AKSES KOMANDO DITERIMA: Selamat Bertugas, $loginRole — $loginNama!',
                style: GoogleFonts.exo2(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.tniGreenAccent,
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const CommandCenterScreen(),
        transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated background ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) => CustomPaint(
              size: size, painter: _AuthBgPainter(_bgCtrl.value, true),
            ),
          ),

          // ── Grid overlay ────────────────────────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Center card ─────────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        width: math.min(480, size.width - 48),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.glassBorder, width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyberCyan.withValues(alpha: 0.15),
                              blurRadius: 50, spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildQuickFillBanner(),
                              _buildNIKField(),
                              const SizedBox(height: 16),
                              _buildPasswordField(),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text('Lupa kata sandi?',
                                      style: GoogleFonts.exo2(
                                        fontSize: 12, color: AppColors.cyberCyan,
                                      )),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildLoginButton(),
                              const SizedBox(height: 24),
                              _buildDivider(),
                              const SizedBox(height: 20),
                              _buildRegisterLink(),
                              const SizedBox(height: 24),
                              _buildFooterNote(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Back button ─────────────────────────────────────────────────────
          Positioned(
            top: 16, left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.75),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      // Logo image (Transparent Background)
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: AppColors.merahIndonesia.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Image.asset(
          'assets/images/sicakrawala_logo.png',
          width: 80, height: 80,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(height: 16),
      Text('MASUK SISTEM',
          style: GoogleFonts.orbitron(
            fontSize: 18, fontWeight: FontWeight.w900,
            color: AppColors.textPrimary, letterSpacing: 2.5,
          )),
      const SizedBox(height: 4),
      Text(AppConstants.appFullName,
          style: GoogleFonts.exo2(
            fontSize: 10, color: AppColors.cyberCyan,
            letterSpacing: 2, fontWeight: FontWeight.w700,
          )),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.merahIndonesia.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.merahIndonesia.withValues(alpha: 0.25)),
        ),
        child: Text('🔐 ${AppConstants.classification}',
            style: GoogleFonts.shareTechMono(
              fontSize: 9, color: AppColors.merahIndonesia, letterSpacing: 1,
            )),
      ),
    ]);
  }

  Widget _buildQuickFillBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cyberCyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyberCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.cyberCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: AppColors.cyberCyan, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'AKUN DEMO — UNTUK JURI & REVIEWER',
                style: GoogleFonts.orbitron(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary, letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._dummyAccounts.map((acc) => _buildDummyAccountCard(acc)),
        ],
      ),
    );
  }

  Widget _buildDummyAccountCard(Map<String, String> acc) {
    final colorHex = acc['colorHex']!;
    Color roleColor;
    IconData roleIcon;
    switch (colorHex) {
      case 'red':
        roleColor = AppColors.merahIndonesia;
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case 'gold':
        roleColor = AppColors.goldInsignia;
        roleIcon = Icons.military_tech_rounded;
        break;
      case 'cyan':
        roleColor = AppColors.cyberCyan;
        roleIcon = Icons.shield_rounded;
        break;
      default:
        roleColor = AppColors.textMuted;
        roleIcon = Icons.person_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: roleColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(roleIcon, color: roleColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        acc['role']!,
                        style: GoogleFonts.orbitron(
                          fontSize: 7.5, fontWeight: FontWeight.w900,
                          color: roleColor, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      acc['clearance']!,
                      style: GoogleFonts.shareTechMono(fontSize: 7.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${acc['nama']!}  •  ${acc['wilayah']!}',
                  style: GoogleFonts.exo2(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '📧 ${acc['email']!}  🔑 ${acc['password']!}',
                  style: GoogleFonts.shareTechMono(fontSize: 9, color: AppColors.tniGreenDark),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _fillDummyCredentials(
              email: acc['email']!,
              password: acc['password']!,
              nama: acc['nama']!,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            child: Text(
              'ISI\nOTOMATIS',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(fontSize: 7.5, fontWeight: FontWeight.w900, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNIKField() {
    return TextFormField(
      controller: _nikController,
      keyboardType: TextInputType.text,
      style: GoogleFonts.exo2(fontSize: 14, color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Email Dinas / NIK / Nama Pengguna',
        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.cyberCyan),
        hintText: 'Contoh: juri001admin@gmail.com atau JURI001',
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Email atau NIK tidak boleh kosong' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passController,
      obscureText: _obscure,
      style: GoogleFonts.exo2(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Kata Sandi',
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.cyberCyan),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textMuted),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        hintText: 'Contoh: Admin@Siber2045',
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi tidak boleh kosong' : null,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.redGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.merahIndonesia.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _loading ? null : _doLogin,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.login_rounded, color: Colors.white, size: 20),
          label: Text(
            _loading ? 'MEMVERIFIKASI...' : 'AKSES KOMANDO',
            style: GoogleFonts.orbitron(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Container(height: 1, color: AppColors.glassBorder)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('ATAU', style: GoogleFonts.shareTechMono(fontSize: 10, color: AppColors.textMuted)),
      ),
      Expanded(child: Container(height: 1, color: AppColors.glassBorder)),
    ]);
  }

  Widget _buildRegisterLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Belum punya akun? ', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
      GestureDetector(
        onTap: () {
          Navigator.pop(context);
          // Let landing page handle register navigation
        },
        child: Text('Daftar Sekarang',
            style: GoogleFonts.exo2(
              fontSize: 12, color: AppColors.cyberCyan,
              fontWeight: FontWeight.w700, decoration: TextDecoration.underline,
            )),
      ),
    ]);
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tniGreenDark.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tniGreenAccent.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text('🌟 INDONESIA EMAS 2045',
            style: GoogleFonts.orbitron(
              fontSize: 9, fontWeight: FontWeight.w800,
              color: AppColors.goldInsignia, letterSpacing: 2,
            )),
        const SizedBox(height: 4),
        Text('Karya: NAZARUL QUDRI  •  SATSIBER TNI AD',
            style: GoogleFonts.exo2(
              fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5,
            )),
      ]),
    );
  }
}

// ── Shared painters ───────────────────────────────────────────────────────────

class _AuthBgPainter extends CustomPainter {
  final double t;
  final bool isLogin;
  _AuthBgPainter(this.t, this.isLogin);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isLogin
                ? const [Color(0xFFF8FAFF), Color(0xFFEEF5FF), Color(0xFFF5F0FF)]
                : const [Color(0xFFF8FFFC), Color(0xFFEEFFF5), Color(0xFFF0F8FF)],
          ).createShader(rect));

    // Orb 1 - animated
    final c1x = size.width * 0.15 + 30 * math.sin(t * 2 * math.pi);
    final c1y = size.height * 0.3;
    canvas.drawCircle(Offset(c1x, c1y), 260,
        Paint()..shader = RadialGradient(colors: [
          isLogin ? const Color(0x1ACC0001) : const Color(0x1A40916C),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(c1x, c1y), radius: 260)));

    // Orb 2 - animated
    final c2x = size.width * 0.85;
    final c2y = size.height * 0.65 + 25 * math.cos(t * 2 * math.pi);
    canvas.drawCircle(Offset(c2x, c2y), 300,
        Paint()..shader = RadialGradient(colors: [
          const Color(0x1500C6FF), Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(c2x, c2y), radius: 300)));
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => old.t != t;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0A00C6FF)..strokeWidth = 0.7;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
