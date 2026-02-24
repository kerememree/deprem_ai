import 'package:flutter/material.dart';
import 'tespit.dart';

class RiskAnalizi {
  final double riskSkoru;
  final List<Tespit> tespitler;
  final String muhendisTavsiyesi;
  final String? binaYasi;
  final String? betonSinifi;
  final String? hasarSiddeti;
  final String? katSayisi;
  final String? yapiTipi;
  final String? analizTarihi;
  final String? aciliyetSeviyesi;
  final String? tahminiMaliyet;

  RiskAnalizi({
    required this.riskSkoru,
    required this.tespitler,
    required this.muhendisTavsiyesi,
    this.binaYasi,
    this.betonSinifi,
    this.hasarSiddeti,
    this.katSayisi,
    this.yapiTipi,
    this.analizTarihi,
    this.aciliyetSeviyesi,
    this.tahminiMaliyet,
  });

  factory RiskAnalizi.fromJson(Map<String, dynamic> json) {
    // Tespitleri parse et - hem eski string format hem yeni object format destekle
    List<Tespit> tespitList = [];
    if (json['tespitler'] != null) {
      final tespitData = json['tespitler'] as List<dynamic>;
      tespitList = tespitData.map((e) {
        if (e is Map<String, dynamic>) {
          return Tespit.fromJson(e);
        } else {
          // Eski format - string olarak gelmişse
          return Tespit(
            kategori: 'Genel',
            aciklama: e.toString(),
            onem: 'Orta',
          );
        }
      }).toList();
    }

    return RiskAnalizi(
      riskSkoru: (json['riskSkoru'] as num?)?.toDouble() ?? 0.0,
      tespitler: tespitList,
      muhendisTavsiyesi: json['muhendisTavsiyesi'] as String? ?? '',
      binaYasi: json['binaYasi'] as String?,
      betonSinifi: json['betonSinifi'] as String?,
      hasarSiddeti: json['hasarSiddeti'] as String?,
      katSayisi: json['katSayisi'] as String?,
      yapiTipi: json['yapiTipi'] as String?,
      analizTarihi: json['analizTarihi'] as String?,
      aciliyetSeviyesi: json['aciliyetSeviyesi'] as String?,
      tahminiMaliyet: json['tahminiMaliyet'] as String?,
    );
  }
  
  // Geriye dönük uyumluluk için
  List<String> get tespitlerEskiFormat {
    return tespitler.map((t) => '${t.kategori}: ${t.aciklama}').toList();
  }

  String get riskSeviyesi {
    if (riskSkoru <= 3) return 'Düşük Risk';
    if (riskSkoru <= 6) return 'Orta Risk';
    if (riskSkoru <= 8) return 'Yüksek Risk';
    return 'Çok Yüksek Risk';
  }

  Color get riskRengi {
    if (riskSkoru <= 3) return Colors.green;
    if (riskSkoru <= 6) return Colors.orange;
    if (riskSkoru <= 8) return Colors.deepOrange;
    return Colors.red;
  }
}
