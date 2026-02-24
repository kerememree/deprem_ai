import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/deprem_api_service.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import '../core/exceptions/app_exceptions.dart';

// ─── Fay Hattı Modeli ─────────────────────────────────────────────────────────

enum RiskSeviyesi { cokYuksek, yuksek, orta }

class FayHatti {
  final String id;
  final String ad;
  final String kisaAd;
  final RiskSeviyesi risk;
  final List<LatLng> noktalar;
  final String aciklama;
  final String uzunluk;
  final String sonBuyukDeprem;

  const FayHatti({
    required this.id,
    required this.ad,
    required this.kisaAd,
    required this.risk,
    required this.noktalar,
    required this.aciklama,
    required this.uzunluk,
    required this.sonBuyukDeprem,
  });

  Color get renk {
    switch (risk) {
      case RiskSeviyesi.cokYuksek: return const Color(0xFFD32F2F);
      case RiskSeviyesi.yuksek:    return const Color(0xFFF57C00);
      case RiskSeviyesi.orta:      return const Color(0xFFF9A825);
    }
  }

  String get riskYazisi {
    switch (risk) {
      case RiskSeviyesi.cokYuksek: return 'ÇOK YÜKSEK RİSK';
      case RiskSeviyesi.yuksek:    return 'YÜKSEK RİSK';
      case RiskSeviyesi.orta:      return 'ORTA RİSK';
    }
  }

  double get kalinlik {
    switch (risk) {
      case RiskSeviyesi.cokYuksek: return 4.5;
      case RiskSeviyesi.yuksek:    return 3.5;
      case RiskSeviyesi.orta:      return 2.5;
    }
  }
}

// ─── Türkiye Ana Fay Hatları ──────────────────────────────────────────────────

