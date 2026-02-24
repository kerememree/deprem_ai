import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/risk_analizi.dart';
import '../models/tespit.dart';

class PdfService {
  // Türkçe karakterleri destekleyen fontlar (lazy loading)
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  
  /// Fontları yükle (ilk kullanımda)
  static Future<void> _loadFonts() async {
    if (_regularFont == null) {
      try {
        // Regular font'u yükle
        final regularData = await rootBundle.load('fonts/OpenSans-Regular.ttf');
        _regularFont = pw.Font.ttf(regularData);
        
        // Bold font'u yüklemeyi dene (opsiyonel - yoksa Regular kullanılacak)
        try {
          final boldData = await rootBundle.load('fonts/OpenSans-Bold.ttf');
          _boldFont = pw.Font.ttf(boldData);
        } catch (e) {
          // Bold font yoksa sadece Regular kullanılacak
          debugPrint('UYARI: OpenSans-Bold.ttf bulunamadı. Sadece Regular font kullanılacak.');
        }
      } catch (e) {
        // Font yüklenemezse varsayılan font kullanılacak (Türkçe karakterler bozuk olabilir)
        debugPrint('Font yükleme hatası: $e');
        debugPrint('PDF\'de Türkçe karakterler düzgün görünmeyebilir. Lütfen font dosyalarını ekleyin.');
      }
    }
  }
  
