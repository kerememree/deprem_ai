import 'dart:io';
import 'package:flutter/material.dart';
import 'risk_analizi.dart';

/// Analiz geçmişi kaydı - Hive database'de saklanacak
class AnalizKaydi {
  final String id;
  final DateTime tarih;
  final RiskAnalizi analiz;
  final List<String>? fotografPathleri; // Fotoğrafların yerel path'leri
  final String? pdfPath; // PDF'in yerel path'i
  final String? binaAdi; // Kullanıcı tarafından verilen isim (opsiyonel)

  AnalizKaydi({
    required this.id,
    required this.tarih,
    required this.analiz,
    this.fotografPathleri,
    this.pdfPath,
    this.binaAdi,
  });

  /// JSON'dan oluştur
  factory AnalizKaydi.fromJson(Map<String, dynamic> json) {
    return AnalizKaydi(
      id: json['id'] as String,
      tarih: DateTime.parse(json['tarih'] as String),
      analiz: RiskAnalizi.fromJson(json['analiz'] as Map<String, dynamic>),
      fotografPathleri: (json['fotografPathleri'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      pdfPath: json['pdfPath'] as String?,
      binaAdi: json['binaAdi'] as String?,
    );
  }

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarih': tarih.toIso8601String(),
      'analiz': {
        'riskSkoru': analiz.riskSkoru,
        'tespitler': analiz.tespitler
            .map((t) => {
                  'kategori': t.kategori,
                  'aciklama': t.aciklama,
                  'onem': t.onem,
                  'fotografIndeksi': t.fotografIndeksi,
                })
            .toList(),
        'muhendisTavsiyesi': analiz.muhendisTavsiyesi,
        'binaYasi': analiz.binaYasi,
        'betonSinifi': analiz.betonSinifi,
        'hasarSiddeti': analiz.hasarSiddeti,
        'katSayisi': analiz.katSayisi,
        'yapiTipi': analiz.yapiTipi,
        'analizTarihi': analiz.analizTarihi,
        'aciliyetSeviyesi': analiz.aciliyetSeviyesi,
        'tahminiMaliyet': analiz.tahminiMaliyet,
      },
      'fotografPathleri': fotografPathleri,
      'pdfPath': pdfPath,
      'binaAdi': binaAdi,
    };
  }

  /// Fotoğraf dosyalarını al (offline erişim için)
  List<File> get fotografDosyalari {
    if (fotografPathleri == null) return [];
    return fotografPathleri!
        .where((path) => File(path).existsSync())
        .map((path) => File(path))
        .toList();
  }

  /// PDF dosyasını al (offline erişim için)
  File? get pdfDosyasi {
    if (pdfPath == null) return null;
    if (!File(pdfPath!).existsSync()) return null;
    return File(pdfPath!);
  }

  /// Kısa tarih formatı
  String get kisaTarih {
    return '${tarih.day}.${tarih.month}.${tarih.year}';
  }

  /// Tam tarih formatı
  String get tamTarih {
    return '${tarih.day}.${tarih.month}.${tarih.year} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}';
  }

  /// Gösterilecek isim
  String get gosterilecekIsim {
    return binaAdi ?? 'Analiz - $kisaTarih';
  }
}




