import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../core/exceptions/app_exceptions.dart';

/// Local notification servisi - Periyodik takip hatırlatmaları için
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Notification servisini başlat
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Timezone verilerini yükle
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Android ayarları
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS ayarları
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android için izinleri iste
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Notification servisi başlatılamadı: $e');
    }
  }

  /// Notification tıklandığında çağrılır
  static void _onNotificationTapped(NotificationResponse response) {
    // Burada navigation yapılabilir
    debugPrint('Notification tıklandı: ${response.payload}');
  }

  /// Zamanlanmış bildirim gönder (3 ay sonra analiz hatırlatması)
  static Future<void> scheduleAnalysisReminder({
    required int notificationId,
    required DateTime analysisDate,
    String? buildingName,
  }) async {
    try {
      if (!_initialized) {
        await init();
      }

      // 3 ay sonrasını hesapla
      final reminderDate = analysisDate.add(const Duration(days: 90));
      final now = DateTime.now();

      // Eğer 3 ay geçmişse, hemen göster (1 dakika sonra)
      final scheduledDate = reminderDate.isBefore(now)
          ? now.add(const Duration(minutes: 1))
          : reminderDate;

      final binaAdi = buildingName ?? 'Binanız';
      const title = 'Deprem Riski Analizi Hatırlatması';
      final body =
          '$binaAdi için son analiz ${_formatDate(analysisDate)} tarihinde yapıldı. 3 ay geçti, yeniden analiz yapmanız önerilir.';

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'analysis_reminder_channel',
            'Analiz Hatırlatmaları',
            channelDescription: 'Deprem risk analizi periyodik hatırlatmaları',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Bildirim zamanlanamadı: $e');
      throw Exception(
        'Bildirim zamanlanamadı: ${e.toString()}',
      );
    }
  }

  /// Tüm zamanlanmış bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Bildirimler iptal edilemedi: $e');
    }
  }

  /// Belirli bir bildirimi iptal et
  static Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
    } catch (e) {
      debugPrint('Bildirim iptal edilemedi: $e');
    }
  }

  /// Tarih formatla
  static String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

