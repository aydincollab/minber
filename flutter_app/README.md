# Minber Flutter App

Minber mobil uygulaması - Hutbe & Namaz Vakitleri

## Kurulum

### Gereksinimler
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode (platform'a göre)

### Bağımlılıkları Yükle

```bash
flutter pub get
```

### Uygulamayı Çalıştır

```bash
# Android
flutter run

# iOS
flutter run
```

## API Yapılandırması

Backend API URL'ini `lib/services/api_service.dart` dosyasından değiştirin:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8000/api/v1';
```

Lokal geliştirme için:
- Android Emulator: `http://10.0.2.2:8000/api/v1`
- iOS Simulator: `http://localhost:8000/api/v1`
- Fiziksel Cihaz: `http://YOUR_COMPUTER_IP:8000/api/v1`

## Konum İzinleri

### Android
`android/app/src/main/AndroidManifest.xml` dosyasına eklendi:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS  
`ios/Runner/Info.plist` dosyasına eklenmelidir:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Namaz vakitlerini konumunuza göre göstermek için konum izni gereklidir.</string>
```

## Proje Yapısı

```
lib/
├── main.dart              # Giriş noktası
├── app.dart               # MaterialApp yapılandırması
├── theme/                 # Tema ve renk paleti
│   ├── app_colors.dart
│   └── app_theme.dart
├── models/                # Veri modelleri
│   ├── hutbe.dart
│   └── prayer_time.dart
├── services/              # API ve servisler
│   ├── api_service.dart
│   └── location_service.dart
├── widgets/               # Paylaşılan widget'lar
│   ├── animated_orb.dart
│   └── bottom_nav_bar.dart
└── screens/               # Ekranlar
    ├── home/
    ├── hutbe_detail/
    ├── hutbe_list/
    ├── prayer_times/
    ├── favorites/
    └── profile/
```

## Build

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ipa --release
```

## Test

```bash
flutter test
```
