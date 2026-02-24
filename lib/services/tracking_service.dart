import 'package:flutter/foundation.dart' show debugPrint;
import '../models/analiz_kaydi.dart';
import 'analiz_gecmisi_service.dart';
import 'notification_service.dart';

/// Periyodik takip servisi - Analiz hatırlatmaları için
class TrackingService {
  static const int reminderDays = 90; // 3 ay = 90 gün

  /// Tüm analiz kayıtları için hatırlatmaları zamanla
  static Future<void> scheduleAllReminders() async {
    try {
      // Notification servisini başlat
      await NotificationService.init();

      // Tüm analiz kayıtlarını al
      final analizler = await AnalizGecmisiService.tumAnalizleriGetir();

      // Her analiz için hatırlatma zamanla
      for (final analiz in analizler) {
        await scheduleReminderForAnalysis(analiz);
      }
    } catch (e) {
      debugPrint('Hatırlatmalar zamanlanamadı: $e');
    }
  }

  /// Belirli bir analiz için hatırlatma zamanla
  static Future<void> scheduleReminderForAnalysis(AnalizKaydi analiz) async {
    try {
      // Notification servisini başlat
      await NotificationService.init();

      // Analiz ID'sini notification ID olarak kullan (hash ile)
      final notificationId = analiz.id.hashCode;

      // 3 ay sonrası hatırlatması zamanla
      await NotificationService.scheduleAnalysisReminder(
        notificationId: notificationId,
        analysisDate: analiz.tarih,
        buildingName: analiz.binaAdi,
      );
    } catch (e) {
      debugPrint('Analiz hatırlatması zamanlanamadı: $e');
    }
  }

  /// Yeni analiz kaydı eklendiğinde hatırlatma zamanla
  static Future<void> onNewAnalysisAdded(AnalizKaydi analiz) async {
    await scheduleReminderForAnalysis(analiz);
  }

  /// Analiz hatırlatmasını iptal et
  static Future<void> cancelReminderForAnalysis(AnalizKaydi analiz) async {
    try {
      final notificationId = analiz.id.hashCode;
      await NotificationService.cancelNotification(notificationId);
    } catch (e) {
      debugPrint('Hatırlatma iptal edilemedi: $e');
    }
  }

  /// Bir analizin hatırlatma tarihini kontrol et
  // FIX: null döndürmez, DateTime? tipi kaldırıldı
  static DateTime getReminderDate(AnalizKaydi analiz) {
    return analiz.tarih.add(const Duration(days: reminderDays));
  }

  /// Hatırlatma tarihi geçmiş mi?
  static bool isReminderDue(AnalizKaydi analiz) {
    return DateTime.now().isAfter(getReminderDate(analiz));
  }

  /// Hatırlatmaya kaç gün kaldı?
  static int daysUntilReminder(AnalizKaydi analiz) {
    final reminderDate = getReminderDate(analiz);
    final now = DateTime.now();
    if (now.isAfter(reminderDate)) return 0; // Süre geçmiş
    return reminderDate.difference(now).inDays;
  }

  /// Tüm hatırlatmaları iptal et
  static Future<void> cancelAllReminders() async {
    await NotificationService.cancelAllNotifications();
  }
}

