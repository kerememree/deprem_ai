import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Uygulama genelinde analytics ve hata takibi
class AnalyticsService {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Başlat — main.dart'ta Firebase.initializeApp'ten sonra çağrılır
  static Future<void> init() async {
    try {
      // Debug modda Crashlytics'i devre dışı bırak
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Flutter hatalarını Crashlytics'e gönder
      FlutterError.onError = _crashlytics.recordFlutterFatalError;

      // Async hataları da yakala
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('AnalyticsService başlatılamadı: $e');
    }
  }

  // ─── Ekran takibi ────────────────────────────────────────────────────────

  static Future<void> ekranGoruntulendi(String ekranAdi) async {
    try {
      await _analytics.logScreenView(screenName: ekranAdi);
    } catch (_) {}
  }

  // ─── Analiz olayları ─────────────────────────────────────────────────────

  static Future<void> analizBaslatildi({
    required bool pdfVar,
    required int fotografSayisi,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'analiz_baslatildi',
        parameters: {
          'pdf_var': pdfVar ? 1 : 0,
          'fotograf_sayisi': fotografSayisi,
        },
      );
    } catch (_) {}
  }

  static Future<void> analizTamamlandi({
    required double riskSkoru,
    required String aciliyetSeviyesi,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'analiz_tamamlandi',
        parameters: {
          'risk_skoru': riskSkoru.round(),
          'aciliyet': aciliyetSeviyesi,
        },
      );
    } catch (_) {}
  }

  static Future<void> analizHatasi(String hataTipi) async {
    try {
      await _analytics.logEvent(
        name: 'analiz_hatasi',
        parameters: {'hata_tipi': hataTipi},
      );
    } catch (_) {}
  }

  // ─── PDF ve paylaşım ─────────────────────────────────────────────────────

  static Future<void> pdfOlusturuldu() async {
    try {
      await _analytics.logEvent(name: 'pdf_olusturuldu');
    } catch (_) {}
  }

  // ─── Kullanıcı olayları ───────────────────────────────────────────────────

  static Future<void> kullanicıGirisYapti() async {
    try {
      await _analytics.logLogin(loginMethod: 'email');
    } catch (_) {}
  }

  static Future<void> kullaniciKayitOldu() async {
    try {
      await _analytics.logSignUp(signUpMethod: 'email');
    } catch (_) {}
  }

  // ─── Hata kayıt ──────────────────────────────────────────────────────────

  static Future<void> hataKaydet(
    dynamic hata,
    StackTrace? stack, {
    bool fatal = false,
    String? aciklama,
  }) async {
    try {
      if (aciklama != null) {
        await _crashlytics.log(aciklama);
      }
      await _crashlytics.recordError(hata, stack, fatal: fatal);
    } catch (_) {}
  }
}
