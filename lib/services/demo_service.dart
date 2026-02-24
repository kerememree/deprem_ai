import '../models/risk_analizi.dart';
import '../models/tespit.dart';

/// Demo modu için sabit, gerçekçi analiz verisi sağlar.
/// API çağrısı yapmadan uygulamanın tüm özelliklerini göstermek için kullanılır.
class DemoService {
  static RiskAnalizi demoAnaliz() {
    return RiskAnalizi(
      riskSkoru: 7.2,
      tespitler: [
        Tespit(
          kategori: 'Kolon Çatlağı',
          aciklama:
              'Zemin kat güney-doğu köşe kolonunda diyagonal çatlak tespit edildi. '
              'Çatlak genişliği 3-5 mm aralığında olup ilerleme riski taşımaktadır.',
          onem: 'Kritik',
        ),
        Tespit(
          kategori: 'Köşe Hasarı',
          aciklama:
              'Kuzey cephe köşe kolonunda beton dökülmesi ve donatı açığa çıkması '
              'gözlemlendi. Yapısal taşıyıcılık kapasitesi azalmış olabilir.',
          onem: 'Yüksek',
        ),
        Tespit(
          kategori: 'Korozyon',
          aciklama:
              'Bodrum kattaki ana kirişlerde ileri düzey paslanma (korozyon) tespit '
              'edildi. Donatı kesit kaybı tahminen %15-20 düzeyindedir.',
          onem: 'Yüksek',
        ),
        Tespit(
          kategori: 'Zemin Katta Yumuşak Kat',
          aciklama:
              'Zemin katta diğer katlara göre belirgin biçimde daha az dolgu duvar '
              'bulunmaktadır. Bu durum deprem sırasında kat mekanizması oluşturabilir.',
          onem: 'Orta',
        ),
      ],
      muhendisTavsiyesi:
          'Tespit edilen yapısal hasarlar binanın deprem performansını ciddi düzeyde '
          'olumsuz etkilemektedir. Öncelikli olarak zemin kat köşe kolonlarındaki '
          'çatlaklar karbon fiber sarma veya çelik manşon ile güçlendirilmeli, bodrum '
          'kattaki paslanmış donatılar temizlenerek antikorozif kaplama uygulanmalıdır. '
          'Acil önlem olarak binaya yük bindiren gereksiz depolama faaliyetleri '
          'durdurulmalı ve en geç 1 ay içinde lisanslı bir inşaat mühendisine kapsamlı '
          'yapısal değerlendirme yaptırılmalıdır.',
      binaYasi: '38 yıl (1987)',
      katSayisi: '5 kat',
      yapiTipi: 'Betonarme çerçeve sistem',
      betonSinifi: 'C16 (Düşük dayanım)',
      hasarSiddeti: 'Orta-Ağır',
      aciliyetSeviyesi: 'Acil Müdahale Gerekli',
      tahminiMaliyet: '₺180.000 – ₺250.000 (güçlendirme + onarım)',
    );
  }
}
