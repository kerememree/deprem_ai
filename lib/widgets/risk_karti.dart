import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../models/risk_analizi.dart';
import '../models/tespit.dart';
import '../l10n/app_strings.dart';
import 'risk_grafikleri.dart';

class RiskKarti extends StatelessWidget {
  final RiskAnalizi analiz;
  final List<File>? fotograflar;

  const RiskKarti({
    super.key,
    required this.analiz,
    this.fotograflar,
  });

  // ── Yardımcı: Risk skoruna göre gauge rengi ────────────────────────────────
  static Color _gaugeRengi(double skor) {
    if (skor <= 3) return Colors.green;
    if (skor <= 6) return Colors.orange;
    if (skor <= 8) return Colors.deepOrange;
    return Colors.red;
  }

  // ── Yardımcı: Tespit kategorisine göre ikon ───────────────────────────────
  static IconData _kategoriIkon(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('çatlak') || k.contains('crack')) {
      return Icons.foundation;
    } else if (k.contains('korozyon') || k.contains('pas')) {
      return Icons.water_damage;
    } else if (k.contains('yumuşak kat') || k.contains('soft')) {
      return Icons.layers;
    } else if (k.contains('kısa kolon') || k.contains('short column')) {
      return Icons.vertical_align_center;
    } else if (k.contains('kolon')) {
      return Icons.architecture;
    } else if (k.contains('kiriş') || k.contains('beam')) {
      return Icons.horizontal_rule;
    } else if (k.contains('zemin') || k.contains('temel') || k.contains('foundation')) {
      return Icons.terrain;
    } else if (k.contains('döşeme') || k.contains('tavan') || k.contains('floor')) {
      return Icons.grid_3x3;
    } else if (k.contains('köşe') || k.contains('hasar')) {
      return Icons.broken_image_outlined;
    } else if (k.contains('nem') || k.contains('su') || k.contains('moisture')) {
      return Icons.water_drop_outlined;
    }
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final gaugeRenk = _gaugeRengi(analiz.riskSkoru);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GAUGE: RadialBarChart (Görev 2a+b) ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: gaugeRenk.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gaugeRenk.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    t('risk_score'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // fl_chart 0.69.2 — PieChart ile yarım gauge
                        // 270° renkli yay + 90° transparan boşluk (alt)
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 62,
                            startDegreeOffset: 135, // 7 saat pozisyonundan başla
                            sections: [
                              // Riskli dilim (renkli)
                              PieChartSectionData(
                                value: analiz.riskSkoru / 10 * 270,
                                color: gaugeRenk,
                                radius: 20,
                                showTitle: false,
                              ),
                              // Kalan dilim (gri)
                              PieChartSectionData(
                                value: (10 - analiz.riskSkoru) / 10 * 270,
                                color: Colors.grey[200]!,
                                radius: 20,
                                showTitle: false,
                              ),
                              // Alt boşluk (transparan)
                              PieChartSectionData(
                                value: 90,
                                color: Colors.transparent,
                                radius: 20,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                        // Merkez skor + seviye yazısı
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              analiz.riskSkoru.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: gaugeRenk,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              analiz.riskSeviyesi,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: gaugeRenk,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Skor aralığı etiketleri
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRangeChip('0–3', Colors.green,
                            analiz.riskSkoru <= 3),
                        _buildRangeChip('3–6', Colors.orange,
                            analiz.riskSkoru > 3 && analiz.riskSkoru <= 6),
                        _buildRangeChip('6–8', Colors.deepOrange,
                            analiz.riskSkoru > 6 && analiz.riskSkoru <= 8),
                        _buildRangeChip('8–10', Colors.red,
                            analiz.riskSkoru > 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Eski stil skor + seviye (gizli değil, bilgi amaçlı küçük) ───
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: analiz.riskSkoru / 10,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation<Color>(analiz.riskRengi),
              ),
            ),
            const SizedBox(height: 20),

            // ── Detaylı Grafikler ─────────────────────────────────────────────
            RiskGrafikleri(analiz: analiz),
            const SizedBox(height: 20),

            // ── Bina Bilgileri ────────────────────────────────────────────────
            if (analiz.binaYasi != null || analiz.betonSinifi != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('building_info'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (analiz.binaYasi != null)
                      _buildInfoRow(t('building_age_label'), analiz.binaYasi!),
                    if (analiz.betonSinifi != null)
                      _buildInfoRow(
                          t('concrete_grade_label'), analiz.betonSinifi!),
                    if (analiz.katSayisi != null)
                      _buildInfoRow(
                          t('floor_count_label'), analiz.katSayisi!),
                    if (analiz.yapiTipi != null)
                      _buildInfoRow(
                          t('structure_type_label'), analiz.yapiTipi!),
                    if (analiz.hasarSiddeti != null)
                      _buildInfoRow(
                          t('damage_severity_label'), analiz.hasarSiddeti!),
                    if (analiz.aciliyetSeviyesi != null)
                      _buildInfoRow(
                          t('urgency_level_label'), analiz.aciliyetSeviyesi!),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Tespitler: Kategori Bazlı Gruplandırma (Görev 2c) ────────────
            _buildTespitlerBolumu(context),
            const SizedBox(height: 20),

            // ── Mühendis Tavsiyesi ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.engineering, color: Colors.amber[900]),
                      const SizedBox(width: 8),
                      Text(
                        t('engineer_advice_title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analiz.muhendisTavsiyesi,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (analiz.tahminiMaliyet != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.amber[900], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analiz.tahminiMaliyet!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Özet Metin Paylaşımı ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _ozetPaylasimi(context),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(t('share_result')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
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

  /// Skor aralığı chip'i — aktif olanı vurgular
  Widget _buildRangeChip(String label, Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? color : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  // ── Tespitler: kategori bazlı gruplandırılmış (Görev 2c) ─────────────────
  Widget _buildTespitlerBolumu(BuildContext context) {
    if (analiz.tespitler.isEmpty) return const SizedBox.shrink();

    // Kategorilere göre grupla
    final Map<String, List<Tespit>> gruplar = {};
    for (final tespit in analiz.tespitler) {
      gruplar.putIfAbsent(tespit.kategori, () => []).add(tespit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t('findings_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${analiz.tespitler.length}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...gruplar.entries.map((entry) =>
            _buildKategoriGrubu(entry.key, entry.value, context)),
      ],
    );
  }

  /// Bir kategoriyi başlıkla + tespitler listesiyle gösterir
  Widget _buildKategoriGrubu(
      String kategori, List<Tespit> tespitler, BuildContext context) {
    // Grubun en yüksek önem rengini al
    Color grupRengi = tespitler.first.onemRengi;
    for (final t in tespitler) {
      if (t.onem.toLowerCase() == 'kritik') {
        grupRengi = Colors.red;
        break;
      } else if (t.onem.toLowerCase().contains('yüksek') ||
          t.onem.toLowerCase() == 'yuksek') {
        grupRengi = Colors.deepOrange;
      }
    }

    final ikon = _kategoriIkon(kategori);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: grupRengi.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          // Kategori başlığı (ikon + ad + tespit sayısı)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: grupRengi.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: grupRengi.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ikon, size: 16, color: grupRengi),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kategori,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: grupRengi,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: grupRengi.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tespitler.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: grupRengi,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tespit kartları
          ...tespitler.asMap().entries.map((entry) {
            final idx = entry.key;
            final tespit = entry.value;
            return Column(
              children: [
                if (idx > 0)
                  Divider(
                      height: 1,
                      thickness: 0.5,
                      color: grupRengi.withOpacity(0.15)),
                _buildTespitRow(tespit, context),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Tek bir tespiti satır formatında gösterir
  Widget _buildTespitRow(Tespit tespit, BuildContext context) {
    File? ilgiliFotograf;
    if (tespit.fotografIndeksi != null &&
        fotograflar != null &&
        fotograflar!.isNotEmpty) {
      final index = tespit.fotografIndeksi!;
      if (index >= 0 && index < fotograflar!.length) {
        ilgiliFotograf = fotograflar![index];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Önem etiketi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tespit.onemRengi.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tespit.onemRengi, width: 1),
                ),
                child: Text(
                  tespit.onem,
                  style: TextStyle(
                    color: tespit.onemRengi,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (ilgiliFotograf != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo, size: 12, color: Colors.blue[900]),
                      const SizedBox(width: 4),
                      Text(
                        '${t('photo_label')} #${tespit.fotografIndeksi! + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tespit.aciklama,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (ilgiliFotograf != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  _fotografiGoster(context, ilgiliFotograf!, tespit),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tespit.onemRengi.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        ilgiliFotograf,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.zoom_in,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              t('tap_to_zoom'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// WhatsApp / SMS dostu kısa analiz özeti paylaşımı
  Future<void> _ozetPaylasimi(BuildContext context) async {
    final emoji = analiz.riskSkoru >= 9
        ? '🔴'
        : analiz.riskSkoru >= 7
            ? '🟠'
            : analiz.riskSkoru >= 5
                ? '🟡'
                : analiz.riskSkoru >= 3
                    ? '🟢'
                    : '✅';

    final sb = StringBuffer();
    sb.writeln('🏗️ Mimar-AI — Deprem Risk Analizi');
    sb.writeln('─────────────────────────');
    sb.writeln('$emoji Risk Skoru: ${analiz.riskSkoru.toStringAsFixed(1)}/10');
    sb.writeln('📊 Seviye: ${analiz.riskSeviyesi}');
    if (analiz.binaYasi != null) sb.writeln('🏠 Bina Yaşı: ${analiz.binaYasi}');
    if (analiz.katSayisi != null)
      sb.writeln('🏢 Kat Sayısı: ${analiz.katSayisi}');
    if (analiz.yapiTipi != null)
      sb.writeln('🔩 Yapı Tipi: ${analiz.yapiTipi}');
    if (analiz.tespitler.isNotEmpty) {
      sb.writeln('─────────────────────────');
      sb.writeln('📋 Tespitler (${analiz.tespitler.length} adet):');
      for (int i = 0; i < analiz.tespitler.length && i < 5; i++) {
        final item = analiz.tespitler[i];
        sb.writeln('• [${item.onem}] ${item.aciklama}');
      }
      if (analiz.tespitler.length > 5) {
        sb.writeln('...ve ${analiz.tespitler.length - 5} tespit daha.');
      }
    }
    sb.writeln('─────────────────────────');
    sb.writeln('💬 ${analiz.muhendisTavsiyesi}');
    sb.writeln();
    sb.writeln('📱 Mimar-AI uygulaması ile hazırlandı.');

    try {
      await Share.share(
        sb.toString(),
        subject:
            'Deprem Risk Analizi — Skor: ${analiz.riskSkoru.toStringAsFixed(1)}/10',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım başarısız: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  /// Risk skoru formül açıklaması bottom sheet
  void _formulAciklamasiGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calculate_outlined,
                      color: Colors.blue[700], size: 26),
                  const SizedBox(width: 10),
                  Text(
                    t('risk_score_formula_title'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t('risk_score_formula_desc'),
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                t('risk_score_factors'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildFormulaFactor(
                  Icons.calendar_today, t('factor_age'), Colors.orange),
              _buildFormulaFactor(
                  Icons.layers, t('factor_floors'), Colors.purple),
              _buildFormulaFactor(
                  Icons.architecture, t('factor_construction'), Colors.blue),
              _buildFormulaFactor(
                  Icons.square_foot, t('factor_concrete'), Colors.teal),
              _buildFormulaFactor(
                  Icons.warning_amber, t('factor_damage'), Colors.red),
              _buildFormulaFactor(Icons.location_on,
                  t('factor_seismic_zone'), Colors.brown),
              const SizedBox(height: 20),
              Text(
                t('risk_score_ranges'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildScoreRange('0 – 2', t('range_very_low'), Colors.green[700]!),
              _buildScoreRange('3 – 4', t('range_low'), Colors.lightGreen[700]!),
              _buildScoreRange(
                  '5 – 6', t('range_medium'), Colors.orange[700]!),
              _buildScoreRange(
                  '7 – 8', t('range_high'), Colors.deepOrange[700]!),
              _buildScoreRange(
                  '9 – 10', t('range_very_high'), Colors.red[800]!),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('risk_score_disclaimer'),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaFactor(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildScoreRange(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 60,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              range,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _fotografiGoster(
      BuildContext context, File fotograf, Tespit tespit) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(fotograf, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tespit.onemRengi,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tespit.kategori,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tespit.onemRengi.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: tespit.onemRengi, width: 1),
                          ),
                          child: Text(
                            tespit.onem,
                            style: TextStyle(
                                color: tespit.onemRengi,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tespit.aciklama,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
