import 'package:flutter/material.dart';

class Tespit {
  final String kategori;
  final String aciklama;
  final String onem; // Düşük, Orta, Yüksek, Kritik
  final int? fotografIndeksi;

  Tespit({
    required this.kategori,
    required this.aciklama,
    required this.onem,
    this.fotografIndeksi,
  });

  factory Tespit.fromJson(Map<String, dynamic> json) {
    return Tespit(
      kategori: json['kategori'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      onem: json['onem'] as String? ?? 'Orta',
      fotografIndeksi: json['fotografIndeksi'] as int?,
    );
  }

  Color get onemRengi {
    switch (onem.toLowerCase()) {
      case 'düşük':
      case 'dusuk':
        return Colors.blue;
      case 'orta':
        return Colors.orange;
      case 'yüksek':
      case 'yuksek':
        return Colors.deepOrange;
      case 'kritik':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
