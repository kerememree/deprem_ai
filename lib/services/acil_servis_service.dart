import '../models/toplanma_alani.dart';

/// Acil servis lokasyonları servisi - Statik veri (ileride Firestore'dan çekilebilir)
class AcilServisService {
  // Örnek acil servis lokasyonları (İstanbul, Ankara, İzmir'den örnekler)
  static List<AcilServisLokasyonu> getOrnekAcilServisler() {
    return [
      // İstanbul - Hastaneler
      AcilServisLokasyonu(
        id: 'h1',
        ad: 'İstanbul Üniversitesi Çapa Tıp Fakültesi',
        lat: 41.0114,
        lng: 28.9319,
        tip: 'hastane',
        adres: 'Fatih, İstanbul',
        telefon: '0212 414 30 00',
      ),
      AcilServisLokasyonu(
        id: 'h2',
        ad: 'Memorial Şişli Hastanesi',
        lat: 41.0614,
        lng: 28.9878,
        tip: 'hastane',
        adres: 'Şişli, İstanbul',
        telefon: '0212 314 66 66',
      ),
      // Ankara - Hastaneler
      AcilServisLokasyonu(
        id: 'h3',
        ad: 'Ankara Üniversitesi Tıp Fakültesi',
        lat: 39.9324,
        lng: 32.8597,
        tip: 'hastane',
        adres: 'Altındağ, Ankara',
        telefon: '0312 595 60 00',
      ),
      // İzmir - Hastaneler
      AcilServisLokasyonu(
        id: 'h4',
        ad: 'Ege Üniversitesi Tıp Fakültesi',
        lat: 38.4639,
        lng: 27.2294,
        tip: 'hastane',
        adres: 'Bornova, İzmir',
        telefon: '0232 390 40 00',
      ),
      // İstanbul - Polis
      AcilServisLokasyonu(
        id: 'p1',
        ad: 'İstanbul Emniyet Müdürlüğü',
        lat: 41.0096,
        lng: 28.9752,
        tip: 'polis',
        adres: 'Vatan Caddesi, Fatih, İstanbul',
        telefon: '155',
      ),
      // Ankara - Polis
      AcilServisLokasyonu(
        id: 'p2',
        ad: 'Ankara Emniyet Müdürlüğü',
        lat: 39.9334,
        lng: 32.8597,
        tip: 'polis',
        adres: 'Ulus, Ankara',
        telefon: '155',
      ),
      // İzmir - Polis
      AcilServisLokasyonu(
        id: 'p3',
        ad: 'İzmir Emniyet Müdürlüğü',
        lat: 38.4237,
        lng: 27.1428,
        tip: 'polis',
        adres: 'Konak, İzmir',
        telefon: '155',
      ),
      // İstanbul - İtfaiye
      AcilServisLokasyonu(
        id: 'i1',
        ad: 'İstanbul İtfaiye Müdürlüğü',
        lat: 41.0104,
        lng: 28.9744,
        tip: 'itfaiye',
        adres: 'Vatan Caddesi, Fatih, İstanbul',
        telefon: '110',
      ),
      // Ankara - İtfaiye
      AcilServisLokasyonu(
        id: 'i2',
        ad: 'Ankara İtfaiye Müdürlüğü',
        lat: 39.9334,
        lng: 32.8597,
        tip: 'itfaiye',
        adres: 'Ulus, Ankara',
        telefon: '110',
      ),
      // İzmir - İtfaiye
      AcilServisLokasyonu(
        id: 'i3',
        ad: 'İzmir İtfaiye Müdürlüğü',
        lat: 38.4237,
        lng: 27.1428,
        tip: 'itfaiye',
        adres: 'Konak, İzmir',
        telefon: '110',
      ),
    ];
  }
}




