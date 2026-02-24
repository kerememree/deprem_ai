import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class DepremBilgilendirmeScreen extends StatefulWidget {
  const DepremBilgilendirmeScreen({super.key});

  @override
  State<DepremBilgilendirmeScreen> createState() =>
      _DepremBilgilendirmeScreenState();
}

class _DepremBilgilendirmeScreenState
    extends State<DepremBilgilendirmeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Çanta öğelerinin sırası (indeks bazlı kayıt için sabit liste)
  static const _cantaOgeleri = [
    'Su (kişi başı en az 3 litre)',
    'Enerji verici gıdalar (bisküvi, konserve, kuruyemiş)',
    'İlk yardım çantası',
    'El feneri ve yedek pil',
    'Pilli/el radyosu ve yedek pil',
    'Düdük (enkaz altında ses çıkarmak için)',
    'Yedek kıyafet ve sağlam ayakkabı',
    'Kişisel ilaçlar ve reçete kopyası',
    'Önemli belgeler (kimlik, tapu, sigorta — fotokopi)',
    'Nakit para (küçük bozuk)',
    'Çakı, kibrit, mum',
    'Battaniye veya uyku tulumu',
    'Powerbank ve şarj kabloları',
    'N95 maske (toz için)',
    'Islak mendil ve dezenfektan',
  ];

  static const _prefsPrefix = 'deprem_cantasi_';

  late Map<String, bool> _depremCantasiChecklist;

  @override
  void initState() {
    super.initState();
    // Varsayılan olarak hepsi false
    _depremCantasiChecklist = {
      for (final oge in _cantaOgeleri) oge: false,
    };
    _tabController = TabController(length: 4, vsync: this);
    _checklistYukle();
  }

  /// SharedPreferences'tan kayıtlı durumu yükle
  Future<void> _checklistYukle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _cantaOgeleri.length; i++) {
        _depremCantasiChecklist[_cantaOgeleri[i]] =
            prefs.getBool('$_prefsPrefix$i') ?? false;
      }
    });
  }

  /// Tek bir öğenin durumunu kaydet
  Future<void> _checklistKaydet(String oge, bool deger) async {
    final index = _cantaOgeleri.indexOf(oge);
    if (index < 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$index', deger);
  }

  /// Tüm listeyi sıfırla
  Future<void> _checklistSifirla() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _cantaOgeleri.length; i++) {
      await prefs.remove('$_prefsPrefix$i');
    }
    if (!mounted) return;
    setState(() {
      for (final oge in _cantaOgeleri) {
        _depremCantasiChecklist[oge] = false;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _aramaYap(String telefon) async {
    final Uri telUri = Uri(scheme: 'tel', path: telefon);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama yapılamadı: $telefon')),
        );
      }
    }
  }

  Future<void> _depremCantasiPaylas() async {
    final tamamlanan =
        _depremCantasiChecklist.entries.where((e) => e.value).length;
    final toplam = _depremCantasiChecklist.length;

    final StringBuffer sb = StringBuffer();
    sb.writeln('DEPREM ÇANTASI DURUM RAPORU');
    sb.writeln('Tamamlanan: $tamamlanan / $toplam\n');

    for (final entry in _depremCantasiChecklist.entries) {
      sb.writeln('${entry.value ? "✅" : "⬜"} ${entry.key}');
    }

    sb.writeln(
        '\nNOT: Çantanızı kolay erişilebilir bir yerde bulundurun ve 6 ayda bir kontrol edin.');

    await Share.share(sb.toString(), subject: 'Deprem Çantası Durumu');
  }

  Future<void> _videoAc(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video açılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deprem Bilgilendirme'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Öncesi', icon: Icon(Icons.warning, size: 20)),
            Tab(text: 'Sırasında', icon: Icon(Icons.access_alarm, size: 20)),
            Tab(text: 'Sonrası', icon: Icon(Icons.emergency, size: 20)),
            Tab(text: 'Çantam', icon: Icon(Icons.checklist, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOncesiTab(),
          _buildSirasindaTab(),
          _buildSonrasiTab(),
          _buildChecklistTab(),
        ],
      ),
    );
  }

  // ─── ÖNCESİ TAB ──────────────────────────────────────────────────────────────

  Widget _buildOncesiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVideoKarti(
            title: 'Deprem Öncesi Hazırlık',
            description:
                'Deprem öncesi ev hazırlığı, deprem çantası ve aile planı hakkında bilgilendirici video.',
            videoUrl: 'https://www.youtube.com/watch?v=6k2QNfmN4mw',
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.home,
            title: 'Ev Hazırlığı',
            items: const [
              'Ağır eşyaları (kütüphane, buzdolabı) duvarlara sabitleyin',
              'Rafları ve dolapları duvara monte edin',
              'Cam ve ağır eşyaları alt raflara taşıyın',
              'Yangın söndürücü edinin ve kullanımını öğrenin',
              'Doğalgaz ve su ana vanalarının yerini öğrenin',
              'Çıkış kapılarının yakınına ağır eşya koymayın',
            ],
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.family_restroom,
            title: 'Aile Planı',
            items: const [
              'Binanın dışında bir toplanma noktası belirleyin',
              'Farklı şehirde yaşayan bir iletişim kişisi belirleyin',
              'Acil durum iletişim listesini herkesin erişebileceği yere asın',
              'Çocuklara ÇÖK-KAPAN-TUTUN hareketini öğretin',
              'Her aile bireyinin deprem çantasının yerini bilmesini sağlayın',
              'Yılda en az bir kez deprem tatbikatı yapın',
            ],
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.construction,
            title: 'Yapısal Hazırlık',
            items: const [
              'Binanızın deprem yönetmeliğine uygunluğunu uzman mühendise kontrol ettirin',
              'Tespit edilen yapısal hasarları ihmal etmeyin',
              'Bacaların ve çıkıntı elemanlarının durumunu kontrol ettirin',
              'Komşularınızı da yapısal kontrol konusunda bilgilendirin',
              'Binanın yapım yılını ve beton sınıfını öğrenin',
            ],
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // ─── SIRASINDA TAB ───────────────────────────────────────────────────────────

  Widget _buildSirasindaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVideoKarti(
            title: 'Deprem Sırasında Ne Yapmalı?',
            description:
                'Deprem anında ÇÖK-KAPAN-TUTUN hareketinin doğru uygulanışı ve yapılmaması gerekenler.',
            videoUrl: 'https://www.youtube.com/watch?v=oZeI0X40EEY&t=12s',
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.hide_source,
            title: 'ÇÖK — KAPAN — TUTUN',
            color: Colors.red,
            customWidget: _buildCokKapanTutun(),
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.apartment,
            title: 'Bina İçindeyken',
            items: const [
              'Pencerelerden, camdan ve ağır eşyalardan uzaklaşın',
              'Kapı eşiklerine sığınmayın — sizi korumaz',
              'Asansörü kesinlikle kullanmayın',
              'Sarsıntı süresince bina içinde kalın, koşarak çıkmaya çalışmayın',
              'Balkonlara ve balkon kapılarına yaklaşmayın',
              'Sarsıntı tamamen bitene kadar yerinizden ayrılmayın',
            ],
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.directions_car,
            title: 'Araç İçindeyken',
            items: const [
              'Aracı yavaşça güvenli bir noktaya çekin ve durdurun',
              'Köprü, viyadük, tünel ve binaların yakınından uzaklaşın',
              'Araç içinde kalın, kapıları kilitlemeyin',
              'Radyoyu açın, acil yayın duyurusunu bekleyin',
              'Sarsıntı bitince dikkatli ve yavaş ilerleyin',
            ],
            color: Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.nature,
            title: 'Açık Alandayken',
            items: const [
              'Binalardan, elektrik direklerinden ve ağaçlardan uzaklaşın',
              'Açık bir alana gidin ve yere çömelin',
              'Başınızı kollarınızla koruyun',
              'Deniz kıyısındaysanız hemen yüksek bir yere çıkın (tsunami riski)',
              'Sarsıntı bitene kadar yerinizde kalın',
            ],
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildCokKapanTutun() {
    final adimlar = [
      {
        'numara': 'ÇÖK',
        'aciklama':
            'Hemen yere çömelin. Diz üstü pozisyonuna geçin, vücudunuzu küçültün.',
        'renk': Colors.red,
        'icon': Icons.arrow_downward,
      },
      {
        'numara': 'KAPAN',
        'aciklama':
            'Sağlam bir masanın altına veya iç bir duvara yakın yere sığının. Başınızı ve boynunuzu kollarınızla koruyun.',
        'renk': Colors.orange,
        'icon': Icons.shield,
      },
      {
        'numara': 'TUTUN',
        'aciklama':
            'Masa altındaysanız masanın bacağını tutun. Sarsıntı süresince yerinden ayrılmayın.',
        'renk': Colors.green,
        'icon': Icons.back_hand,
      },
    ];

    return Column(
      children: adimlar.map((adim) {
        final renk = adim['renk'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: renk.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: renk.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
                child: Icon(adim['icon'] as IconData,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adim['numara'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: renk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adim['aciklama'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── SONRASI TAB ─────────────────────────────────────────────────────────────

  Widget _buildSonrasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVideoKarti(
            title: 'Deprem Sonrasında Ne Yapmalı?',
            description:
                'Deprem sonrası ilk saatlerde yapılması ve kaçınılması gerekenler; artçı sarsıntılara karşı önlemler.',
            videoUrl: 'https://www.youtube.com/watch?v=6e97auZHgcA',
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.check_circle,
            title: 'Hemen Yapılacaklar',
            items: const [
              'Önce kendi güvenliğinizi sağlayın — sakin olun',
              'Çevrenizdekilerin sağlığını kontrol edin',
              'Yangın, gaz kaçağı veya su baskını olup olmadığını kontrol edin',
              'Gaz ve elektrik ana vanalarını kapatın',
              'Artçı sarsıntılara karşı dikkatli olun — güvenli açık alanlara çıkın',
              'Hasar görmüş binaya girmeyin',
            ],
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildUyariKarti(
            baslik: '⚠️ Artçı Sarsıntılar',
            mesaj:
                'Büyük depremlerin ardından saatler veya günler içinde artçı sarsıntılar yaşanır. '
                'Bazıları ana deprem kadar güçlü olabilir. '
                'Hasar görmüş yapılardan uzak durun ve resmi açıklamaları takip edin.',
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.phone,
            title: 'Acil Durum Numaraları',
            color: Colors.blue,
            customWidget: _buildAcilDurumNumaralari(),
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.home_repair_service,
            title: 'Bina Güvenlik Kontrolü',
            items: const [
              'Binanızı dışarıdan gözlemleyin; çatlak, eğim veya çöküntü varsa girmeyin',
              'Bina içi kontrolü yetkili mühendis olmadan yapmayın',
              'Hasar tespiti için AFAD veya belediyeye başvurun',
              'Binaya "yeşil" etiket yapıştırılmadan kullanmaya çalışmayın',
              'Hasarlı komşu binaların yakınında durmayın',
            ],
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildBilgiKarti(
            icon: Icons.family_restroom,
            title: 'Ailemle Nasıl İletişim Kurarım?',
            color: Colors.purple,
            customWidget: _buildAilemiNasilBulurum(),
          ),
        ],
      ),
    );
  }

  Widget _buildUyariKarti({required String baslik, required String mesaj}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[400]!, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mesaj,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ÇANTAM TAB ──────────────────────────────────────────────────────────────

  Widget _buildChecklistTab() {
    final tamamlanan =
        _depremCantasiChecklist.entries.where((e) => e.value).length;
    final toplam = _depremCantasiChecklist.length;
    final oran = tamamlanan / toplam;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.backpack,
                            color: Colors.orange, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deprem Çantası',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Evinizin erişilebilir bir yerine hazırlayın',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: oran,
                            minHeight: 10,
                            backgroundColor: Colors.orange[100],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              oran < 0.5
                                  ? Colors.red
                                  : oran < 0.9
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$tamamlanan/$toplam',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ..._depremCantasiChecklist.entries.map((entry) {
                    return CheckboxListTile(
                      title: Text(entry.key,
                          style: const TextStyle(fontSize: 14)),
                      value: entry.value,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        final yeniDeger = value ?? false;
                        setState(() {
                          _depremCantasiChecklist[entry.key] = yeniDeger;
                        });
                        // Kalıcı kayıt
                        _checklistKaydet(entry.key, yeniDeger);
                      },
                      activeColor: Colors.orange,
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _depremCantasiPaylas,
                          icon: const Icon(Icons.share),
                          label: const Text('Listeyi Paylaş'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final onay = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Listeyi Sıfırla'),
                              content: const Text(
                                  'Tüm işaretler kaldırılsın mı?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('İptal'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white),
                                  child: const Text('Sıfırla'),
                                ),
                              ],
                            ),
                          );
                          if (onay == true) _checklistSifirla();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Sıfırla'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Not: Çantanızı 6 ayda bir gözden geçirin.\nSu ve gıda stoklarını yenileyin.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── YARDIMCI WIDGET'LAR ─────────────────────────────────────────────────────

  Widget _buildVideoKarti({
    required String title,
    required String description,
    required String videoUrl,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_circle_filled,
                      color: Colors.red, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _videoAc(videoUrl),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Videoyu İzle (YouTube)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiKarti({
    required IconData icon,
    required String title,
    List<String>? items,
    required Color color,
    Widget? customWidget,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (customWidget != null)
                customWidget
              else if (items != null)
                ...items.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration:
                        Duration(milliseconds: 300 + (entry.key * 80)),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset((1 - value) * 20, 0),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                  fontSize: 15, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcilDurumNumaralari() {
    final numaralar = [
      {
        'isim': 'Acil Çağrı Merkezi',
        'numara': '112',
        'icon': Icons.emergency_share,
      },
      {'isim': 'İtfaiye', 'numara': '110', 'icon': Icons.fire_truck},
      {'isim': 'Polis', 'numara': '155', 'icon': Icons.local_police},
      {'isim': 'Jandarma', 'numara': '156', 'icon': Icons.security},
      {'isim': 'AFAD', 'numara': '122', 'icon': Icons.warning_amber},
      {'isim': 'Kızılay', 'numara': '168', 'icon': Icons.medical_services},
    ];

    return Column(
      children: numaralar.map((numara) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _aramaYap(numara['numara'] as String),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(numara['icon'] as IconData, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          numara['isim'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          numara['numara'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.phone, color: Colors.blue[700]),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAilemiNasilBulurum() {
    final adimlar = [
      {
        'baslik': 'SMS Gönderin',
        'aciklama':
            'Telefon hatları dolup taşar. SMS çok daha hızlı iletilir. Kısa ve net mesaj gönderin.',
      },
      {
        'baslik': 'Toplanma Noktasına Gidin',
        'aciklama':
            'Önceden belirlediğiniz toplanma noktasına gidin. Tüm aile orada buluşacak şekilde plan yapın.',
      },
      {
        'baslik': 'Şehir Dışı İletişim Kişisi',
        'aciklama':
            'Farklı şehirde bir kişiyi merkezi iletişim noktası olarak belirleyin. Herkes o kişiyi arasın.',
      },
      {
        'baslik': 'AFAD Kayıp Bildirim',
        'aciklama':
            'AFAD\'ın kurduğu arama sistemine 122\'yi arayarak başvurun.',
      },
      {
        'baslik': 'Sosyal Medya Güvende miyim?',
        'aciklama':
            'Deprem sonrası Facebook ve diğer platformlardaki "Güvende miyim?" özelliğini kullanın.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: adimlar.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value['baslik']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.value['aciklama']!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
