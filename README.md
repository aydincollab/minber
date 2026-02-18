# 🕌 Minber — Hutbe & Namaz Vakitleri Uygulaması

Minber, Diyanet İşleri Başkanlığı'nın yayınladığı hutbelere kolayca erişmenizi ve günlük namaz vakitlerini takip etmenizi sağlayan modern bir mobil uygulamadır.

## ✨ Özellikler

### 📖 Hutbeler
- Diyanet İşleri Başkanlığı'nın resmi hutbelerine erişim
- Yıllara ve kategorilere göre filtreleme
- Tam metin arama
- Bu haftanın öne çıkan hutbesi
- Hutbeleri favorilere ekleme
- Okuma süresi tahmini

### 🕌 Namaz Vakitleri
- Konuma dayalı otomatik namaz vakti hesaplama
- Sıradaki namaza kalan süre göstergesi
- Gerçek zamanlı geri sayım
- 5 vakit için doğru zamanlama (İmsak, Öğle, İkindi, Akşam, Yatsı)

### 🎨 Kullanıcı Arayüzü
- Modern ve şık tasarım
- Koyu tema ile göz dostu deneyim
- Akıcı animasyonlar
- Responsive tasarım

## 🛠 Teknoloji Stack'i

### Backend
- **Python 3.11+**
- **FastAPI** - Modern, hızlı web framework
- **SQLAlchemy** - ORM ve veritabanı yönetimi
- **PostgreSQL** - İlişkisel veritabanı
- **Alembic** - Veritabanı migration'ları
- **BeautifulSoup4** - Web scraping
- **APScheduler** - Zamanlanmış görevler
- **Docker & Docker Compose** - Container yönetimi

### Frontend
- **Flutter** - Cross-platform mobil uygulama framework
- **Dart** - Programlama dili
- **Google Fonts** - Tipografi (Playfair Display, DM Sans, Amiri)
- **Geolocator** - Konum servisleri
- **Provider/Riverpod** - State management
- **HTTP/Dio** - API iletişimi

### Harici API'ler
- **Aladhan API** - Namaz vakitleri hesaplama
- **Diyanet İşleri Başkanlığı** - Hutbe içerikleri

## 🚀 Kurulum

### Gereksinimler
- Docker ve Docker Compose
- Flutter SDK (3.0+)
- Python 3.11+ (lokal geliştirme için)

### Backend Kurulumu

1. Repository'yi klonlayın:
```bash
git clone https://github.com/aydincollab/minber.git
cd minber
```

2. Backend için environment dosyasını oluşturun:
```bash
cp backend/.env.example backend/.env
# .env dosyasını düzenleyerek gerekli ayarları yapın
```

3. Docker container'ları başlatın:
```bash
docker-compose up -d
```

4. Veritabanı migration'larını çalıştırın:
```bash
docker-compose exec backend alembic upgrade head
```

5. Backend artık çalışıyor: http://localhost:8000
   - API Dokümantasyonu: http://localhost:8000/docs
   - pgAdmin: http://localhost:5050 (admin@minber.com / admin)

### Flutter Uygulaması Kurulumu

1. Flutter dizinine gidin:
```bash
cd flutter_app
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
# Android için
flutter run

# iOS için
flutter run
```

## 📱 Ekran Görüntüleri

_Ekran görüntüleri yakında eklenecek_

## 🔌 API Dokümantasyonu

Backend başlatıldıktan sonra, tam API dokümantasyonuna şu adresten erişebilirsiniz:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Temel Endpoint'ler

#### Hutbeler
- `GET /api/v1/hutbeler` - Tüm hutbeleri listele
- `GET /api/v1/hutbeler/{id}` - Hutbe detayı
- `GET /api/v1/hutbeler/featured` - Bu haftanın öne çıkan hutbesi
- `GET /api/v1/hutbeler/latest` - Son eklenen hutbeler
- `GET /api/v1/hutbeler/search?q=...` - Hutbe arama

#### Namaz Vakitleri
- `GET /api/v1/namaz-vakitleri?lat=...&lng=...` - Konum bazlı namaz vakitleri

## 🔄 Scraper

Backend, Diyanet İşleri Başkanlığı sitesinden her Perşembe gecesi otomatik olarak yeni hutbeleri çeker. Manuel scraping için:

```bash
curl -X POST http://localhost:8000/api/v1/scraper/run
```

## 🏗 Proje Yapısı

```
minber/
├── backend/                    # Python/FastAPI backend
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   ├── models/            # Database models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── scraper/           # Web scraper
│   │   ├── services/          # Business logic
│   │   ├── config.py
│   │   ├── database.py
│   │   └── main.py
│   ├── alembic/               # Database migrations
│   ├── Dockerfile
│   └── requirements.txt
│
├── flutter_app/               # Flutter mobile app
│   ├── lib/
│   │   ├── screens/          # App screens
│   │   ├── widgets/          # Reusable widgets
│   │   ├── models/           # Data models
│   │   ├── services/         # API & location services
│   │   ├── theme/            # App theming
│   │   ├── app.dart
│   │   └── main.dart
│   └── pubspec.yaml
│
├── docker-compose.yml
└── README.md
```

## 🎨 Renk Paleti

```dart
Gold: #C9A84C
Gold Light: #E8C97A
Gold Dark: #8B6914
Emerald: #1B5E3B
Emerald Mid: #2D7A52
Emerald Light: #3FA069
Cream: #F5EFE0
Cream Dark: #E8DFC8
Dark: #0D1F14
Dark Mid: #142B1C
Text Light: #F0E8D5
Text Muted: #A8C0A8
```

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen şu adımları izleyin:

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📧 İletişim

Sorularınız için: [GitHub Issues](https://github.com/aydincollab/minber/issues)

---

**Not:** Bu uygulama Diyanet İşleri Başkanlığı ile resmi olarak ilişkili değildir. Hutbeler, Diyanet'in halka açık web sitesinden toplanmaktadır.