  /// Türkçe karakterleri destekleyen text style (font yoksa varsayılan)
  static pw.TextStyle _textStyle({
    double fontSize = 12,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor? color,
    pw.FontStyle fontStyle = pw.FontStyle.normal,
  }) {
    pw.Font? font;
    if (fontWeight == pw.FontWeight.bold && _boldFont != null) {
      font = _boldFont;
    } else if (_regularFont != null) {
      font = _regularFont;
    }
    
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      font: font, // Font yüklenmişse kullan
    );
  }
  /// PDF rapor oluştur ve paylaş
  static Future<void> raporOlusturVePaylas(
    RiskAnalizi analiz,
    List<File>? fotograflar,
  ) async {
    final pdf = await _pdfOlustur(analiz);
    
    // Geçici dosya oluştur
    final directory = await getTemporaryDirectory();
    final fileName = 'MimarAI_Rapor_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Paylaşım dialogu göster
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Mimar-AI Deprem Riski Analiz Raporu',
      subject: 'Bina Deprem Riski Analizi',
    );
  }

  /// PDF rapor oluştur ve önizleme göster
  static Future<void> raporOlusturVeGoster(
    RiskAnalizi analiz,
    List<File>? fotograflar,
  ) async {
    final pdf = await _pdfOlustur(analiz);
    
    // PDF önizleme göster
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// PDF dokümanı oluştur (public method)
  static Future<pw.Document> createPdfDocument(RiskAnalizi analiz) async {
    return _pdfOlustur(analiz);
  }

  /// PDF dokümanı oluştur
  static Future<pw.Document> _pdfOlustur(RiskAnalizi analiz) async {
    // Fontları yükle (Türkçe karakter desteği için)
    await _loadFonts();
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Başlık
            _buildBaslik(),
            pw.SizedBox(height: 20),

            // Risk Skoru Özet
            _buildRiskSkoru(analiz),
            pw.SizedBox(height: 20),

            // Bina Bilgileri
            _buildBinaBilgileri(analiz),
            pw.SizedBox(height: 20),

            // Tespitler
            _buildTespitler(analiz),
            pw.SizedBox(height: 20),

            // Mühendis Tavsiyesi
            _buildMuhendisTavsiyesi(analiz),
            pw.SizedBox(height: 20),

            // Alt Bilgi
            _buildAltBilgi(),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Başlık bölümü
  static pw.Widget _buildBaslik() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MİMAR-AI',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Deprem Riski Analiz Raporu',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Container(
              width: 60,
              height: 60,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(
                child: pw.Text(
                  '🏢',
                  style: pw.TextStyle(fontSize: 30),
                ),
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue700),
      ],
    );
  }

  /// Risk Skoru bölümü
  static pw.Widget _buildRiskSkoru(RiskAnalizi analiz) {
    final riskRengi = _riskRengiPdf(analiz.riskSkoru);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: riskRengi, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Risk Skoru',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${analiz.riskSkoru.toStringAsFixed(1)} / 10',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                  color: riskRengi,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: riskRengi,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  analiz.riskSeviyesi,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bina Bilgileri bölümü
  static pw.Widget _buildBinaBilgileri(RiskAnalizi analiz) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bina Bilgileri',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildBilgiSatiri('Bina Yaşı', analiz.binaYasi ?? 'Belirtilmemiş'),
          _buildBilgiSatiri('Beton Sınıfı', analiz.betonSinifi ?? 'Belirtilmemiş'),
          if (analiz.katSayisi != null)
            _buildBilgiSatiri('Kat Sayısı', analiz.katSayisi!),
          if (analiz.yapiTipi != null)
            _buildBilgiSatiri('Yapı Tipi', analiz.yapiTipi!),
          if (analiz.hasarSiddeti != null)
            _buildBilgiSatiri('Hasar Şiddeti', analiz.hasarSiddeti!),
          if (analiz.aciliyetSeviyesi != null)
            _buildBilgiSatiri('Aciliyet Seviyesi', analiz.aciliyetSeviyesi!),
          if (analiz.tahminiMaliyet != null)
            _buildBilgiSatiri('Tahmini Maliyet', analiz.tahminiMaliyet!),
        ],
      ),
    );
  }

  /// Bilgi satırı helper
  static pw.Widget _buildBilgiSatiri(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Tespitler bölümü
  static pw.Widget _buildTespitler(RiskAnalizi analiz) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tespitler (${analiz.tespitler.length})',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...analiz.tespitler.map((tespit) => _buildTespitKarti(tespit)),
      ],
    );
  }

  /// Tespit kartı
  static pw.Widget _buildTespitKarti(Tespit tespit) {
    final onemRengi = _onemRengiPdf(tespit.onem);
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: onemRengi, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  tespit.kategori,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: onemRengi,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: onemRengi,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  tespit.onem,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            tespit.aciklama,
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Mühendis Tavsiyesi bölümü
  static pw.Widget _buildMuhendisTavsiyesi(RiskAnalizi analiz) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.orange300, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mühendis Tavsiyesi',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            analiz.muhendisTavsiyesi,
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Alt bilgi
  static pw.Widget _buildAltBilgi() {
    // Locale olmadan format kullan (Türkçe locale initialize sorunu için)
    final now = DateTime.now();
    final monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final formattedDate = '${now.day.toString().padLeft(2, '0')} ${monthNames[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Bu rapor Mimar-AI tarafından otomatik oluşturulmuştur.',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Oluşturulma Tarihi: $formattedDate',
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'NOT: Bu rapor ön değerlendirme amaçlıdır. Detaylı analiz için profesyonel bir inşaat mühendisi ile görüşmeniz önerilir.',
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.red700,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Risk skoru rengi (PDF için)
  static PdfColor _riskRengiPdf(double riskSkoru) {
    if (riskSkoru < 3) return PdfColors.green;
    if (riskSkoru < 6) return PdfColors.orange;
    if (riskSkoru < 8) return PdfColors.deepOrange;
    return PdfColors.red;
  }

  /// Önem rengi (PDF için)
  static PdfColor _onemRengiPdf(String onem) {
    switch (onem.toLowerCase()) {
      case 'düşük':
      case 'dusuk':
        return PdfColors.blue;
      case 'orta':
        return PdfColors.orange;
      case 'yüksek':
      case 'yuksek':
        return PdfColors.deepOrange;
      case 'kritik':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
}

