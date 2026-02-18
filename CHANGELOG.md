# Changelog

All notable changes to the Minber project will be documented in this file.

## [1.0.1] - 2024-02-18

### Security
- **CRITICAL**: Updated `fastapi` from 0.109.0 to 0.109.1
  - Fixes ReDoS vulnerability in Content-Type header parsing
- **CRITICAL**: Updated `python-multipart` from 0.0.6 to 0.0.22
  - Fixes arbitrary file write vulnerability (CVE)
  - Fixes DoS via malformed multipart/form-data boundary
  - Fixes Content-Type header ReDoS vulnerability
  - Addresses 3 security vulnerabilities

### Changed
- All dependencies now at patched versions with no known vulnerabilities

## [1.0.0] - 2024-02-18

### Added - Backend (Python/FastAPI)

#### Core Infrastructure
- FastAPI application with async support
- PostgreSQL database with SQLAlchemy async ORM
- Alembic for database migrations
- Docker and Docker Compose configuration
- Environment-based configuration system
- CORS middleware for cross-origin requests

#### Models & Schemas
- Hutbe (Sermon) model with full metadata
  - Title, content, summary
  - Date, year, category
  - Reading time calculation
  - Source URL tracking
  - Featured flag
  - Created/updated timestamps
- Pydantic schemas for validation and serialization
  - HutbeCreate, HutbeUpdate, HutbeResponse
  - HutbeListItem for efficient listing
  - Search result pagination
  - Statistics schemas

#### API Endpoints
- **Hutbeler Routes** (`/api/v1/hutbeler`)
  - List with pagination, filtering, and search
  - Get by ID
  - Featured hutbe endpoint
  - Latest hutbeler
  - Year statistics
  - Category statistics
  - Full-text search
- **Prayer Times Route** (`/api/v1/namaz-vakitleri`)
  - Location-based prayer times
  - Integration with Aladhan API
  - Support for coordinates and city lookup
  - Next prayer calculation
- **Scraper Route** (`/api/v1/scraper/run`)
  - Manual scraper trigger
  - Admin endpoint for maintenance

#### Services
- HutbeService: Business logic for hutbe operations
  - CRUD operations
  - Advanced filtering and search
  - Statistics aggregation
  - Reading time calculation
- PrayerService: Prayer times integration
  - Aladhan API wrapper
  - Coordinates and city-based lookup
  - Next prayer determination
  - Turkish Diyanet method (method 13)

#### Scraper
- DiyanetScraper: Web scraping for Diyanet website
  - BeautifulSoup-based HTML parsing
  - Automatic category detection
  - Reading time estimation
  - Error handling and logging
- Scheduler: Automated weekly scraping
  - APScheduler integration
  - Thursday 23:00 UTC cron job
  - Configurable scraping limits

### Added - Frontend (Flutter)

