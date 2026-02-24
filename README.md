<div align="center">

# 🏗️ Mimar-AI

### Yapay Zeka Destekli Deprem Risk Analiz Uygulaması
### AI-Powered Earthquake Risk Assessment App

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Analytics-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-AI-4285F4?style=for-the-badge&logo=google)](https://aistudio.google.com)


</div>

---

## 📱 Uygulama Hakkında

**Mimar-AI**, bina fotoğrafları ve yapı belgelerini (PDF) Google Gemini AI'ya göndererek **deprem risk skoru (0–10)** üreten bir Flutter mobil uygulamasıdır.

Türkiye'deki mevcut yapı stoğunun büyük kısmının deprem yönetmeliklerinden önce inşa edildiği göz önüne alındığında, bu uygulama vatandaşlara ve mühendislere bina güvenliğini hızlıca ön değerlendirme imkânı sunar.

> ⚠️ Bu uygulama **ön rapor** niteliğindedir. Kritik kararlar için lisanslı bir inşaat mühendisine danışılmalıdır.

---

## ✨ Özellikler

| Özellik | Detay |
|---|---|
| 🤖 **AI Analizi** | Google Gemini ile çok modlu yapısal analiz (görsel + metin) |
| 📊 **Risk Gauge** | PieChart tabanlı 0–10 renk kodlu risk göstergesi |
| 📄 **PDF Desteği** | Ruhsat/tapu belgesinden bina yaşı ve beton sınıfı çıkarma |
| 📸 **Çoklu Fotoğraf** | Galeri veya kamera; fotoğraf-tespit eşleştirmesi |
| 🗂️ **Analiz Geçmişi** | Hive ile yerel veritabanı, geçmiş analizler |
| 🎭 **Demo Modu** | API olmadan uygulamayı test etme |
| 📋 **PDF Export** | Analiz raporunu PDF olarak paylaşma |
| 🌍 **Çoklu Dil** | Türkçe / İngilizce (runtime switching) |
| 🌙 **Tema** | Açık / Koyu / Sistem |
| 🔔 **Bildirimler** | Periyodik takip hatırlatmaları |
| 🗺️ **Deprem Haritası** | Güncel deprem verileri harita görünümü |
| 🔐 **Firebase Auth** | E-posta + Google ile giriş |

---

## 🏛️ Mimari

```
lib/
├── main.dart                      # Ana sayfa + AuthWrapper + tema/dil yönetimi
├── config/
│   └── model_config.dart          # Gemini model seçimi
├── core/
│   └── exceptions/
│       └── app_exceptions.dart    # Özel exception hiyerarşisi
├── l10n/
│   └── app_strings.dart           # TR/EN yerelleştirme (t() fonksiyonu)
├── models/
│   ├── analiz_kaydi.dart          # Hive modeli
│   ├── risk_analizi.dart          # AI sonuç modeli
│   └── tespit.dart                # Yapısal tespit modeli
├── screens/
│   ├── analiz_gecmisi_screen.dart
│   ├── deprem_bilgilendirme_screen.dart
│   ├── deprem_haritasi_screen.dart
│   ├── login_screen.dart
│   └── onboarding_screen.dart
├── services/
│   ├── analiz_gecmisi_service.dart  # Hive CRUD
│   ├── auth_service.dart            # Firebase Auth
│   ├── demo_service.dart            # Demo analiz verisi
│   ├── gemini_service.dart          # 🔒 Gizli (prompt mühendisliği)
│   ├── gemini_service.dart.example  # Şablon — kendi prompt'unuzu yazın
│   ├── notification_service.dart
│   ├── pdf_service.dart
│   └── tracking_service.dart
└── widgets/
    ├── loading_overlay.dart
    ├── risk_grafikleri.dart         # fl_chart grafikleri
    ├── risk_karti.dart              # Ana sonuç kartı + gauge
    └── fotograf_listesi.dart
```

---

## 🛠️ Kullanılan Teknolojiler

| Kategori | Paket |
|---|---|
| AI | `google_generative_ai` (Gemini 3 Pro / Flash) |
| Auth | `firebase_auth`, `firebase_analytics`, `firebase_crashlytics` |
| Yerel DB | `hive`, `hive_flutter` |
| Grafikler | `fl_chart ^0.69.2` |
| PDF | `pdf`, `printing`, `file_picker` |
| Harita | `flutter_map` |
| Paylaşım | `share_plus` |
| Bağlantı | `connectivity_plus` |
| Bildirimler | `flutter_local_notifications` |

---

## 🚀 Kurulum

### 1. Gereksinimler

- Flutter SDK 3.10+
- Android Studio / Xcode
- [Google AI Studio](https://aistudio.google.com/) hesabı (Gemini API Key)
- Firebase projesi

### 2. Depoyu klonlayın

```bash
git clone https://github.com/KULLANICI_ADINIZ/mimar-ai.git
cd mimar-ai/flutter_application_1
```

### 3. Bağımlılıkları yükleyin

```bash
flutter pub get
```

### 4. `.env` dosyası oluşturun

Proje kökünde `.env` dosyası oluşturun:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

> API Key almak için [Google AI Studio](https://aistudio.google.com/) → *Get API Key*

### 5. Firebase yapılandırması

```bash
# Firebase CLI kurulumu (yoksa)
npm install -g firebase-tools
flutterfire configure
```

`google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını otomatik oluşturur.

### 6. Gemini servisini yazın

```bash
cp lib/services/gemini_service.dart.example lib/services/gemini_service.dart
```

`gemini_service.dart` içinde `analizYap()` metodunu kendi Gemini prompt'unuzla doldurun. Beklenen JSON çıktı şeması dosyada belgelenmiştir.

### 7. Çalıştırın

```bash
flutter run
```

> Demo modunu deneyin — API key olmadan da UI'ı test edebilirsiniz.

---

## 📸 Ekran Görüntüleri

| Ana Sayfa | Risk Kartı | Analiz Geçmişi |
|:---:|:---:|:---:|
| <img width="338" height="710" alt="image" src="https://github.com/user-attachments/assets/c945fca3-5bc7-4f64-9f4f-0f4fe6c4e24d" />| <img width="336" height="709" alt="image" src="https://github.com/user-attachments/assets/786c3a76-0c33-4613-aa4b-5260271846ff" />| <img width="334" height="710" alt="image" src="https://github.com/user-attachments/assets/dfcea3f9-36c9-4a65-8435-2c09561a53f9" />|

| Demo Modu | Deprem Haritası | PDF Export |
|:---:|:---:|:---:|
| <img width="337" height="709" alt="image" src="https://github.com/user-attachments/assets/4c0050ae-18e8-4ee1-a2e2-182a7e75846e" />| <img width="337" height="707" alt="image" src="https://github.com/user-attachments/assets/0d92cccb-2e08-4316-ac25-c513e33ce9a3" />| <img width="343" height="708" alt="image" src="https://github.com/user-attachments/assets/6bf4c010-5a0a-4985-b7d9-481c820e2a84" />|

---

## 🔒 Güvenlik Notları

| Dosya | Durum | Neden |
|---|---|---|
| `.env` | 🔒 Gizli | Gemini API Key |
| `google-services.json` | 🔒 Gizli | Firebase proje kimliği |
| `GoogleService-Info.plist` | 🔒 Gizli | Firebase iOS kimliği |
| `lib/services/gemini_service.dart` | 🔒 Gizli | Tescilli prompt mühendisliği |

---


<div align="center">

Deprem güvenliğine katkı için geliştirilmiştir 🇹🇷

</div>
