import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

/// OpenStreetMap Overpass API'den gerçek zamanlı POI verisi çeker.
/// Tamamen ücretsiz, her şehir için güncel veri sağlar.
class OverpassSonuc {
  final String id;
  final String ad;
  final double lat;
  final double lng;
  final String tip; // hastane | polis | itfaiye | toplanma
  final String? adres;
  final String? telefon;

  const OverpassSonuc({
    required this.id,
    required this.ad,
    required this.lat,
    required this.lng,
    required this.tip,
    this.adres,
    this.telefon,
  });
}

class OverpassService {
  static const String _apiUrl = 'https://overpass-api.de/api/interpreter';

  // ─── Ana metod: tek istekle tüm POI türlerini çek ────────────────────────────

  /// Kullanıcı konumuna yakın tüm acil servis ve toplanma alanlarını getirir.
  /// [yaricim] metre cinsinden arama yarıçapı (varsayılan 8 km).
  static Future<OverpassSonuclar> yakindakiYerleriGetir({
    required double lat,
    required double lng,
    int yaricim = 8000,
  }) async {
    // Overpass QL sorgusu — tek istekle tüm türleri çek
    final sorgu = '''
[out:json][timeout:30];
(
  node["amenity"="hospital"](around:$yaricim,$lat,$lng);
  way["amenity"="hospital"](around:$yaricim,$lat,$lng);
  node["amenity"="clinic"](around:$yaricim,$lat,$lng);
  node["healthcare"="hospital"](around:$yaricim,$lat,$lng);
  node["amenity"="police"](around:$yaricim,$lat,$lng);
  way["amenity"="police"](around:$yaricim,$lat,$lng);
  node["amenity"="fire_station"](around:$yaricim,$lat,$lng);
  way["amenity"="fire_station"](around:$yaricim,$lat,$lng);
  node["emergency"="assembly_point"](around:$yaricim,$lat,$lng);
  node["amenity"="assembly_point"](around:$yaricim,$lat,$lng);
  node["leisure"="stadium"](around:$yaricim,$lat,$lng);
  way["leisure"="stadium"](around:$yaricim,$lat,$lng);
  node["leisure"="sports_centre"](around:$yaricim,$lat,$lng);
  way["leisure"="sports_centre"](around:$yaricim,$lat,$lng);
  node["leisure"="park"]["name"](around:$yaricim,$lat,$lng);
);
out center;
''';

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=${Uri.encodeComponent(sorgu)}',
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Overpass API hatası: ${response.statusCode}');
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final elements = (json['elements'] as List<dynamic>?) ?? [];

      final hastaneler = <OverpassSonuc>[];
      final polisler = <OverpassSonuc>[];
      final itfaiyeler = <OverpassSonuc>[];
      final toplanmaAlanlari = <OverpassSonuc>[];

      for (final el in elements) {
        final tags = (el['tags'] as Map<String, dynamic>?) ?? {};

        // Koordinat (way için center kullan)
        final double? eLat = el['lat'] != null
            ? (el['lat'] as num).toDouble()
            : (el['center']?['lat'] as num?)?.toDouble();
        final double? eLng = el['lon'] != null
            ? (el['lon'] as num).toDouble()
            : (el['center']?['lon'] as num?)?.toDouble();

        if (eLat == null || eLng == null) continue;

        final id = el['id'].toString();
        final ad = _adCikar(tags);
        if (ad.isEmpty) continue;

        final adres = _adresCikar(tags);
        final telefon = tags['phone'] ?? tags['contact:phone'];

        final amenity = tags['amenity'] as String?;
        final healthcare = tags['healthcare'] as String?;
        final emergency = tags['emergency'] as String?;
        final leisure = tags['leisure'] as String?;

        if (amenity == 'hospital' ||
            amenity == 'clinic' ||
            healthcare == 'hospital') {
          hastaneler.add(OverpassSonuc(
            id: id, ad: ad, lat: eLat, lng: eLng,
            tip: 'hastane', adres: adres, telefon: telefon,
          ));
        } else if (amenity == 'police') {
          polisler.add(OverpassSonuc(
            id: id, ad: ad, lat: eLat, lng: eLng,
            tip: 'polis', adres: adres, telefon: telefon ?? '155',
          ));
        } else if (amenity == 'fire_station') {
          itfaiyeler.add(OverpassSonuc(
            id: id, ad: ad, lat: eLat, lng: eLng,
            tip: 'itfaiye', adres: adres, telefon: telefon ?? '110',
          ));
        } else if (emergency == 'assembly_point' ||
            amenity == 'assembly_point' ||
            leisure == 'stadium' ||
            leisure == 'sports_centre' ||
            leisure == 'park') {
          final tipYazisi = switch (leisure) {
            'stadium' => 'Stadyum',
            'sports_centre' => 'Spor Merkezi',
            'park' => 'Park',
            _ => 'Toplanma Alanı',
          };
          toplanmaAlanlari.add(OverpassSonuc(
            id: id, ad: ad, lat: eLat, lng: eLng,
            tip: 'toplanma',
            adres: adres ?? tipYazisi,
          ));
        }
      }

      return OverpassSonuclar(
        hastaneler: hastaneler,
        polisler: polisler,
        itfaiyeler: itfaiyeler,
        toplanmaAlanlari: toplanmaAlanlari,
      );
    } catch (e) {
      // Hata durumunda boş sonuç döndür
      debugPrint('Overpass API hatası: $e');
      return OverpassSonuclar.bos();
    }
  }

  // ─── Yardımcı metodlar ────────────────────────────────────────────────────────

  static String _adCikar(Map<String, dynamic> tags) {
    return (tags['name:tr'] ??
            tags['name'] ??
            tags['official_name'] ??
            tags['brand'] ??
            '') as String;
  }

  static String? _adresCikar(Map<String, dynamic> tags) {
    final parts = <String>[];
    final street = tags['addr:street'] as String?;
    final houseNumber = tags['addr:housenumber'] as String?;
    final city = tags['addr:city'] ?? tags['addr:district'] as String?;

    if (street != null) {
      parts.add(houseNumber != null ? '$street $houseNumber' : street);
    }
    if (city != null) parts.add(city as String);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// Overpass API sonuç paketi
class OverpassSonuclar {
  final List<OverpassSonuc> hastaneler;
  final List<OverpassSonuc> polisler;
  final List<OverpassSonuc> itfaiyeler;
  final List<OverpassSonuc> toplanmaAlanlari;

  const OverpassSonuclar({
    required this.hastaneler,
    required this.polisler,
    required this.itfaiyeler,
    required this.toplanmaAlanlari,
  });

  factory OverpassSonuclar.bos() => const OverpassSonuclar(
        hastaneler: [], polisler: [], itfaiyeler: [], toplanmaAlanlari: []);

  bool get bos =>
      hastaneler.isEmpty &&
      polisler.isEmpty &&
      itfaiyeler.isEmpty &&
      toplanmaAlanlari.isEmpty;

  int get toplam =>
      hastaneler.length +
      polisler.length +
      itfaiyeler.length +
      toplanmaAlanlari.length;
}
