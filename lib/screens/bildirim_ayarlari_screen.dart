import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../services/notification_service.dart';

class BildirimAyarlariScreen extends StatefulWidget {
  const BildirimAyarlariScreen({super.key});

  @override
  State<BildirimAyarlariScreen> createState() => _BildirimAyarlariScreenState();
}

class _BildirimAyarlariScreenState extends State<BildirimAyarlariScreen> {
  bool _analizHatirlatma = true;
  bool _depremUyarisi = false;
  bool _ipuclari = true;
  String _hatirlatmaAraligi = '3months';
  bool _izinVerildi = false;
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
    _izinKontrolEt();
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analizHatirlatma = prefs.getBool('notif_analiz') ?? true;
      _depremUyarisi = prefs.getBool('notif_deprem') ?? false;
      _ipuclari = prefs.getBool('notif_ipucu') ?? true;
      _hatirlatmaAraligi = prefs.getString('notif_aralik') ?? '3months';
      _yukleniyor = false;
    });
  }

  Future<void> _ayariKaydet(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _izinKontrolEt() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.areNotificationsEnabled() ?? false;
      if (mounted) setState(() => _izinVerildi = granted);
    } catch (_) {
      if (mounted) setState(() => _izinVerildi = true);
    }
  }

  Future<void> _testBildirimGonder() async {
    try {
      await NotificationService.scheduleAnalysisReminder(
        notificationId: 9999,
        analysisDate: DateTime.now().subtract(const Duration(days: 91)),
        buildingName: 'Test Binası',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t('notification_test_sent')),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Scaffold(
        appBar: AppBar(
          title: Text(t('notification_settings')),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  // İzin uyarısı
                  if (!_izinVerildi) _buildIzinBandi(),

                  // ── Bildirim türleri ──────────────────────────────────
                  _buildSectionHeader(Icons.notifications_outlined, t('notification_settings')),

                  _buildSwitchTile(
                    icon: Icons.history,
                    iconColor: Colors.blue,
                    title: t('notification_analysis_reminder'),
                    subtitle: t('notification_analysis_reminder_sub'),
                    value: _analizHatirlatma,
                    onChanged: (v) {
                      setState(() => _analizHatirlatma = v);
                      _ayariKaydet('notif_analiz', v);
                    },
                  ),

                  if (_analizHatirlatma) _buildAraliksecici(),

                  _buildSwitchTile(
                    icon: Icons.warning_amber,
                    iconColor: Colors.red,
                    title: t('notification_earthquake_alert'),
                    subtitle: t('notification_earthquake_alert_sub'),
                    value: _depremUyarisi,
                    onChanged: (v) {
                      setState(() => _depremUyarisi = v);
                      _ayariKaydet('notif_deprem', v);
                    },
                  ),

                  _buildSwitchTile(
                    icon: Icons.lightbulb_outline,
                    iconColor: Colors.orange,
                    title: t('notification_tips'),
                    subtitle: t('notification_tips_sub'),
                    value: _ipuclari,
                    onChanged: (v) {
                      setState(() => _ipuclari = v);
                      _ayariKaydet('notif_ipucu', v);
                    },
                  ),

                  const Divider(height: 32),

                  // ── Test bildirimi ────────────────────────────────────
                  _buildSectionHeader(Icons.science_outlined, 'Test'),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: _testBildirimGonder,
                      icon: const Icon(Icons.send),
                      label: Text(t('notification_test')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.blue[700]!),
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildIzinBandi() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off, color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('notification_permission_required'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(t('notification_permission_sub'),
                    style: TextStyle(color: Colors.orange[800], fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              // Ayarlardan döndükten sonra izin durumunu yeniden kontrol et
              if (mounted) await _izinKontrolEt();
            },
            child: Text(t('notification_open_settings'),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue[700],
    );
  }

  Widget _buildAraliksecici() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('notification_reminder_interval'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _aralikcip('1months', t('notification_1month')),
              _aralikcip('3months', t('notification_3months')),
              _aralikcip('6months', t('notification_6months')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aralikcip(String value, String label) {
    final secili = _hatirlatmaAraligi == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: secili,
      onSelected: (_) {
        setState(() => _hatirlatmaAraligi = value);
        _ayariKaydet('notif_aralik', value);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }
}
