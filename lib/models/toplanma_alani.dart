/// Toplanma alanı modeli
class ToplanmaAlani {
  final String id;
  final String ad;
  final double lat;
  final double lng;
  final String? adres;
  final String? kapasite;
  final String? tip; // Park, Okul, Spor Salonu, vb.

  ToplanmaAlani({
    required this.id,
    required this.ad,
    required this.lat,
    required this.lng,
    this.adres,
    this.kapasite,
    this.tip,
  });

  factory ToplanmaAlani.fromJson(Map<String, dynamic> json) {
    return ToplanmaAlani(
      id: json['id'] as String,
      ad: json['ad'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      adres: json['adres'] as String?,
      kapasite: json['kapasite'] as String?,
      tip: json['tip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'lat': lat,
      'lng': lng,
      'adres': adres,
      'kapasite': kapasite,
      'tip': tip,
    };
  }
}

/// Acil servis lokasyonu modeli
class AcilServisLokasyonu {
  final String id;
  final String ad;
  final double lat;
  final double lng;
  final String tip; // hastane, polis, itfaiye
  final String? adres;
  final String? telefon;

  AcilServisLokasyonu({
    required this.id,
    required this.ad,
    required this.lat,
    required this.lng,
    required this.tip,
    this.adres,
    this.telefon,
  });

  factory AcilServisLokasyonu.fromJson(Map<String, dynamic> json) {
    return AcilServisLokasyonu(
      id: json['id'] as String,
      ad: json['ad'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      tip: json['tip'] as String,
      adres: json['adres'] as String?,
      telefon: json['telefon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'lat': lat,
      'lng': lng,
      'tip': tip,
      'adres': adres,
      'telefon': telefon,
    };
  }
}




