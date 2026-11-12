import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/config/supabase_config.dart';
import '../core/services/auth_blockchain_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _pangkatCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreed = false;
  int _step = 0; // 0=personal, 1=credentials, 2=done

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
    for (final c in [_namaCtrl, _nikCtrl, _pangkatCtrl, _satuanCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (!_formKey.currentState!.validate()) return;
    if (_step == 0) {
      setState(() => _step = 1);
      _cardCtrl.reset();
      _cardCtrl.forward();
    } else if (_step == 1) {
      if (!_agreed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Anda harus menyetujui ketentuan keamanan',
              style: GoogleFonts.exo2()),
          backgroundColor: AppColors.merahIndonesia,
        ));
        return;
      }
      setState(() => _loading = true);

      // Integrasi Supabase jika aktif terhubung
      if (SupabaseConfig.isConfigured) {
        final res = await AuthBlockchainService().registerOperator(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          namaLengkap: _namaCtrl.text.trim(),
          nik: _nikCtrl.text.trim(),
          pangkat: _pangkatCtrl.text.trim(),
          satuan: _satuanCtrl.text.trim(),
        );

        if (!mounted) return;
        setState(() => _loading = false);

        if (res['success'] == true) {
          setState(() => _step = 2);
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message']?.toString() ?? 'Gagal mendaftarkan operator.',
                style: GoogleFonts.exo2()),
            backgroundColor: AppColors.merahIndonesia,
          ));
          return;
        }
      }

      // Fallback demo/offline
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() { _loading = false; _step = 2; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) => CustomPaint(
              size: size, painter: _AuthBgPainter(_bgCtrl.value, false),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

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
                        width: math.min(520, size.width - 48),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.84),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.glassBorderGreen, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tniGreenAccent.withValues(alpha: 0.15),
                              blurRadius: 50, spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: _step == 2
                              ? _buildSuccessScreen()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: 24),
                                    _buildStepIndicator(),
                                    const SizedBox(height: 28),
                                    if (_step == 0) ..._buildStep0(),
                                    if (_step == 1) ..._buildStep1(),
                                    const SizedBox(height: 24),
                                    _buildNextButton(),
                                    const SizedBox(height: 16),
                                    _buildLoginLink(),
                                    const SizedBox(height: 20),
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

          Positioned(
            top: 16, left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.75)),
                onPressed: () {
                  if (_step > 0) {
                    setState(() => _step--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 76, height: 76,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: AppColors.tniGreenAccent.withValues(alpha: 0.30), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Image.asset(
          'assets/images/sicakrawala_logo.png',
          width: 76, height: 76,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(height: 14),
      Text('PENDAFTARAN ANGGOTA',
          style: GoogleFonts.orbitron(
            fontSize: 15, fontWeight: FontWeight.w900,
            color: AppColors.textPrimary, letterSpacing: 2,
          )),
      const SizedBox(height: 4),
      Text(AppConstants.appFullName,
          style: GoogleFonts.exo2(
            fontSize: 10, color: AppColors.tniGreenNeon,
            letterSpacing: 2, fontWeight: FontWeight.w700,
          )),
    ]);
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 28 : 22, height: active ? 28 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done || active ? AppColors.greenGradient : null,
                  color: done || active ? null : AppColors.backgroundShade,
                  border: Border.all(
                    color: done || active ? AppColors.tniGreenAccent : AppColors.glassBorder,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : Text('${i + 1}',
                          style: GoogleFonts.orbitron(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: active ? Colors.white : AppColors.textMuted,
                          )),
                ),
              ),
              if (i < 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: _step > i ? AppColors.greenGradient : null,
                      color: _step > i ? null : AppColors.backgroundShade,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildStep0() {
    return [
      _field('Nama Lengkap', Icons.person_outline, _namaCtrl, 'Nama sesuai identitas militer'),
      const SizedBox(height: 14),
      _field('NIK Prajurit', Icons.badge_outlined, _nikCtrl, 'Nomor identitas prajurit',
          keyboard: TextInputType.number),
      const SizedBox(height: 14),
      _field('Pangkat', Icons.military_tech_outlined, _pangkatCtrl, 'cth: Kolonel, Mayor, Kapten...'),
      const SizedBox(height: 14),
      _field('Satuan / Unit', Icons.account_balance_outlined, _satuanCtrl, 'cth: SATSIBER TNI AD'),
    ];
  }

  List<Widget> _buildStep1() {
    return [
      _field('Email Dinas', Icons.email_outlined, _emailCtrl, 'email@tni-ad.mil.id',
          keyboard: TextInputType.emailAddress),
      const SizedBox(height: 14),
      _field('Kata Sandi', Icons.lock_outline_rounded, _passCtrl, 'Min. 8 karakter',
          obscure: _obscurePass,
          toggleObscure: () => setState(() => _obscurePass = !_obscurePass)),
      const SizedBox(height: 14),
      _field('Konfirmasi Kata Sandi', Icons.lock_reset_rounded, _confirmCtrl, 'Ulangi kata sandi',
          obscure: _obscureConfirm,
          toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          extraValidator: (v) => v != _passCtrl.text ? 'Kata sandi tidak cocok' : null),
      const SizedBox(height: 16),
      // Terms checkbox
      GestureDetector(
        onTap: () => setState(() => _agreed = !_agreed),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: _agreed ? AppColors.greenGradient : null,
                border: Border.all(
                  color: _agreed ? AppColors.tniGreenAccent : AppColors.glassBorder,
                  width: 1.5,
                ),
              ),
              child: _agreed
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Saya menyetujui Ketentuan Keamanan Siber TNI AD, Protokol Zero-Trust, dan Perjanjian Non-Disclosure Taktis.',
                style: GoogleFonts.exo2(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSuccessScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.tniGreenAccent.withValues(alpha: 0.4), blurRadius: 30),
            ],
          ),
          child: const Center(child: Icon(Icons.verified, color: Colors.white, size: 48)),
        ),
        const SizedBox(height: 24),
        Text('PENDAFTARAN BERHASIL',
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w900,
              color: AppColors.textPrimary, letterSpacing: 2,
            )),
        const SizedBox(height: 12),
        Text(
          'Akun Anda sedang diverifikasi oleh SATSIBER TNI AD.\nAnda akan menerima konfirmasi melalui email dinas.',
          textAlign: TextAlign.center,
          style: GoogleFonts.exo2(fontSize: 13, color: AppColors.textSecondary, height: 1.7),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.redGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.merahIndonesia.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
              label: Text('KEMBALI KE BERANDA',
                  style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildFooterNote(),
      ],
    );
  }

  Widget _buildNextButton() {
    final isLastStep = _step == 1;
    return SizedBox(
      width: double.infinity, height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.tniGreenAccent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _loading ? null : _nextStep,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(isLastStep ? Icons.send_rounded : Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          label: Text(
            _loading ? 'MEMPROSES...' : (isLastStep ? 'KIRIM PENDAFTARAN' : 'LANJUTKAN'),
            style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Sudah punya akun? ', style: GoogleFonts.exo2(fontSize: 12, color: AppColors.textMuted)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text('Masuk Sekarang',
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
            style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.goldInsignia, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text('Karya: NAZARUL QUDRI  •  SATSIBER TNI AD',
            style: GoogleFonts.exo2(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    bool? obscure,
    VoidCallback? toggleObscure,
    String? Function(String?)? extraValidator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure ?? false,
      style: GoogleFonts.exo2(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.tniGreenAccent, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted),
                onPressed: toggleObscure,
              )
            : null,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '$label tidak boleh kosong';
        return extraValidator?.call(v);
      },
    );
  }
}

// ── Shared painters (same as in login_view.dart but local copies to avoid cross-file issues) ─────

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

    final c1x = size.width * 0.15 + 30 * math.sin(t * 2 * math.pi);
    final c1y = size.height * 0.3;
    canvas.drawCircle(Offset(c1x, c1y), 260,
        Paint()..shader = RadialGradient(colors: [
          isLogin ? const Color(0x1ACC0001) : const Color(0x1A40916C),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(c1x, c1y), radius: 260)));

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
    final paint = Paint()..color = const Color(0x0A40916C)..strokeWidth = 0.7;
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
