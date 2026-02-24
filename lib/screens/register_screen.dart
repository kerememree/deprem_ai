import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../l10n/app_strings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Google ile kayıt/giriş ──────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } on AuthException catch (e) {
      if (mounted) _showError(e.userMessage);
    } catch (e) {
      if (mounted) _showError('Google ile giriş yapılamadı. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Email ile kayıt ─────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      setState(() => _isLoading = false);

      if (mounted) {
        // Email doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacementNamed('/verify-email');
      }
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError(e.userMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('Kayıt olurken hata oluştu: ${e.toString()}');
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

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            t('register_screen_title'),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Başlık ────────────────────────────────────────────────
                Text(
                  t('register_welcome_title'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('register_welcome_subtitle'),
                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                ),
                const SizedBox(height: 24),

                // ── Google Butonu ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Ayırıcı ───────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider(color: Color(0x22FFFFFF))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(t('or_register_with_email'),
                        style: const TextStyle(
                            color: Colors.white30, fontSize: 12)),
                  ),
                  const Expanded(child: Divider(color: Color(0x22FFFFFF))),
                ]),

                const SizedBox(height: 20),

                // ── Form ──────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ad Soyad
                      _label(t('full_name')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco(
                            hint: t('full_name_hint'),
                            icon: Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return t('full_name_required');
                          }
                          if (v.trim().length < 2) {
                            return t('full_name_short');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _label(t('email')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco(
                            hint: t('email_hint'),
                            icon: Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return t('email_required');
                          if (!v.contains('@') || !v.contains('.')) {
                            return t('email_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Şifre
                      _label(t('password')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco(
                          hint: t('password_min_chars'),
                          icon: Icons.lock_outline,
                          suffix: _eyeIcon(
                              _obscurePassword,
                              () => setState(
                                  () => _obscurePassword = !_obscurePassword)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return t('password_required');
                          if (v.length < 6) return t('password_short');
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Şifre Tekrar
                      _label(t('password_confirm_label')),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        style: const TextStyle(color: Colors.white),
                        decoration: _deco(
                          hint: t('password_confirm_hint'),
                          icon: Icons.lock_outline,
                          suffix: _eyeIcon(
                              _obscureConfirm,
                              () => setState(
                                  () => _obscureConfirm = !_obscureConfirm)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return t('password_confirm_required');
                          }
                          if (v != _passwordController.text) {
                            return t('password_mismatch');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Kayıt Ol Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4361EE),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  t('create_account_btn'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Giriş yap linki
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t('have_account'),
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              t('sign_in_link'),
                              style: const TextStyle(
                                color: Color(0xFF7B9FFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Yardımcı widget'lar ─────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
      );

  InputDecoration _deco(
      {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1C2E4A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF4361EE), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: Colors.white38,
          size: 20,
        ),
        onPressed: onTap,
      );
}

// ── Google "G" Logo Painter ────────────────────────────────────────────────────

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
