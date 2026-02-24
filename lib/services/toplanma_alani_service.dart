import '../models/toplanma_alani.dart';

/// Toplanma alanları servisi - Statik veri (ileride Firestore'dan çekilebilir)
class ToplanmaAlaniService {
  // Örnek toplanma alanları (İstanbul, Ankara, İzmir'den örnekler)
  // İleride Firestore'dan çekilebilir
  static List<ToplanmaAlani> getOrnekToplanmaAlanlari() {
    return [
      // İstanbul
      ToplanmaAlani(
        id: '1',
        ad: 'Maçka Demokrasi Parkı',
        lat: 41.0470,
        lng: 28.9930,
        adres: 'Maçka, İstanbul',
        tip: 'Park',
        kapasite: '5000 kişi',
      ),
      ToplanmaAlani(
        id: '2',
        ad: 'Atatürk Olimpiyat Stadı',
        lat: 41.0742,
        lng: 28.7667,
        adres: 'Bakırköy, İstanbul',
        tip: 'Spor Salonu',
        kapasite: '76000 kişi',
      ),
      ToplanmaAlani(
        id: '3',
        ad: 'Fenerbahçe Şükrü Saraçoğlu Stadı',
        lat: 40.9876,
        lng: 29.0356,
        adres: 'Kadıköy, İstanbul',
        tip: 'Spor Salonu',
        kapasite: '50000 kişi',
      ),
      // Ankara
      ToplanmaAlani(
        id: '4',
        ad: 'Anıttepe Parkı',
        lat: 39.9189,
        lng: 32.8581,
        adres: 'Çankaya, Ankara',
        tip: 'Park',
        kapasite: '3000 kişi',
      ),
      ToplanmaAlani(
        id: '5',
        ad: 'Atatürk Spor Salonu',
        lat: 39.9334,
        lng: 32.8597,
        adres: 'Ulus, Ankara',
        tip: 'Spor Salonu',
        kapasite: '10000 kişi',
      ),
      // İzmir
      ToplanmaAlani(
        id: '6',
        ad: 'Kültürpark',
        lat: 38.4250,
        lng: 27.1433,
        adres: 'Konak, İzmir',
        tip: 'Park',
        kapasite: '8000 kişi',
      ),
      ToplanmaAlani(
        id: '7',
        ad: 'İzmir Atatürk Stadyumu',
        lat: 38.4333,
        lng: 27.1733,
        adres: 'Alsancak, İzmir',
        tip: 'Spor Salonu',
        kapasite: '51500 kişi',
      ),
    ];
  }
}