const List<FayHatti> _turkiyeFayHatlari = [
  FayHatti(
    id: 'kafz', ad: 'Kuzey Anadolu Fay Zonu', kisaAd: 'KAFZ',
    risk: RiskSeviyesi.cokYuksek, uzunluk: '~1500 km',
    sonBuyukDeprem: '1999 Gölcük - M7.6',
    aciklama: 'Türkiye\'nin en aktif ve uzun fay zonu. Saros Körfezi\'nden '
        'Doğu Anadolu\'ya kadar uzanır. 1999 Kocaeli ve Düzce depremleri '
        'bu fay üzerinde gerçekleşmiştir.\n\n'
        '⚠️ Marmara altındaki segment kırılmamış olup büyük deprem riski taşımaktadır.',
    noktalar: [
      LatLng(40.48,26.22),LatLng(40.58,26.70),LatLng(40.65,27.10),
      LatLng(40.72,27.60),LatLng(40.80,28.00),LatLng(40.78,28.65),
      LatLng(40.77,29.10),LatLng(40.77,29.90),LatLng(40.82,30.42),
      LatLng(40.83,30.90),LatLng(40.82,31.20),LatLng(40.80,31.60),
      LatLng(40.80,32.00),LatLng(40.80,32.50),LatLng(40.85,33.10),
      LatLng(40.95,33.80),LatLng(41.00,34.40),LatLng(41.00,35.00),
      LatLng(40.90,35.55),LatLng(40.75,36.20),LatLng(40.60,36.90),
      LatLng(40.40,37.40),LatLng(40.25,37.90),LatLng(39.95,38.40),
      LatLng(39.75,39.00),LatLng(39.75,39.50),LatLng(39.80,40.00),
      LatLng(39.90,40.55),LatLng(39.97,41.07),LatLng(40.05,41.75),
    ],
  ),
  FayHatti(
    id: 'dafz', ad: 'Doğu Anadolu Fay Zonu', kisaAd: 'DAFZ',
    risk: RiskSeviyesi.cokYuksek, uzunluk: '~550 km',
    sonBuyukDeprem: '2023 Kahramanmaraş - M7.8',
    aciklama: 'İskenderun Körfezi\'nden Bingöl\'e uzanan sol yanal doğrultu atımlı fay. '
        'Şubat 2023\'teki M7.8 ve M7.7\'lik depremler bu fay üzerinde oluşmuş; '
        '11 ilde büyük yıkıma yol açmıştır.\n\n'
        '⚠️ Güneydoğu Anadolu\'da yaşayan nüfus için birincil deprem tehlikesidir.',
    noktalar: [
      LatLng(36.05,35.95),LatLng(36.20,36.10),LatLng(36.40,36.15),
      LatLng(36.85,36.45),LatLng(37.10,36.60),LatLng(37.35,36.80),
      LatLng(37.55,37.10),LatLng(37.65,37.50),LatLng(38.00,37.45),
      LatLng(38.20,37.90),LatLng(38.35,38.35),LatLng(38.30,38.85),
      LatLng(38.15,39.25),LatLng(38.30,39.80),LatLng(38.60,40.10),
      LatLng(38.90,40.50),LatLng(39.10,40.75),LatLng(39.30,41.00),
    ],
  ),
  FayHatti(
    id: 'gediz', ad: 'Gediz Grabeni', kisaAd: 'Gediz',
    risk: RiskSeviyesi.yuksek, uzunluk: '~150 km',
    sonBuyukDeprem: '1970 Gediz - M7.2',
    aciklama: 'Ege genişleme tektoniği kapsamında oluşan D-B uzanımlı graben. '
        'Kütahya\'dan İzmir\'e uzanır. 1970 Gediz depremi (M7.2) bu graben üzerinde gerçekleşmiştir.',
    noktalar: [
      LatLng(39.35,29.60),LatLng(39.25,29.30),LatLng(39.10,29.00),
      LatLng(39.00,28.75),LatLng(38.85,28.40),LatLng(38.70,28.10),
      LatLng(38.55,27.80),LatLng(38.50,27.40),LatLng(38.55,27.00),LatLng(38.60,26.80),
    ],
  ),
  FayHatti(
    id: 'buyukmenderes', ad: 'Büyük Menderes Grabeni', kisaAd: 'B.Menderes',
    risk: RiskSeviyesi.yuksek, uzunluk: '~175 km',
    sonBuyukDeprem: '2020 İzmir (Samos) - M7.0',
    aciklama: 'Batı Anadolu\'nun en uzun graben sistemi. Dinar\'dan Kuşadası\'na uzanır. '
        '2020 İzmir depreminde (M7.0) belirleyici rol oynamıştır.',
    noktalar: [
      LatLng(38.10,30.20),LatLng(38.00,29.80),LatLng(37.90,29.30),
      LatLng(37.80,28.80),LatLng(37.75,28.30),LatLng(37.72,27.90),
      LatLng(37.70,27.50),LatLng(37.72,27.10),LatLng(37.75,26.80),LatLng(37.80,26.65),
    ],
  ),
  FayHatti(
    id: 'kucukmenderes', ad: 'Küçük Menderes Grabeni', kisaAd: 'K.Menderes',
    risk: RiskSeviyesi.yuksek, uzunluk: '~100 km',
    sonBuyukDeprem: '1992 Erzincan - M6.8',
    aciklama: 'Ödemiş–Selçuk arasında uzanan aktif graben sistemi. '
        'İzmir-Ankara Zonu üzerinde yer alır.',
    noktalar: [
      LatLng(38.15,28.50),LatLng(38.10,28.10),LatLng(38.05,27.70),
      LatLng(38.00,27.40),LatLng(37.95,27.10),LatLng(37.90,26.80),
    ],
  ),
  FayHatti(
    id: 'simav', ad: 'Simav–Kütahya Fay Zonu', kisaAd: 'Simav',
    risk: RiskSeviyesi.yuksek, uzunluk: '~80 km',
    sonBuyukDeprem: '2011 Simav - M5.9',
    aciklama: 'Kütahya ile Simav arasında uzanan KD-GB yönlü normal fay sistemi.',
    noktalar: [
      LatLng(39.45,29.80),LatLng(39.35,29.55),LatLng(39.20,29.30),
      LatLng(39.10,29.05),LatLng(38.95,28.75),
    ],
  ),
  FayHatti(
    id: 'van', ad: 'Van–Çaldıran Fay Zonu', kisaAd: 'Van',
    risk: RiskSeviyesi.yuksek, uzunluk: '~120 km',
    sonBuyukDeprem: '2011 Van - M7.2',
    aciklama: 'Doğu Türkiye sıkışma tektoniği bölgesinde yer alan fay sistemi. '
        '2011 Van depremi (M7.2) büyük can ve mal kayıplarına yol açmıştır.',
    noktalar: [
      LatLng(39.40,43.20),LatLng(39.10,43.60),LatLng(38.85,43.90),
      LatLng(38.65,44.10),LatLng(38.45,44.30),
    ],
  ),
  FayHatti(
    id: 'bitlis', ad: 'Bitlis Bindirme Zonu', kisaAd: 'Bitlis',
    risk: RiskSeviyesi.orta, uzunluk: '~300 km',
    sonBuyukDeprem: '1976 Çaldıran - M7.3',
    aciklama: 'Arap levhasının Anadolu altına daldığı bindirme kuşağı. '
        'Bitlis–Zagros kuşağı boyunca uzanır.',
    noktalar: [
      LatLng(38.00,36.50),LatLng(37.90,37.50),LatLng(37.85,38.50),
      LatLng(37.90,39.50),LatLng(38.05,40.50),LatLng(38.20,41.50),
      LatLng(38.30,42.30),LatLng(38.35,43.00),
    ],
  ),
];

