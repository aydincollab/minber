# 🕌 Minber

> **Diyanet İşleri Başkanlığı hutbelerine mobil erişim — çevrimdışı okuma, TTS ve kıble pusulası.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Neon-blue?logo=postgresql)](https://neon.tech)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/aydin-sasik/minber)](https://github.com/aydin-sasik/minber/releases)

---

## ✨ Ne Yapar?

Diyanet'in Cuma hutbelerini SharePoint'ten otomatik kazıyarak veritabanına kaydeder ve kullanıcılara temiz bir mobil arayüz sunar.

| Özellik | Detay |
|---|---|
| 📖 **Hutbe Okuma** | 50+ hutbe, kategori/yıl filtresi, tam metin arama |
| 🔊 **Sesli Okuma (TTS)** | Türkçe metin okuma, ayarlanabilir hız |
| ⭐ **Favoriler** | Çevrimdışı kaydetme (SQLite), kaydırarak silme |
| 🕐 **Namaz Vakitleri** | GPS veya şehir bazlı, Diyanet metodu (Aladhan API) |
| 🧭 **Kıble Pusulası** | Manyetik sapma düzeltmeli, gerçek zamanlı |
| 🔔 **Bildirimler** | Namaz vakti yerel bildirimleri |
| 📱 **Onboarding** | İlk kullanım akışı, konum izni |

---

## 👤 Kimler İçin?

- Türkçe konuşan Müslümanlar
- Cuma hutbelerini mobil cihazdan okumak/dinlemek isteyenler
- Namaz vakitlerini ve kıble yönünü tek uygulamadan takip etmek isteyenler

---

## 🏗️ Mimari

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Mobile App                  │
│  HomeScreen · HutbeList · Detail · Qibla · Prayer   │
│         Provider · SQLite · flutter_tts             │
└───────────────────────┬─────────────────────────────┘
                        │ HTTP (REST)
┌───────────────────────▼─────────────────────────────┐
│              FastAPI Backend (Render.com)             │
│   /hutbeler · /featured · /prayer-times              │
│   APScheduler cron — her Cuma 08:00 TR otomatik     │
└───────────────────────┬─────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
  PostgreSQL      Diyanet         Aladhan API
  (Neon.tech)   SharePoint       (namaz vakitleri)
                  Scraper
```

### Scraper Akışı

```
Phase 1 → SharePoint XHR API → metadata (başlık, tarih, PDF URL)
Phase 2 → pdfplumber crop()  → iki sütunlu PDF metin çıkarma
          Unicode filtresi   → Arapça satırları otomatik ayıklama
```

---

## 🚀 Kurulum

### Gereksinimler

- Flutter 3.x
- Python 3.11+
- PostgreSQL (veya Neon.tech ücretsiz)

### Backend

```bash
cd backend
pip install -r requirements.txt

# .env dosyası oluştur
cp .env.example .env
# DATABASE_URL ve ADMIN_SECRET değerlerini doldur

uvicorn app.main:app --reload
```

### Flutter Uygulaması

```bash
cd flutter_app
flutter pub get
flutter run
```

> **API URL:** `flutter_app/lib/services/api_service.dart` içinde `_prodUrl` değişkenini kendi backend adresinizle güncelleyin.

### Docker (Backend)

```bash
docker-compose up --build
```

---

## 📁 Proje Yapısı

```
minber/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI uygulaması, endpointler
│   │   ├── database.py      # SQLAlchemy async engine
│   │   ├── models.py        # ORM modelleri
│   │   └── scraper/
│   │       └── diyanet.py   # SharePoint scraper + PDF parser
│   └── requirements.txt
├── flutter_app/
│   └── lib/
│       ├── screens/         # HomeScreen, HutbeList, Detail, Qibla...
│       ├── services/        # ApiService, LocalDatabase, TTS, Notifications
│       ├── models/          # Hutbe, PrayerTime model sınıfları
│       └── main.dart
├── render.yaml              # Render.com deployment
└── docker-compose.yml
```

---

## 🔌 API Endpointleri

| Method | Endpoint | Açıklama |
|---|---|---|
| `GET` | `/api/v1/hutbeler` | Hutbe listesi (sayfalama, filtre, arama) |
| `GET` | `/api/v1/hutbeler/{id}` | Hutbe detayı |
| `GET` | `/api/v1/hutbeler/featured` | Öne çıkan hutbe |
| `GET` | `/api/v1/hutbeler/latest` | Son eklenenler |
| `GET` | `/api/v1/hutbeler/years` | Yıl bazlı istatistik |
| `POST` | `/api/v1/scraper/run` | Scraper tetikle *(admin)* |

---

## 🛠️ Kullanılan Teknolojiler

**Mobile (Flutter)**
- `flutter_tts` — Türkçe metin okuma
- `flutter_compass` — Kıble pusulası sensör verisi
- `geolocator` — GPS konumu
- `sqflite` — Çevrimdışı SQLite
- `flutter_local_notifications` — Namaz vakti bildirimleri
- `shared_preferences` — Kullanıcı ayarları
- `lottie` — Onboarding animasyonları
- `shimmer` — İskelet yükleme efekti

**Backend (Python)**
- `FastAPI` + `Uvicorn` — Async REST API
- `SQLAlchemy 2.0` — Async ORM
- `asyncpg` — PostgreSQL sürücüsü
- `pdfplumber` — PDF metin çıkarma
- `APScheduler` — Cron görevi (haftalık scraping)
- `BeautifulSoup` + `requests` — HTML/JSON kazıma

---

## 📄 Lisans

MIT © [Aydın Şaşık](https://github.com/aydin-sasik)

Hutbeler, Diyanet İşleri Başkanlığı'nın kamuya açık web sitesinden toplanmaktadır.
