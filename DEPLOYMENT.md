# Minber Deployment Guide

This guide explains how to deploy and run the Minber application.

## Prerequisites

- Docker and Docker Compose installed
- Flutter SDK 3.0+ (for mobile app)
- Git

## Quick Start with Docker

1. Clone the repository:
```bash
git clone https://github.com/aydincollab/minber.git
cd minber
```

2. Start the backend with Docker Compose:
```bash
docker-compose up -d
```

This will start:
- PostgreSQL database on port 5432
- FastAPI backend on port 8000
- pgAdmin on port 5050

3. Run database migrations:
```bash
docker-compose exec backend alembic upgrade head
```

4. Access the API:
- API Documentation: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- pgAdmin: http://localhost:5050 (admin@minber.com / admin)

## Manual Backend Setup (Without Docker)

### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Set Up PostgreSQL

Install PostgreSQL and create a database:
```sql
CREATE DATABASE minber_db;
CREATE USER minber_user WITH PASSWORD 'minber_password';
GRANT ALL PRIVILEGES ON DATABASE minber_db TO minber_user;
```

### 3. Configure Environment

Copy `.env.example` to `.env` and update with your settings:
```bash
cp .env.example .env
```

Edit `.env`:
```env
DATABASE_URL=postgresql+asyncpg://minber_user:minber_password@localhost:5432/minber_db
ENVIRONMENT=development
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 4. Run Migrations

```bash
alembic upgrade head
```

### 5. Start the Backend

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Flutter Mobile App Setup

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/services/api_service.dart` and set the backend URL:

For emulator/simulator:
```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// iOS Simulator
static const String baseUrl = 'http://localhost:8000/api/v1';
```

For physical device:
```dart
// Replace with your computer's IP address
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```

### 3. Run the App

```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Or just run on the first available device
flutter run
```

## API Endpoints

### Hutbeler (Sermons)

- `GET /api/v1/hutbeler` - List all hutbeler with pagination
  - Query params: `page`, `page_size`, `year`, `category`, `search`
- `GET /api/v1/hutbeler/{id}` - Get hutbe details
- `GET /api/v1/hutbeler/featured` - Get featured hutbe
- `GET /api/v1/hutbeler/latest` - Get latest hutbeler
- `GET /api/v1/hutbeler/years` - Get hutbe counts by year
- `GET /api/v1/hutbeler/categories` - Get hutbe counts by category
- `GET /api/v1/hutbeler/search?q=...` - Search hutbeler

### Namaz Vakitleri (Prayer Times)

- `GET /api/v1/namaz-vakitleri` - Get prayer times
  - Query params: `lat`, `lng`, `city`, `country`

### Scraper (Admin)

- `POST /api/v1/scraper/run` - Manually trigger scraper
  - Query params: `year`, `limit`

## Scraper Configuration

The scraper automatically runs every Thursday at 23:00 UTC. To configure:

1. Edit `backend/app/scraper/scheduler.py`
2. Modify the cron expression in `start_scheduler()`
3. Restart the backend

To manually run the scraper:
```bash
curl -X POST http://localhost:8000/api/v1/scraper/run?limit=5
```

## Production Deployment

### Backend

1. Use a production WSGI server (Gunicorn/Uvicorn workers):
```bash
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

2. Set environment variables:
```env
ENVIRONMENT=production
DEBUG=False
SECRET_KEY=<strong-random-key>
ALLOWED_ORIGINS=https://yourdomain.com
```

3. Use a reverse proxy (Nginx/Traefik)
4. Enable HTTPS with SSL certificates
5. Set up database backups
6. Configure logging and monitoring

### Flutter App

1. Build for release:
```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release
```

2. Update API base URL to production endpoint
3. Configure app signing
4. Test on real devices
5. Submit to app stores

## Environment Variables

### Backend

- `DATABASE_URL` - PostgreSQL connection string
- `ENVIRONMENT` - development/production
- `SECRET_KEY` - Secret key for sessions
- `DEBUG` - Enable debug mode
- `ALLOWED_ORIGINS` - CORS allowed origins
- `SCRAPER_ENABLED` - Enable/disable automatic scraping
- `DIYANET_BASE_URL` - Diyanet website URL

## Troubleshooting

### Backend Issues

**Database connection error:**
- Check PostgreSQL is running
- Verify DATABASE_URL is correct
- Ensure database and user exist

**Migration errors:**
- Check database connection
- Run `alembic upgrade head`
- Check migration files in `alembic/versions/`

**Import errors:**
- Ensure all dependencies are installed: `pip install -r requirements.txt`
- Check Python version (3.11+)

### Flutter Issues

**API connection error:**
- Check backend is running
- Verify API URL is correct
- Check network permissions in AndroidManifest.xml

**Location permission error:**
- Add location permissions to AndroidManifest.xml
- Add usage description to Info.plist (iOS)
- Request permissions at runtime

**Build errors:**
- Run `flutter clean`
- Run `flutter pub get`
- Check Flutter version: `flutter --version`

## Monitoring

### Backend Logs

Docker:
```bash
docker-compose logs -f backend
```

Manual:
```bash
tail -f logs/app.log
```

### Database

pgAdmin: http://localhost:5050

Connect with:
- Host: postgres (or localhost if outside Docker)
- Port: 5432
- Database: minber_db
- Username: minber_user
- Password: minber_password

## Backup and Restore

### Database Backup

```bash
docker-compose exec postgres pg_dump -U minber_user minber_db > backup.sql
```

### Database Restore

```bash
docker-compose exec -T postgres psql -U minber_user minber_db < backup.sql
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/aydincollab/minber/issues
- Documentation: See README.md