// ─── Harita Ekranı ────────────────────────────────────────────────────────────

class DepremHaritasiScreen extends StatefulWidget {
  const DepremHaritasiScreen({super.key});

  @override
  State<DepremHaritasiScreen> createState() => _DepremHaritasiScreenState();
}

class _DepremHaritasiScreenState extends State<DepremHaritasiScreen> {
  final MapController _mapController = MapController();

  static const LatLng _turkiyeCenter = LatLng(39.0, 35.0);

  // ── Deprem verisi ─────────────────────────────────────────────────────────
  List<DepremVerisi> _depremler = [];
  bool _depremYukleniyor = false;
  String? _hataMesaji;
  String _filtre = '24saat';

  // ── Büyüklük filtresi ─────────────────────────────────────────────────────
  double _minBuyukluk = 2.0;
  bool _sliderGorunur = false;

  // ── Konum ─────────────────────────────────────────────────────────────────
  Position? _kullaniciKonumu;
  bool _konumYukleniyor = false;

  // ── Overpass (gerçek zamanlı POI) ─────────────────────────────────────────
  OverpassSonuclar? _overpassSonuclari;
  bool _overpassYukleniyor = false;
  bool _overpassYuklendi = false; // ilk kez yüklenip yüklenmediği

  // ── Katman görünürlükleri ─────────────────────────────────────────────────
  bool _depremlerGorunur = true;
  bool _fayHatlariGorunur = true;
  bool _toplanmaAlanlariGorunur = false;
  bool _acilServislerGorunur = false;
  bool _kullaniciKonumuGorunur = true;

  // ── Seçili fay hattı ──────────────────────────────────────────────────────
  FayHatti? _seciliFayHatti;

  // ── Filtrelenmiş depremler (getter) ───────────────────────────────────────
  List<DepremVerisi> get _filtreliDepremler {
    if (_depremler.isEmpty) return [];
    return _depremler
        .where((d) => d.magnitude >= _minBuyukluk)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _depremleriYukle();
    _konumuYukle();
  }

  // ── Konum izni ayarları dialog ─────────────────────────────────────────────

