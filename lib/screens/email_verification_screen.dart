import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  Timer? _resendCooldownTimer;
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0; // saniye cinsinden bekleme süresi
  String? _userEmail;

  late final AnimationController _iconAnimController;
  late final Animation<double> _iconAnim;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _iconAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _iconAnimController, curve: Curves.easeInOut),
    );

    _loadEmail();
    // Ekran açılır açılmaz email gönder, ardından periyodik kontrol başlat
    _sendEmailOnInit();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendCooldownTimer?.cancel();
    _iconAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService.getUserEmail();
    if (mounted) setState(() => _userEmail = email);
  }

  // ── Ekran açılınca otomatik email gönder ────────────────────────────────────
  Future<void> _sendEmailOnInit() async {
    try {
      // Zaten doğrulanmışsa direkt geç
      final verified = await AuthService.isEmailVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }
      // Doğrulama emailini gönder
      await AuthService.sendEmailVerification();
      // Cooldown başlat (60sn boyunca yeniden gönder butonu pasif)
      if (mounted) {
        setState(() => _resendCooldown = 60);
        _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) { t.cancel(); return; }
          setState(() {
            _resendCooldown--;
            if (_resendCooldown <= 0) t.cancel();
          });
        });
      }
    } catch (_) {
      // too-many-requests → kayıt sırasında zaten gönderildi, sorun yok
    }
  }

  // ── Doğrulama kontrolü ──────────────────────────────────────────────────────
  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final verified = await AuthService.isEmailVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        // Onboarding + home kontrolü için AuthWrapper'a git
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (_) {
      // Sessizce geç
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // ── Email yeniden gönder ────────────────────────────────────────────────────
  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      await AuthService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('verify_resent_success')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        // 60 saniyelik cooldown başlat
        setState(() => _resendCooldown = 60);
        _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _resendCooldown--;
            if (_resendCooldown <= 0) t.cancel();
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t('verify_resend_failed_prefix')}${e.toString()}'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ── Çıkış yap (doğrulamadan vaz geç) ───────────────────────────────────────
  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
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
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _logout,
              child: Text(
                t('logout'),
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── Animasyonlu Email İkonu ─────────────────────────────────
                ScaleTransition(
                  scale: _iconAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4361EE).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4361EE).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 54,
                      color: Color(0xFF7B9FFF),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Başlık ──────────────────────────────────────────────────
                Text(
                  t('verify_email_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Açıklama ─────────────────────────────────────────────────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 15, height: 1.6),
                    children: [
                      TextSpan(text: t('verify_email_sent_to')),
                      TextSpan(
                        text: _userEmail ?? '...',
                        style: const TextStyle(
                          color: Color(0xFF7B9FFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Spam uyarısı - daha belirgin
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        t('verify_email_spam'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Kontrol Et Butonu ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4361EE),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                t('verify_confirm_btn'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Yeniden Gönder Butonu ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: (_resendCooldown > 0 || _isResending)
                        ? null
                        : _resendEmail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0x44FFFFFF), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      disabledForegroundColor: Colors.white30,
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white54),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? '${t('verify_resend_countdown')} (${_resendCooldown}s)'
                                : t('verify_resend_btn'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _resendCooldown > 0
                                  ? Colors.white30
                                  : Colors.white70,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Alt Bilgi ─────────────────────────────────────────────
                Text(
                  t('verify_auto_detect'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