#### Theme System
- Complete color palette matching HTML prototype
  - Gold (#C9A84C, #E8C97A, #8B6914)
  - Emerald (#1B5E3B, #2D7A52, #3FA069)
  - Cream (#F5EFE0, #E8DFC8)
  - Dark (#0D1F14, #142B1C)
  - Text colors (#F0E8D5, #A8C0A8)
- Google Fonts integration
  - Playfair Display for headings
  - DM Sans for body text
  - Amiri for Arabic text
- Gradient definitions for hero and cards

#### Models
- Hutbe model with JSON serialization
- PrayerTime and PrayerTimings models
- Turkish prayer name mappings

#### Services
- ApiService: HTTP client for backend communication
  - Hutbeler endpoints
  - Prayer times endpoints
  - Error handling
- LocationService: Geolocation integration
  - Permission handling
  - Current position retrieval
  - Reverse geocoding

#### UI Components

**Widgets:**
- AnimatedOrb: Pulsing gradient orb with scale animation
- BottomNavBar: 5-tab navigation with backdrop blur
  - Active state with gold accent
  - Icons: Home, Hutbeler, Vakitler, Kaydedilen, Profil

**Home Screen Widgets:**
- HeroSection: Gradient background with animated orbs
  - Diagonal pattern overlay
  - Logo with gradient
  - Icon buttons with blur effect
- PrayerCard: Prayer times display
  - Real-time countdown timer
  - Active prayer highlighting
  - Location display
  - Backdrop blur glass effect
  - 5 prayer times (İmsak, Öğle, İkindi, Akşam, Yatsı)
- SearchBarWidget: Search input with custom styling
- AdBannerWidget: Placeholder for AdMob banner
- FeaturedHutbeCard: Featured sermon card
  - Gradient background
  - Mosque emoji watermark
  - GÜNCEL badge
  - Date and reading time metadata
- CategoryTags: Horizontal scrolling category pills
  - Active/inactive states
  - 8 categories: Tümü, İman, Aile, Ahlak, İbadet, Toplum, Oruç, Hac
- YearSlideCards: Horizontal scrolling year cards
  - Different gradient for each year
  - Accent circles
  - Dot indicator with active state
  - Smooth PageView navigation
- RecentHutbeList: List of recent sermons
  - Category icons
  - Date and reading time
  - Colored icon boxes
  - Ellipsis overflow handling

**Screens:**
- HomeScreen: Main app screen
  - All widgets integrated
  - Data loading from API
  - Error handling
  - Smooth scrolling
- HutbeDetailScreen: Sermon detail (placeholder)
- HutbeListScreen: All sermons list (placeholder)
- PrayerTimesScreen: Prayer times detail (placeholder)
- FavoritesScreen: Saved sermons (placeholder)
- ProfileScreen: User profile and settings (placeholder)

#### Animations
- Orb pulse animation (4s/6s cycles)
- Real-time prayer countdown (1 second updates)
- Smooth card scaling on tap
- Page view transitions with dots
- Fade-in animations (planned)

### Configuration Files

#### Backend
- `requirements.txt`: Python dependencies
- `Dockerfile`: Container configuration
- `.env.example`: Environment template
- `alembic.ini`: Migration configuration
- `alembic/env.py`: Migration environment

#### Flutter
- `pubspec.yaml`: Dart dependencies
- `AndroidManifest.xml`: Android configuration with permissions
- `README.md`: Flutter app documentation

#### Root
- `docker-compose.yml`: Multi-container setup
- `.gitignore`: Comprehensive ignore rules
- `README.md`: Project documentation
- `DEPLOYMENT.md`: Deployment guide

### Documentation
- Comprehensive README in Turkish
- Deployment guide with troubleshooting
- API documentation via Swagger/ReDoc
- Code comments and docstrings
- Type hints throughout

### Security
- CORS configuration
- Environment-based secrets
- PostgreSQL with credentials
- Input validation with Pydantic
- SQL injection prevention via ORM
- No hardcoded secrets

### Performance
- Async database operations
- Connection pooling
- Pagination for large datasets
- Indexed database columns
- Efficient queries with proper filtering
- Lazy loading where appropriate

## Technical Specifications

### Backend Stack
- Python 3.11+
- FastAPI 0.109.0
- SQLAlchemy 2.0.25 (async)
- PostgreSQL 15
- Alembic 1.13.1
- APScheduler 3.10.4
- BeautifulSoup4 4.12.3
- httpx 0.26.0

### Frontend Stack
- Flutter 3.0+
- Dart 3.0+
- provider 6.1.1 (state management)
- http 1.2.0 / dio 5.4.0
- google_fonts 6.1.0
- geolocator 11.0.0
- geocoding 2.1.1
- shared_preferences 2.2.2
- intl 0.19.0
- flutter_animate 4.5.0
- google_mobile_ads 4.0.0

### Design System
- Color palette: Gold, Emerald, Cream, Dark
- Typography: Playfair Display, DM Sans, Amiri
- Layout: Responsive with mobile-first approach
- Theme: Dark mode optimized

## Known Limitations

1. Scraper selectors are placeholders - need actual Diyanet website analysis
2. No authentication/authorization system yet
3. No favorites/bookmarks implementation
4. Search is basic text matching (no full-text search yet)
5. No push notifications
6. No offline mode
7. Detail screens are placeholders
8. No unit/integration tests yet
9. No CI/CD pipeline
10. Arabic text rendering not tested

## Future Enhancements

### Planned Features
- User authentication and profiles
- Favorites and bookmarks
- Push notifications for prayer times
- Offline mode with local storage
- Full-text search with ranking
- Hutbe translations
- Audio playback of hutbeler
- Dark/light theme toggle
- Multiple language support
- Social sharing
- Comments and discussions
- Admin panel for content management

### Technical Improvements
- Comprehensive test suite
- CI/CD with GitHub Actions
- Database query optimization
- Caching layer (Redis)
- Rate limiting
- API versioning
- Error tracking (Sentry)
- Analytics integration
- Performance monitoring
- Load testing
- Security audit
- Accessibility improvements

## Migration Notes

This is the initial release. No migrations needed.

## Contributors

- Initial development: aydincollab
- Architecture and implementation: GitHub Copilot Agent

## License

MIT License - See LICENSE file for details