  void _konumIzniDialogGoster({bool kaliciRed = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konum İzni Gerekli'),
        content: Text(
          kaliciRed
              ? 'Konum izni kalıcı olarak reddedildi. Yakınınızdaki toplanma alanları ve acil servisleri görmek için lütfen ayarlardan konum iznini etkinleştirin.'
              : 'Yakınınızdaki toplanma alanları ve acil servisleri görmek için konum iznine ihtiyaç var.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Ayarları Aç'),
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  // ── Konum yükle ───────────────────────────────────────────────────────────

  Future<void> _konumuYukle() async {
    setState(() => _konumYukleniyor = true);
    try {
      final position = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _kullaniciKonumu = position;
          _konumYukleniyor = false;
        });
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() => _konumYukleniyor = false);
        if (e.code == 'PERMISSION_DENIED_FOREVER') {
          _konumIzniDialogGoster(kaliciRed: true);
        } else if (e.code == 'PERMISSION_DENIED') {
          _konumIzniDialogGoster();
        } else {
          _showSnack(e.userMessage);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _konumYukleniyor = false);
    }
  }

  // ── Overpass verisi yükle (butona tıklanınca) ─────────────────────────────

  Future<void> _overpassVeriYukle() async {
    if (_kullaniciKonumu == null) {
      _konumIzniDialogGoster();
      return;
    }
    if (_overpassYukleniyor) return;

    setState(() => _overpassYukleniyor = true);

    final sonuclar = await OverpassService.yakindakiYerleriGetir(
      lat: _kullaniciKonumu!.latitude,
      lng: _kullaniciKonumu!.longitude,
      yaricim: 8000,
    );

    if (mounted) {
      setState(() {
        _overpassSonuclari = sonuclar;
        _overpassYukleniyor = false;
        _overpassYuklendi = true;
        // Katmanları otomatik aç
        _toplanmaAlanlariGorunur = true;
        _acilServislerGorunur = true;
      });

      if (sonuclar.bos) {
        _showSnack('Yakında kayıtlı yer bulunamadı (8 km yarıçap)');
      } else {
        _showSnack(
          '${sonuclar.toplam} yer bulundu: '
          '${sonuclar.hastaneler.length} hastane, '
          '${sonuclar.polisler.length} polis, '
          '${sonuclar.itfaiyeler.length} itfaiye, '
          '${sonuclar.toplanmaAlanlari.length} toplanma alanı',
        );
      }
    }
  }

  // ── Depremler ─────────────────────────────────────────────────────────────

  Future<void> _depremleriYukle() async {
    setState(() {
      _depremYukleniyor = true;
      _hataMesaji = null;
    });
    try {
      final depremler = _filtre == '24saat'
          ? await DepremApiService.getSon24SaatDepremler()
          : await DepremApiService.getSon7GunDepremler();
      if (mounted) {
        setState(() {
          _depremler = depremler;
          _depremYukleniyor = false;
        });
      }
    } on NetworkException catch (e) {
      if (mounted) setState(() { _hataMesaji = e.userMessage; _depremYukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() { _hataMesaji = 'Deprem verileri alınamadı'; _depremYukleniyor = false; });
    }
  }

  // ── Yardımcı ──────────────────────────────────────────────────────────────

  Color _depremRengi(double mag) {
    if (mag >= 6.0) return const Color(0xFFB71C1C);
    if (mag >= 5.0) return const Color(0xFFE53935);
    if (mag >= 4.0) return const Color(0xFFF57C00);
    if (mag >= 3.0) return const Color(0xFFFBC02D);
    return const Color(0xFF1565C0);
  }

  double _depremBoyut(double mag) {
    if (mag >= 6.0) return 44.0;
    if (mag >= 5.0) return 36.0;
    if (mag >= 4.0) return 30.0;
    if (mag >= 3.0) return 24.0;
    return 20.0;
  }

  String _formatTarih(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }

  void _fayHattiSecildi(FayHatti fay) {
    setState(() => _seciliFayHatti = fay);
    final orta = fay.noktalar[fay.noktalar.length ~/ 2];
    _mapController.move(orta, 7.0);
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  void _showPoiDialog(String baslik, List<String> satirlar, {String? telefon}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(baslik),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...satirlar.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4), child: Text(s))),
            if (telefon != null)
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: telefon);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                icon: const Icon(Icons.phone),
                label: Text('Ara: $telefon'),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  // En yakın POI'ye git
  void _enYakinPOIGit(String tip) {
    if (_kullaniciKonumu == null) { _showSnack('Konum alınamadı'); return; }
    if (_overpassSonuclari == null) { _showSnack('Önce "Yakınımı Tara" butonuna basın'); return; }

    final liste = switch (tip) {
      'toplanma'  => _overpassSonuclari!.toplanmaAlanlari,
      'hastane'   => _overpassSonuclari!.hastaneler,
      'polis'     => _overpassSonuclari!.polisler,
      'itfaiye'   => _overpassSonuclari!.itfaiyeler,
      _ => <OverpassSonuc>[],
    };

    if (liste.isEmpty) { _showSnack('Yakında $tip bulunamadı'); return; }

    // En yakını hesapla (Haversine)
    OverpassSonuc? enYakin;
    double enKucukMesafe = double.infinity;
    for (final poi in liste) {
      final d = Geolocator.distanceBetween(
        _kullaniciKonumu!.latitude, _kullaniciKonumu!.longitude,
        poi.lat, poi.lng,
      );
      if (d < enKucukMesafe) { enKucukMesafe = d; enYakin = poi; }
    }
    if (enYakin == null) return;

    _mapController.move(LatLng(enYakin.lat, enYakin.lng), 15.0);

    _showPoiDialog(enYakin.ad, [
      '📍 ${enYakin.adres ?? tip}',
      '📏 ${(enKucukMesafe / 1000).toStringAsFixed(1)} km uzaklıkta',
    ], telefon: enYakin.telefon);
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deprem & Fay Haritası'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // Büyüklük filtresi — aktifse badge göster
          IconButton(
            tooltip: 'Büyüklük Filtresi',
            onPressed: () => setState(() => _sliderGorunur = !_sliderGorunur),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(_sliderGorunur ? Icons.tune : Icons.tune_outlined),
                if (_minBuyukluk > 2.0)
                  Positioned(
                    top: -4, right: -6,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                          color: _buyuklukRengi(_minBuyukluk),
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          _minBuyukluk.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Zaman filtresi
          PopupMenuButton<String>(
            icon: const Icon(Icons.access_time),
            onSelected: (v) { setState(() => _filtre = v); _depremleriYukle(); },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: '24saat',
                child: Row(children: [
                  Icon(Icons.circle, size: 12,
                      color: _filtre == '24saat' ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Son 24 Saat'),
                ]),
              ),
              PopupMenuItem(
                value: '7gun',
                child: Row(children: [
                  Icon(Icons.circle, size: 12,
                      color: _filtre == '7gun' ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Son 7 Gün'),
                ]),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: _depremleriYukle,
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      body: Column(
        children: [
          _buildBilgiBandi(),
          if (_hataMesaji != null) _buildHataBandi(),
          if (_sliderGorunur) _buildBuyuklukSlider(),
          _buildHizliAksiyonBar(),
          Expanded(
            child: Stack(children: [
              _buildHarita(isDark),
              if (_seciliFayHatti != null)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _buildFayBilgiPaneli(_seciliFayHatti!),
                ),
              // Overpass yükleniyor göstergesi
              if (_overpassYukleniyor)
                const Positioned(
                  top: 12, left: 0, right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('Yakınındaki yerler aranıyor...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Konuma git
        FloatingActionButton.small(
          heroTag: 'loc',
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[700],
          onPressed: () {
            if (_kullaniciKonumu != null) {
              _mapController.move(
                  LatLng(_kullaniciKonumu!.latitude, _kullaniciKonumu!.longitude), 13.0);
            } else {
              _konumuYukle();
            }
          },
          child: Icon(_konumYukleniyor ? Icons.hourglass_empty : Icons.my_location),
        ),
        const SizedBox(height: 8),
        // Katmanlar
        FloatingActionButton.small(
          heroTag: 'lay',
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[700],
          onPressed: () => showDialog(
              context: context, builder: (_) => _buildKatmanDialog()),
          child: const Icon(Icons.layers),
        ),
        const SizedBox(height: 8),
        // Türkiye'ye dön
        FloatingActionButton.small(
          heroTag: 'tr',
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[700],
          onPressed: () => _mapController.move(_turkiyeCenter, 6.0),
          child: const Icon(Icons.zoom_out_map),
        ),
      ],
    );
  }

  // ─── Harita ───────────────────────────────────────────────────────────────────

  Widget _buildHarita(bool isDark) {
    if (_depremYukleniyor && _depremler.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // CartoDB tile — Google Maps benzeri temiz görünüm
    final tileUrl = isDark
        ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    final filtered = _filtreliDepremler;

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _turkiyeCenter,
        initialZoom: 6.0,
        minZoom: 4.5,
        maxZoom: 18.0,
      ),
      children: [
        // ── Altlık ────────────────────────────────────────────────────────
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.mimarai.app',
        ),

        // ── Fay hatları ───────────────────────────────────────────────────
        if (_fayHatlariGorunur)
          PolylineLayer(
            polylines: _turkiyeFayHatlari
                .map((fay) => Polyline(
                      points: fay.noktalar,
                      strokeWidth: fay.kalinlik,
                      color: fay.renk,
                      pattern: StrokePattern.solid(),
                    ))
                .toList(),
          ),

        // Fay etiketi markerları
        if (_fayHatlariGorunur)
          MarkerLayer(
            markers: _turkiyeFayHatlari.map((fay) {
              final orta = fay.noktalar[fay.noktalar.length ~/ 2];
              return Marker(
                point: orta, width: 110, height: 26,
                child: GestureDetector(
                  onTap: () => _fayHattiSecildi(fay),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: fay.renk.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [BoxShadow(
                          color: Colors.black38, blurRadius: 3, offset: const Offset(1, 1))],
                    ),
                    child: Text(fay.kisaAd,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              );
            }).toList(),
          ),

        // ── Deprem markerları (filtrelenmiş) ──────────────────────────────
        if (_depremlerGorunur && filtered.isNotEmpty)
          MarkerLayer(
            markers: filtered.map((d) {
              final renk  = _depremRengi(d.magnitude);
              final boyut = _depremBoyut(d.magnitude);
              return Marker(
                point: LatLng(d.lat, d.lng),
                width: boyut, height: boyut,
                child: GestureDetector(
                  onTap: () => _showPoiDialog(
                    'M ${d.magnitude.toStringAsFixed(1)} — Deprem',
                    [
                      '📍 ${d.location}',
                      '🕐 ${_formatTarih(d.date)}',
                      '↕ Derinlik: ${d.depth.toStringAsFixed(1)} km',
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: renk,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [BoxShadow(
                          color: renk.withOpacity(0.45), blurRadius: 6, spreadRadius: 1)],
                    ),
                    child: Center(
                      child: Text(
                        d.magnitude.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        // ── Overpass: Toplanma alanları ───────────────────────────────────
        if (_toplanmaAlanlariGorunur &&
            _overpassSonuclari != null &&
            _overpassSonuclari!.toplanmaAlanlari.isNotEmpty)
          MarkerLayer(
            markers: _overpassSonuclari!.toplanmaAlanlari.map((p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 34, height: 34,
              child: GestureDetector(
                onTap: () => _showPoiDialog(p.ad, [
                  '📍 ${p.adres ?? 'Toplanma Alanı'}',
                  '🏟 OpenStreetMap verisi',
                ]),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.people, color: Colors.white, size: 18),
                ),
              ),
            )).toList(),
          ),

        // ── Overpass: Hastaneler ─────────────────────────────────────────
        if (_acilServislerGorunur &&
            _overpassSonuclari != null &&
            _overpassSonuclari!.hastaneler.isNotEmpty)
          MarkerLayer(
            markers: _overpassSonuclari!.hastaneler.map((p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 32, height: 32,
              child: GestureDetector(
                onTap: () => _showPoiDialog(p.ad, [
                  if (p.adres != null) '📍 ${p.adres}',
                ], telefon: p.telefon),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 17),
                ),
              ),
            )).toList(),
          ),

        // ── Overpass: Polis ──────────────────────────────────────────────
        if (_acilServislerGorunur &&
            _overpassSonuclari != null &&
            _overpassSonuclari!.polisler.isNotEmpty)
          MarkerLayer(
            markers: _overpassSonuclari!.polisler.map((p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 32, height: 32,
              child: GestureDetector(
                onTap: () => _showPoiDialog(p.ad, [
                  if (p.adres != null) '📍 ${p.adres}',
                ], telefon: p.telefon ?? '155'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.local_police, color: Colors.white, size: 17),
                ),
              ),
            )).toList(),
          ),

        // ── Overpass: İtfaiye ────────────────────────────────────────────
        if (_acilServislerGorunur &&
            _overpassSonuclari != null &&
            _overpassSonuclari!.itfaiyeler.isNotEmpty)
          MarkerLayer(
            markers: _overpassSonuclari!.itfaiyeler.map((p) => Marker(
              point: LatLng(p.lat, p.lng),
              width: 32, height: 32,
              child: GestureDetector(
                onTap: () => _showPoiDialog(p.ad, [
                  if (p.adres != null) '📍 ${p.adres}',
                ], telefon: p.telefon ?? '110'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.local_fire_department, color: Colors.white, size: 17),
                ),
              ),
            )).toList(),
          ),

        // ── Kullanıcı konumu ─────────────────────────────────────────────
        if (_kullaniciKonumuGorunur && _kullaniciKonumu != null)
          MarkerLayer(markers: [
            Marker(
              point: LatLng(_kullaniciKonumu!.latitude, _kullaniciKonumu!.longitude),
              width: 46, height: 46,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(
                      color: Colors.blue.withOpacity(0.5), blurRadius: 14, spreadRadius: 4)],
                ),
                child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
              ),
            ),
          ]),
      ],
    );
  }

  // ─── Büyüklük Slider ─────────────────────────────────────────────────────────

  Widget _buildBuyuklukSlider() {
    final gosterilen = _filtreliDepremler.length;
    final toplam = _depremler.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, size: 16),
              const SizedBox(width: 6),
              const Text('Min. Büyüklük:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              // Renkli büyüklük badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: _buyuklukRengi(_minBuyukluk),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('M ${_minBuyukluk.toStringAsFixed(1)}+',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const Spacer(),
              Text('$gosterilen / $toplam deprem',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(width: 8),
              if (_minBuyukluk > 2.0)
                GestureDetector(
                  onTap: () => setState(() => _minBuyukluk = 2.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Sıfırla',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
            ],
          ),
          // Slider — 0.5'lik adımlarla 2.0–6.0
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _buyuklukRengi(_minBuyukluk),
              thumbColor: _buyuklukRengi(_minBuyukluk),
              inactiveTrackColor: Colors.grey[300],
              overlayColor: _buyuklukRengi(_minBuyukluk).withOpacity(0.2),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _minBuyukluk,
              min: 2.0,
              max: 6.0,
              divisions: 8, // 2.0, 2.5, 3.0, ... 6.0
              label: 'M ${_minBuyukluk.toStringAsFixed(1)}+',
              onChanged: (v) => setState(() => _minBuyukluk = v),
            ),
          ),
          // Skala etiketleri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['2.0', '3.0', '4.0', '5.0', '6.0']
                  .map((l) => Text(l,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _buyuklukRengi(double mag) {
    if (mag >= 5.0) return Colors.red;
    if (mag >= 4.0) return Colors.orange;
    if (mag >= 3.0) return Colors.amber[700]!;
    return Colors.blue;
  }

  // ─── Hızlı aksiyon bar ────────────────────────────────────────────────────────

  Widget _buildHizliAksiyonBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Yakınımı Tara (Overpass) ─────────────────────────────────
            _aksiyonBtn(
              _overpassYuklendi
                  ? 'Tekrar Tara'
                  : 'Yakınımı Tara',
              _overpassYukleniyor ? Icons.hourglass_empty : Icons.radar,
              Colors.teal,
              _overpassYukleniyor ? null : _overpassVeriYukle,
            ),
            const SizedBox(width: 8),
            // ── En yakın POI ─────────────────────────────────────────────
            _aksiyonBtn('Toplanma', Icons.people, Colors.green,
                () => _enYakinPOIGit('toplanma')),
            const SizedBox(width: 8),
            _aksiyonBtn('Hastane', Icons.local_hospital, Colors.red,
                () => _enYakinPOIGit('hastane')),
            const SizedBox(width: 8),
            _aksiyonBtn('Polis', Icons.local_police, Colors.blue,
                () => _enYakinPOIGit('polis')),
            const SizedBox(width: 8),
            _aksiyonBtn('İtfaiye', Icons.local_fire_department, Colors.orange,
                () => _enYakinPOIGit('itfaiye')),
            const SizedBox(width: 8),
            // ── Fay hattı seçici ─────────────────────────────────────────
            _faySeciciBtn(),
          ],
        ),
      ),
    );
  }

  Widget _aksiyonBtn(String label, IconData icon, Color color,
      VoidCallback? onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onTap == null ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _faySeciciBtn() {
    return PopupMenuButton<FayHatti>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.show_chart, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('Fay Seç',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
      itemBuilder: (_) => _turkiyeFayHatlari
          .map((fay) => PopupMenuItem<FayHatti>(
                value: fay,
                child: Row(children: [
                  Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                          color: fay.renk, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(fay.kisaAd,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('(${fay.riskYazisi.split(' ')[0]})',
                      style:
                          TextStyle(fontSize: 11, color: fay.renk)),
                ]),
              ))
          .toList(),
      onSelected: _fayHattiSecildi,
    );
  }

  // ─── Bilgi bandı ─────────────────────────────────────────────────────────────

  Widget _buildBilgiBandi() {
    final gosterilen = _filtreliDepremler.length;
    final overpassBilgi = _overpassYuklendi && _overpassSonuclari != null
        ? ' • ${_overpassSonuclari!.toplam} yer'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.blue[700],
      child: Row(children: [
        const Icon(Icons.info_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_filtre == '24saat' ? 'Son 24 saat' : 'Son 7 gün'} '
            '• $gosterilen deprem$overpassBilgi',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        if (_depremYukleniyor || _overpassYukleniyor)
          const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
      ]),
    );
  }

  Widget _buildHataBandi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red[50],
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_hataMesaji!,
            style: const TextStyle(color: Colors.red, fontSize: 13))),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red, size: 18),
          onPressed: () => setState(() => _hataMesaji = null),
        ),
      ]),
    );
  }

  // ─── Fay bilgi paneli ─────────────────────────────────────────────────────────

  Widget _buildFayBilgiPaneli(FayHatti fay) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12, offset: const Offset(0, -2))],
        border: Border(left: BorderSide(color: fay.renk, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fay.ad, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: fay.renk, borderRadius: BorderRadius.circular(10)),
                  child: Text(fay.riskYazisi,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            )),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _seciliFayHatti = null),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _chip(Icons.straighten, fay.uzunluk),
            const SizedBox(width: 8),
            _chip(Icons.history_edu, fay.sonBuyukDeprem),
          ]),
          const SizedBox(height: 8),
          Text(fay.aciklama,
              style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
              maxLines: 4, overflow: TextOverflow.ellipsis),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => _showTamAciklama(fay),
            child: const Text('Daha fazla oku →',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[800])),
      ]),
    );
  }

  void _showTamAciklama(FayHatti fay) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(children: [
        Container(width: 4, height: 24,
            decoration: BoxDecoration(
                color: fay.renk, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(fay.ad, style: const TextStyle(fontSize: 15))),
      ]),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: fay.renk, borderRadius: BorderRadius.circular(10)),
              child: Text(fay.riskYazisi,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            _chip(Icons.straighten, 'Uzunluk: ${fay.uzunluk}'),
            const SizedBox(height: 6),
            _chip(Icons.history_edu, fay.sonBuyukDeprem),
            const SizedBox(height: 12),
            Text(fay.aciklama, style: const TextStyle(height: 1.6)),
          ],
        ),
      ),
      actions: [TextButton(
          onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
    ));
  }

  // ─── Legend ────────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Renk Açıklaması',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 4, children: [
          _legendItem(const Color(0xFFD32F2F), 'Çok Yüksek Riskli Fay', isLine: true),
          _legendItem(const Color(0xFFF57C00), 'Yüksek Riskli Fay', isLine: true),
          _legendItem(const Color(0xFFF9A825), 'Orta Riskli Fay', isLine: true),
          _legendItem(const Color(0xFFB71C1C), 'M6.0+'),
          _legendItem(const Color(0xFFE53935), 'M5.0–6.0'),
          _legendItem(const Color(0xFFF57C00), 'M4.0–5.0'),
          _legendItem(const Color(0xFFFBC02D), 'M3.0–4.0'),
          _legendItem(const Color(0xFF1565C0), 'M2.0–3.0'),
        ]),
      ]),
    );
  }

  Widget _legendItem(Color color, String label, {bool isLine = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (isLine)
        Container(width: 22, height: 4,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)))
      else
        Container(width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ]);
  }

  // ─── Katman dialog ────────────────────────────────────────────────────────────

  Widget _buildKatmanDialog() {
    return StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Harita Katmanları'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _toggle('Depremler', Icons.circle, _depremlerGorunur, setS,
              (v) { _depremlerGorunur = v; }),
          _toggle('Fay Hatları', Icons.show_chart, _fayHatlariGorunur, setS,
              (v) { _fayHatlariGorunur = v; }),
          _toggle(
            'Toplanma Alanları${_overpassSonuclari != null ? ' (${_overpassSonuclari!.toplanmaAlanlari.length})' : ''}',
            Icons.people, _toplanmaAlanlariGorunur, setS,
            (v) { _toplanmaAlanlariGorunur = v; }),
          _toggle(
            'Acil Servisler${_overpassSonuclari != null ? ' (${_overpassSonuclari!.hastaneler.length + _overpassSonuclari!.polisler.length + _overpassSonuclari!.itfaiyeler.length})' : ''}',
            Icons.local_hospital, _acilServislerGorunur, setS,
            (v) { _acilServislerGorunur = v; }),
          _toggle('Konumum', Icons.my_location, _kullaniciKonumuGorunur, setS,
              (v) { _kullaniciKonumuGorunur = v; }),
        ]),
        actions: [TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
  }

  Widget _toggle(String label, IconData icon, bool value,
      StateSetter setS, void Function(bool) onChange) {
    return SwitchListTile(
      title: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      ]),
      value: value,
      onChanged: (v) => setS(() { onChange(v); setState(() {}); }),
      dense: true,
    );
  }
}
