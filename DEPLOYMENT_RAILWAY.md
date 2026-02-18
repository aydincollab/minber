# Railway.app Deployment Rehberi

Bu rehber, Minber uygulamasının Railway.app üzerinde nasıl deploy edileceğini adım adım açıklamaktadır.

## Gereksinimler

- GitHub hesabı
- Railway.app hesabı (GitHub ile giriş yapabilirsiniz)

## Deployment Adımları

### 1. Railway.app'e Giriş

1. [Railway.app](https://railway.app) adresine gidin
2. "Login" butonuna tıklayın
3. GitHub hesabınızla giriş yapın

### 2. Yeni Proje Oluşturma

1. Dashboard'da "New Project" butonuna tıklayın
2. "Deploy from GitHub repo" seçeneğini seçin
3. GitHub reponuzu (aydincollab/minber) seçin
4. Railway otomatik olarak projeyi deploy etmeye başlayacaktır

### 3. PostgreSQL Veritabanı Ekleme

1. Projenizin dashboard'unda "New" butonuna tıklayın
2. "Database" > "Add PostgreSQL" seçeneğini seçin
3. Railway otomatik olarak bir PostgreSQL instance'ı oluşturacak ve `DATABASE_URL` environment variable'ını ekleyecektir

### 4. Environment Variables Ayarlama

Projenizin "Variables" sekmesinde aşağıdaki environment variable'ları ekleyin:

```
DATABASE_URL=<Railway tarafından otomatik eklenir>
ENVIRONMENT=production
SECRET_KEY=<güvenli-bir-secret-key-oluşturun>
PORT=<Railway tarafından otomatik eklenir>
```

**SECRET_KEY oluşturmak için:**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 5. Deploy Ayarları

Railway, repository'deki `railway.toml` dosyasını otomatik olarak kullanacaktır. Bu dosya:
- Backend Dockerfile'ı kullanarak build yapar
- Health check endpoint'i olarak `/health` kullanır
- Hata durumunda otomatik restart yapar

### 6. Domain ve URL

1. Deploy tamamlandıktan sonra, Railway size otomatik bir domain verecektir (örn: `minber-production.up.railway.app`)
2. Bu URL'i not alın
3. Bu URL'i `flutter_app/lib/services/api_service.dart` dosyasındaki `_prodUrl` değişkenine ekleyin:

```dart
static const String _prodUrl = 'https://your-railway-domain.up.railway.app/api/v1';
```

### 7. Seed Data

Uygulama ilk kez başlatıldığında, veritabanı boş ise otomatik olarak seed data yüklenecektir. Bu işlem:
- 10 örnek hutbe içeriği ekler
- Farklı kategorilerden içerikler içerir
- İlk testler için hazır veri sağlar

### 8. Test ve Doğrulama

Deploy tamamlandıktan sonra:

1. Railway dashboard'da logları kontrol edin
2. API health check endpoint'ini test edin: `https://your-domain.railway.app/health`
3. API docs'a erişin: `https://your-domain.railway.app/docs`
4. Flutter uygulamasını güncelleyip test edin

### 9. Monitoring

Railway dashboard'u kullanarak:
- CPU ve RAM kullanımını izleyin
- Deploy loglarını kontrol edin
- Restart gerekirse manuel restart yapın

## Sorun Giderme

### Veritabanı Bağlantı Hatası

- `DATABASE_URL` environment variable'ının doğru ayarlandığından emin olun
- PostgreSQL service'inin çalıştığından emin olun

### Build Hatası

- Repository'deki `backend/Dockerfile` dosyasının doğru olduğundan emin olun
- Build loglarını kontrol edin

### Health Check Başarısız

- `/health` endpoint'inin doğru çalıştığından emin olun
- Timeout değerini artırmayı deneyin (railway.toml'da `healthcheckTimeout`)

## Notlar

- Railway ücretsiz tier'da belirli limitler vardır
- Production ortamında `DEBUG=False` ve güçlü bir `SECRET_KEY` kullanın
- Düzenli olarak veritabanı yedekleri alın
- Railway'in otomatik scaling özelliklerini inceleyin

## Destek

Railway dokümantasyonu: https://docs.railway.app/
Minber GitHub Issues: https://github.com/aydincollab/minber/issues
