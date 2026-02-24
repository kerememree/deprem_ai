import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } on AuthException catch (e) {
      if (mounted) _showError(e.userMessage);
    } catch (e) {
      if (mounted) _showError(t('google_sign_in_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guestSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.loginAsGuest();
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF050D1A),
                Color(0xFF0D1F3C),
                Color(0xFF0A1628),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Logo ─────────────────────────────────────────────
                      _buildLogo(),
                      const SizedBox(height: 32),

                      // ── Başlık ───────────────────────────────────────────
                      Text(
                        t('login_welcome_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('login_welcome_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white54,
                          height: 1.6,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── Google Butonu ────────────────────────────────────
                      _AuthButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        backgroundColor: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CustomPaint(painter: _GoogleLogoPainter()),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t('continue_with_google'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Kayıt Ol ─────────────────────────────────────────
                      _AuthButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed('/register'),
                        backgroundColor: const Color(0xFF4361EE),
                        child: Text(
                          t('register'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Giriş Yap ────────────────────────────────────────
                      _AuthButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed('/email-login'),
                        backgroundColor: Colors.transparent,
                        isOutlined: true,
                        child: Text(
                          t('login_btn'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Ayırıcı ──────────────────────────────────────────
                      Row(children: [
                        const Expanded(child: Divider(color: Color(0x22FFFFFF))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            t('or'),
                            style: const TextStyle(color: Colors.white30, fontSize: 13),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0x22FFFFFF))),
                      ]),

                      const SizedBox(height: 18),

                      // ── Misafir ───────────────────────────────────────────
                      GestureDetector(
                        onTap: _isLoading ? null : _guestSignIn,
                        child: Text(
                          t('continue_as_guest_btn'),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('guest_local_save'),
                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C4EC6), Color(0xFF4361EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.apartment_rounded, size: 54, color: Colors.white),
    );
  }
}

// ── Reusable Auth Button ────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final bool isOutlined;

  const _AuthButton({
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0x44FFFFFF), width: 1.5),
            shape: shape,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: backgroundColor == Colors.white ? 4 : 0,
          shadowColor: backgroundColor == Colors.white ? Colors.black26 : Colors.transparent,
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}

// ── Google "G" Logo Painter ─────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  static const double _r = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.22;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - sw / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 305 * _r, 110 * _r, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 55 * _r, 75 * _r, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 130 * _r, 100 * _r, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 230 * _r, 75 * _r, false, paint);

    paint
      ..color = const Color(0xFF4285F4)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.93, size.height * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
