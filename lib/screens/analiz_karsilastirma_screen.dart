import 'package:flutter/material.dart';
import '../models/analiz_kaydi.dart';
import '../services/analiz_gecmisi_service.dart';
import '../l10n/app_strings.dart';

/// İki analizi yan yana karşılaştıran ekran.
/// Geçmiş ekranından bir "Karşılaştır" butonuyla açılabilir,
/// ya da doğrudan iki AnalizKaydi nesnesi geçilerek kullanılabilir.
class AnalizKarsilastirmaScreen extends StatefulWidget {
  /// İki analiz önceden seçilmişse geçilir.
  final AnalizKaydi? ilkAnaliz;
  final AnalizKaydi? ikinciAnaliz;

  const AnalizKarsilastirmaScreen({
    super.key,
    this.ilkAnaliz,
    this.ikinciAnaliz,
  });

  @override
  State<AnalizKarsilastirmaScreen> createState() =>
      _AnalizKarsilastirmaScreenState();
}

class _AnalizKarsilastirmaScreenState
    extends State<AnalizKarsilastirmaScreen> {
  List<AnalizKaydi> _tumAnalizler = [];
  bool _yukleniyor = true;

  AnalizKaydi? _solAnaliz;
  AnalizKaydi? _sagAnaliz;

  @override
  void initState() {
    super.initState();
    _solAnaliz = widget.ilkAnaliz;
    _sagAnaliz = widget.ikinciAnaliz;
    _analizleriYukle();
  }

  Future<void> _analizleriYukle() async {
    try {
      final list = await AnalizGecmisiService.tumAnalizleriGetir();
      if (mounted) setState(() { _tumAnalizler = list; _yukleniyor = false; });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  // Kullanıcıya analiz seçtiren dialog
  Future<void> _analizSec(bool solTaraf) async {
    if (_tumAnalizler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz kayıtlı analiz yok.')));
      return;
    }
    final secilen = await showDialog<AnalizKaydi>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(solTaraf ? 'Sol Analizi Seç' : 'Sağ Analizi Seç'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _tumAnalizler.length,
            itemBuilder: (_, i) {
              final a = _tumAnalizler[i];
              final secili = solTaraf
                  ? _solAnaliz?.id == a.id
                  : _sagAnaliz?.id == a.id;
              return ListTile(
                selected: secili,
                selectedTileColor: Colors.blue[50],
                leading: CircleAvatar(
                  backgroundColor: a.analiz.riskRengi.withOpacity(0.2),
                  child: Text(
                    a.analiz.riskSkoru.toStringAsFixed(0),
                    style: TextStyle(
                      color: a.analiz.riskRengi,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(a.gosterilecekIsim,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(a.tamTarih,
                    style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(ctx, a),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
    if (secilen != null) {
      setState(() {
        if (solTaraf) _solAnaliz = secilen;
        else _sagAnaliz = secilen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Karşılaştırma'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Seçici başlık bandı ───────────────────────────────────
                _buildSeciciBar(),
                // ── İçerik ───────────────────────────────────────────────
                Expanded(
                  child: (_solAnaliz == null || _sagAnaliz == null)
                      ? _buildBosEkran()
                      : _buildKarsilastirma(_solAnaliz!, _sagAnaliz!),
                ),
              ],
            ),
    );
  }

  // ─── Seçici bar ──────────────────────────────────────────────────────────────

  Widget _buildSeciciBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(child: _analizSecKart(_solAnaliz, true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue[700], size: 28),
                Text('VS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue[700],
                  )),
              ],
            ),
          ),
          Expanded(child: _analizSecKart(_sagAnaliz, false)),
        ],
      ),
    );
  }

  Widget _analizSecKart(AnalizKaydi? analiz, bool solTaraf) {
    if (analiz == null) {
      return GestureDetector(
        onTap: () => _analizSec(solTaraf),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.blue[300]!,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue[400], size: 18),
              const SizedBox(width: 6),
              Text(
                solTaraf ? 'Sol Analiz' : 'Sağ Analiz',
                style: TextStyle(color: Colors.blue[400], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _analizSec(solTaraf),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: analiz.analiz.riskRengi.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: analiz.analiz.riskRengi, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analiz.gosterilecekIsim,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              analiz.kisaTarih,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: analiz.analiz.riskRengi,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'M ${analiz.analiz.riskSkoru.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Colors.grey[500]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Boş ekran ────────────────────────────────────────────────────────────────

  Widget _buildBosEkran() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'İki analiz seçin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yukarıdan iki analiz seçerek\ndetaylı karşılaştırma yapın',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          if (_tumAnalizler.length < 2)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Karşılaştırmak için en az 2 analiz gerekli. Önce birkaç analiz yapın.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Ana karşılaştırma içeriği ────────────────────────────────────────────────

  Widget _buildKarsilastirma(AnalizKaydi sol, AnalizKaydi sag) {
    final solSkor = sol.analiz.riskSkoru;
    final sagSkor = sag.analiz.riskSkoru;
    final solDahaIyi = solSkor < sagSkor;
    final esit = solSkor == sagSkor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Risk skoru özet kartı ────────────────────────────────────────
          _buildSkorOzetKarti(sol, sag, solDahaIyi, esit),
          const SizedBox(height: 16),

          // ── Detay karşılaştırma tablosu ──────────────────────────────────
          _buildDetayTablo(sol, sag),
          const SizedBox(height: 16),

          // ── Tespit sayıları ─────────────────────────────────────────────
          _buildTespitKarsilastirma(sol, sag),
          const SizedBox(height: 16),

          // ── Değişim özeti ────────────────────────────────────────────────
          _buildDegisimOzeti(sol, sag),
        ],
      ),
    );
  }

  // ─── Risk Skoru Özet Kartı ────────────────────────────────────────────────────

  Widget _buildSkorOzetKarti(
      AnalizKaydi sol, AnalizKaydi sag, bool solDahaIyi, bool esit) {
    final fark = (sol.analiz.riskSkoru - sag.analiz.riskSkoru).abs();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Risk Skoru Karşılaştırması',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Sol skor
                Expanded(child: _skorGorunumu(sol, solDahaIyi && !esit)),
                // Orta: fark gösterimi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      if (esit)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.drag_handle,
                              color: Colors.grey),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            solDahaIyi
                                ? Icons.arrow_back
                                : Icons.arrow_forward,
                            color: Colors.blue[700],
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (!esit)
                        Text(
                          '${fark.toStringAsFixed(1)} puan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Sağ skor
                Expanded(child: _skorGorunumu(sag, !solDahaIyi && !esit)),
              ],
            ),
            if (!esit) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green[700], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${(solDahaIyi ? sol : sag).gosterilecekIsim} daha az riskli',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skorGorunumu(AnalizKaydi analiz, bool kazanan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analiz.analiz.riskRengi.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kazanan
              ? Colors.green
              : analiz.analiz.riskRengi.withOpacity(0.4),
          width: kazanan ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (kazanan)
            Icon(Icons.check_circle, color: Colors.green, size: 18),
          Text(
            analiz.analiz.riskSkoru.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: analiz.analiz.riskRengi,
            ),
          ),
          Text(
            analiz.analiz.riskSeviyesi,
            style: TextStyle(
              fontSize: 11,
              color: analiz.analiz.riskRengi,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            analiz.gosterilecekIsim,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            analiz.kisaTarih,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── Detay Tablo ─────────────────────────────────────────────────────────────

  Widget _buildDetayTablo(AnalizKaydi sol, AnalizKaydi sag) {
    final satirlar = [
      _KarsilastirmaSatiri(
        baslik: t('structure_type_label'),
        icon: Icons.apartment,
        solDeger: sol.analiz.yapiTipi ?? '—',
        sagDeger: sag.analiz.yapiTipi ?? '—',
      ),
      _KarsilastirmaSatiri(
        baslik: t('building_age_label'),
        icon: Icons.calendar_today,
        solDeger: sol.analiz.binaYasi ?? '—',
        sagDeger: sag.analiz.binaYasi ?? '—',
        dusukIyi: true,
      ),
      _KarsilastirmaSatiri(
        baslik: t('floor_count_label'),
        icon: Icons.layers,
        solDeger: sol.analiz.katSayisi ?? '—',
        sagDeger: sag.analiz.katSayisi ?? '—',
      ),
      _KarsilastirmaSatiri(
        baslik: t('concrete_grade_label'),
        icon: Icons.foundation,
        solDeger: sol.analiz.betonSinifi ?? '—',
        sagDeger: sag.analiz.betonSinifi ?? '—',
        yuksekIyi: true,
      ),
      _KarsilastirmaSatiri(
        baslik: t('damage_severity_label'),
        icon: Icons.warning_amber,
        solDeger: sol.analiz.hasarSiddeti ?? '—',
        sagDeger: sag.analiz.hasarSiddeti ?? '—',
      ),
      _KarsilastirmaSatiri(
        baslik: t('urgency_level_label'),
        icon: Icons.priority_high,
        solDeger: sol.analiz.aciliyetSeviyesi ?? '—',
        sagDeger: sag.analiz.aciliyetSeviyesi ?? '—',
      ),
      _KarsilastirmaSatiri(
        baslik: t('estimated_cost_label'),
        icon: Icons.attach_money,
        solDeger: sol.analiz.tahminiMaliyet ?? '—',
        sagDeger: sag.analiz.tahminiMaliyet ?? '—',
      ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.table_rows, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text('Detaylı Karşılaştırma',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            // Sütun başlıkları
            Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Center(
                    child: Text(
                      sol.gosterilecekIsim,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      sag.gosterilecekIsim,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...satirlar.map((s) => _buildTabloCizgisi(s)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabloCizgisi(_KarsilastirmaSatiri satir) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // İkon + başlık
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(satir.icon, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    satir.baslik,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sol değer
          Expanded(
            child: _degerHucresi(
              satir.solDeger,
              _hucreRengi(satir.solDeger, satir.sagDeger,
                  dusukIyi: satir.dusukIyi, yuksekIyi: satir.yuksekIyi),
            ),
          ),
          const SizedBox(width: 6),
          // Sağ değer
          Expanded(
            child: _degerHucresi(
              satir.sagDeger,
              _hucreRengi(satir.sagDeger, satir.solDeger,
                  dusukIyi: satir.dusukIyi, yuksekIyi: satir.yuksekIyi),
            ),
          ),
        ],
      ),
    );
  }

  Widget _degerHucresi(String deger, Color? vurguRenk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: vurguRenk?.withOpacity(0.10) ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: vurguRenk?.withOpacity(0.35) ?? Colors.grey[200]!,
        ),
      ),
      child: Text(
        deger,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              vurguRenk != null ? FontWeight.bold : FontWeight.normal,
          color: vurguRenk ?? Colors.grey[800],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Sayısal karşılaştırma yapılabiliyorsa renk döndürür.
  Color? _hucreRengi(String deger, String karsi,
      {bool dusukIyi = false, bool yuksekIyi = false}) {
    if (!dusukIyi && !yuksekIyi) return null;
    if (deger == '—' || karsi == '—') return null;
    // Sayı parse etmeye çalış (ör. "C25/30" → çıkarılamaz, renk yok)
    final dSayi = double.tryParse(
        deger.replaceAll(RegExp(r'[^0-9.]'), ''));
    final kSayi = double.tryParse(
        karsi.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (dSayi == null || kSayi == null) return null;
    if (dSayi == kSayi) return null;
    if (dusukIyi) return dSayi < kSayi ? Colors.green : Colors.red;
    if (yuksekIyi) return dSayi > kSayi ? Colors.green : Colors.red;
    return null;
  }

  // ─── Tespit Karşılaştırması ───────────────────────────────────────────────────

  Widget _buildTespitKarsilastirma(AnalizKaydi sol, AnalizKaydi sag) {
    final solToplam = sol.analiz.tespitler.length;
    final sagToplam = sag.analiz.tespitler.length;

    // Kategori bazlı sayım
    Map<String, int> solKategoriler = {};
    for (final t in sol.analiz.tespitler) {
      solKategoriler[t.kategori] = (solKategoriler[t.kategori] ?? 0) + 1;
    }
    Map<String, int> sagKategoriler = {};
    for (final t in sag.analiz.tespitler) {
      sagKategoriler[t.kategori] = (sagKategoriler[t.kategori] ?? 0) + 1;
    }

    // Tüm kategoriler
    final tumKategoriler = {
      ...solKategoriler.keys,
      ...sagKategoriler.keys
    }.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Tespit Karşılaştırması',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            // Toplam bar
            Row(
              children: [
                const SizedBox(width: 100),
                Expanded(
                  child: _sayiBar(solToplam,
                      max(solToplam, sagToplam).toDouble(), Colors.blue),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _sayiBar(sagToplam,
                      max(solToplam, sagToplam).toDouble(), Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 100),
                Expanded(
                  child: Text('$solToplam tespit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('$sagToplam tespit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (tumKategoriler.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('Kategorilere Göre',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...tumKategoriler.map((kat) {
                final solSayi = solKategoriler[kat] ?? 0;
                final sagSayi = sagKategoriler[kat] ?? 0;
                final maxSayi = max(solSayi, sagSayi);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(kat,
                          style: TextStyle(
                            fontSize: 11, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: _sayiBar(solSayi, maxSayi > 0 ? maxSayi.toDouble() : 1, Colors.blue),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$solSayi|$sagSayi',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ),
                      Expanded(
                        child: _sayiBar(sagSayi, maxSayi > 0 ? maxSayi.toDouble() : 1, Colors.indigo),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sayiBar(int deger, double maksimum, Color renk) {
    final oran = maksimum > 0 ? deger / maksimum : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: oran,
            minHeight: 12,
            backgroundColor: renk.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(renk),
          ),
        ),
      ],
    );
  }

  // ─── Değişim Özeti ────────────────────────────────────────────────────────────

  Widget _buildDegisimOzeti(AnalizKaydi sol, AnalizKaydi sag) {
    final skorFark = sag.analiz.riskSkoru - sol.analiz.riskSkoru;
    final kotu = skorFark > 0;
    final ayni = skorFark == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, size: 18, color: Colors.purple),
                SizedBox(width: 8),
                Text('Risk Değişim Özeti',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            if (ayni)
              _ozOzetChip(
                renk: Colors.grey,
                icon: Icons.drag_handle,
                metin: 'İki analiz arasında risk skoru farkı yok.',
              )
            else
              _ozOzetChip(
                renk: kotu ? Colors.red : Colors.green,
                icon: kotu ? Icons.trending_up : Icons.trending_down,
                metin: kotu
                    ? '${sag.gosterilecekIsim} tarafında risk ${skorFark.abs().toStringAsFixed(1)} puan daha yüksek.\n'
                      'Müdahale önceliği bu yapıdadır.'
                    : '${sol.gosterilecekIsim} tarafında risk ${skorFark.abs().toStringAsFixed(1)} puan daha yüksek.\n'
                      'Müdahale önceliği bu yapıdadır.',
              ),
            const SizedBox(height: 10),
            // Tespit sayısı değişimi
            _buildTespitDegisimSatiri(sol, sag),
          ],
        ),
      ),
    );
  }

  Widget _ozOzetChip(
      {required Color renk, required IconData icon, required String metin}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: renk.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: renk, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              metin,
              style: TextStyle(
                color: renk,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTespitDegisimSatiri(AnalizKaydi sol, AnalizKaydi sag) {
    final solSayi = sol.analiz.tespitler.length;
    final sagSayi = sag.analiz.tespitler.length;
    final fark = sagSayi - solSayi;
    if (fark == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            fark > 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: fark > 0 ? Colors.orange : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${sag.gosterilecekIsim} tarafında ${fark.abs()} '
              '${fark > 0 ? "daha fazla" : "daha az"} tespit mevcut.',
              style: TextStyle(
                fontSize: 13,
                color: fark > 0 ? Colors.orange[800] : Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int max(int a, int b) => a > b ? a : b;
}

/// Karşılaştırma tablosu için veri modeli
class _KarsilastirmaSatiri {
  final String baslik;
  final IconData icon;
  final String solDeger;
  final String sagDeger;
  final bool dusukIyi; // Daha düşük değer daha iyiyse (ör. yaş)
  final bool yuksekIyi; // Daha yüksek değer daha iyiyse (ör. beton sınıfı)

  const _KarsilastirmaSatiri({
    required this.baslik,
    required this.icon,
    required this.solDeger,
    required this.sagDeger,
    this.dusukIyi = false,
    this.yuksekIyi = false,
  });
}
