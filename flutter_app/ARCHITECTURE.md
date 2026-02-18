# Minber Flutter App Architecture

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                          # App entry point with Providers
│   ├── app.dart                           # MaterialApp configuration
│   │
│   ├── models/                            # Data models
│   │   ├── hutbe.dart                     # Hutbe & HutbeListItem models
│   │   └── prayer_time.dart               # Prayer timings model
│   │
│   ├── services/                          # Business logic layer
│   │   ├── api_service.dart               # Backend API communication
│   │   ├── location_service.dart          # GPS & location handling
│   │   ├── tts_service.dart              # ⭐ Text-to-speech engine
│   │   ├── local_database.dart           # ⭐ SQLite operations
│   │   ├── favorites_service.dart        # ⭐ Favorites management
│   │   ├── share_service.dart            # ⭐ Share functionality
│   │   └── connectivity_service.dart     # ⭐ Network monitoring
│   │
│   ├── screens/                           # UI screens
│   │   ├── home/
│   │   │   ├── home_screen.dart          # ⚡ Enhanced: PageView navigation
│   │   │   └── widgets/
│   │   │       ├── hero_section.dart
│   │   │       ├── prayer_card.dart
│   │   │       ├── search_bar_widget.dart
│   │   │       ├── ad_banner_widget.dart
│   │   │       ├── featured_hutbe_card.dart
│   │   │       ├── category_tags.dart
│   │   │       ├── year_slide_cards.dart
│   │   │       └── recent_hutbe_list.dart
│   │   │
│   │   ├── hutbe_detail/                 # ⭐ NEW: Complete reading experience
│   │   │   ├── hutbe_detail_screen.dart  # Main detail screen
│   │   │   └── widgets/
│   │   │       ├── hutbe_content.dart    # Content renderer
│   │   │       ├── reading_progress.dart # Progress indicator
│   │   │       ├── tts_mini_player.dart  # Audio controls
│   │   │       └── share_card.dart       # Share card design
│   │   │
│   │   ├── hutbe_list/
│   │   │   └── hutbe_list_screen.dart    # ⚡ Enhanced: Search, filter, pagination
│   │   │
│   │   ├── favorites/
│   │   │   └── favorites_screen.dart     # ⭐ NEW: Favorites management
│   │   │
│   │   ├── prayer_times/
│   │   │   └── prayer_times_screen.dart  # ⚡ Enhanced: Detailed timings
│   │   │
│   │   └── profile/
│   │       └── profile_screen.dart       # ⭐ NEW: Settings & preferences
│   │
│   ├── widgets/                           # Shared widgets
│   │   ├── bottom_nav_bar.dart           # Navigation bar
│   │   ├── animated_orb.dart             # Animation widget
│   │   ├── favorite_button.dart          # ⭐ NEW: Animated heart
│   │   └── offline_banner.dart           # ⭐ NEW: Offline indicator
│   │
│   └── theme/                             # Design system
│       ├── app_colors.dart                # Color palette
│       └── app_theme.dart                 # Theme configuration
│
├── pubspec.yaml                           # ⚡ Enhanced: 7 new dependencies
├── PHASE2_FEATURES.md                     # Feature documentation
├── IMPLEMENTATION_SUMMARY.md              # Technical summary
└── ARCHITECTURE.md                        # This file
```

## Legend
- ⭐ NEW: Newly created in Phase 2
- ⚡ ENHANCED: Significantly improved in Phase 2

## Architecture Layers

### 1. Presentation Layer (UI)
```
Screens & Widgets
    ↓
User Interactions
    ↓
Service Calls
```

**Responsibilities:**
- Display data to user
- Handle user input
- Trigger service operations
- React to state changes

**Pattern:** Stateful/Stateless widgets with Provider

### 2. Business Logic Layer (Services)
```
Services (ChangeNotifier)
    ↓
Business Rules
    ↓
Data Operations
```

**Responsibilities:**
- State management
- Business logic
- Data transformation
- Event coordination

**Pattern:** Singleton services with ChangeNotifier

### 3. Data Layer
```
API Service ←→ Remote Backend
LocalDatabase ←→ SQLite
```

**Responsibilities:**
- Data persistence
- Network communication
- Caching strategy
- Error handling

**Pattern:** Repository-like services

## Data Flow Diagram

```
┌─────────────────────────────────────────────────┐
│                    UI Layer                      │
│  (Screens, Widgets, User Interactions)          │
└─────────────┬───────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────┐
│              Services Layer                      │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ TtsService   │  │ Favorites    │            │
│  │              │  │ Service      │            │
│  └──────┬───────┘  └──────┬───────┘            │
│         │                  │                     │
│  ┌──────┴───────┐  ┌──────┴───────┐            │
│  │ Share        │  │ Connectivity │            │
│  │ Service      │  │ Service      │            │
│  └──────────────┘  └──────────────┘            │
└─────────────┬───────────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────────┐
│                  Data Layer                      │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ API Service  │  │ Local        │            │
│  │              │  │ Database     │            │
│  └──────┬───────┘  └──────┬───────┘            │
│         │                  │                     │
│         ↓                  ↓                     │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Backend API  │  │ SQLite DB    │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
```

## State Management

### Provider Architecture

```dart
main.dart
  └─ MultiProvider
       ├─ TtsService (ChangeNotifier)
       ├─ FavoritesService (ChangeNotifier)
       └─ ConnectivityService (ChangeNotifier)
```

**Benefits:**
- Reactive updates
- Minimal rebuilds
- Easy testing
- Clear dependencies

### State Flow Example: Adding to Favorites

```
User taps ❤️
    ↓
FavoriteButton.onTap()
    ↓
FavoritesService.toggleFavorite()
    ↓
LocalDatabase.saveHutbe() + toggleFavorite()
    ↓
FavoritesService.notifyListeners()
    ↓
UI updates (❤️ fills with red)
```

## Database Schema

### SQLite Tables

#### saved_hutbes
```sql
CREATE TABLE saved_hutbes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  summary TEXT,
  date TEXT NOT NULL,
  year INTEGER NOT NULL,
  category TEXT,
  reading_time_minutes INTEGER,
  source_url TEXT,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  saved_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

#### reading_history
```sql
CREATE TABLE reading_history (
  hutbe_id TEXT PRIMARY KEY,
  last_read_at TEXT NOT NULL,
  read_count INTEGER NOT NULL DEFAULT 1,
  scroll_position REAL NOT NULL DEFAULT 0.0,
  FOREIGN KEY (hutbe_id) REFERENCES saved_hutbes (id)
)
```

#### user_preferences
```sql
CREATE TABLE user_preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
```

## Navigation Flow

```
HomeScreen (PageView)
    ├─ Tab 0: Home Feed
    │   └─ Tap Hutbe → HutbeDetailScreen
    │
    ├─ Tab 1: HutbeListScreen
    │   └─ Tap Hutbe → HutbeDetailScreen
    │
    ├─ Tab 2: PrayerTimesScreen
    │
    ├─ Tab 3: FavoritesScreen
    │   └─ Tap Hutbe → HutbeDetailScreen
    │
    └─ Tab 4: ProfileScreen
```

## Service Communication

### TtsService
```
HutbeDetailScreen
    ↓ speak()
TtsService
    ↓ flutter_tts
Device TTS Engine
```

### FavoritesService
```
Any Screen
    ↓ toggleFavorite()
FavoritesService
    ↓ saveHutbe() / toggleFavorite()
LocalDatabase
    ↓ SQL operations
SQLite
```

### ConnectivityService
```
ConnectivityService (auto-init)
    ↓ listens to
connectivity_plus
    ↓ notifyListeners()
All subscribed widgets
```

## Design System

### Color Palette
```dart
Gold:    #C9A84C (Primary Accent)
         #E8C97A (Light)
         #8B6914 (Dark)

Emerald: #1B5E3B (Primary Color)
         #2D7A52 (Mid)
         #3FA069 (Light)

Dark:    #0D1F14 (Background)
         #142B1C (Mid)

Text:    #F0E8D5 (Light)
         #A8C0A8 (Muted)
```

### Typography
```dart
Playfair Display: Headings, titles
DM Sans:          Body text, UI
Amiri:            Hutbe content (Arabic/Turkish)
```

### Spacing System
```dart
xs:  4px
sm:  8px
md:  12px
lg:  16px
xl:  20px
xxl: 24px
```

## Performance Optimizations

1. **Lazy Loading**: Hutbe list with pagination
2. **Caching**: SQLite for offline access
3. **Provider Scope**: Minimal rebuild scope
4. **Async Operations**: All I/O is non-blocking
5. **Image Optimization**: Future feature
6. **Memory Management**: Proper dispose() calls

## Error Handling Strategy

```dart
try {
  // Operation
} catch (e) {
  debugPrint('Error: $e');  // Log for debugging
  // Show user-friendly message
  // Fallback to cached data if available
}
```

**Principles:**
- Never crash the app
- Always provide user feedback
- Log errors for debugging
- Graceful degradation

## Testing Strategy

### Unit Tests (Future)
- Service logic
- Data transformations
- State management

### Widget Tests (Future)
- Screen rendering
- User interactions
- Navigation flows

### Integration Tests (Future)
- End-to-end flows
- Offline scenarios
- TTS functionality

## Security Considerations

1. **No Authentication**: Single-user app
2. **Local Storage**: App-sandboxed SQLite
3. **API Calls**: HTTPS only (when available)
4. **No Analytics**: Privacy-first approach
5. **No External Tracking**: All data stays local

## Accessibility Features

- Semantic labels on all interactive elements
- TTS for audio alternative
- High contrast support
- Text scaling support
- Touch target size compliance (48x48dp minimum)

## Localization Readiness

Current: Turkish only
Future support for:
- English
- Arabic
- RTL layout support

## Build Variants

- **Debug**: Development with logging
- **Profile**: Performance profiling
- **Release**: Production build

## Dependencies Overview

### Core Flutter
- `flutter/material.dart`: Material Design
- `flutter/services.dart`: Platform services

### State Management
- `provider: ^6.1.1`: Reactive state

### Networking
- `http: ^1.2.0`: HTTP client
- `dio: ^5.4.0`: Advanced HTTP

### UI
- `google_fonts: ^6.1.0`: Typography
- `flutter_animate: ^4.5.0`: Animations
- `shimmer: ^3.0.0`: Loading effects

### Location
- `geolocator: ^11.0.0`: GPS
- `geocoding: ^2.1.1`: Reverse geocoding

### Storage
- `shared_preferences: ^2.2.2`: Key-value storage
- `sqflite: ^2.3.0`: SQLite database
- `path_provider: ^2.1.1`: File paths

### Features
- `flutter_tts: ^4.0.2`: Text-to-speech
- `share_plus: ^7.2.1`: Sharing
- `connectivity_plus: ^5.0.2`: Network status
- `package_info_plus: ^5.0.1`: App info

### Utilities
- `intl: ^0.19.0`: Internationalization

## File Size Impact

- App size increase: ~5-8MB
- Dependencies: ~3-5MB
- Assets: Minimal (no images yet)

## Future Enhancements

1. **Image Share Cards**: Generate beautiful share images
2. **Push Notifications**: Prayer time reminders
3. **Background Audio**: Continue TTS in background
4. **Cloud Sync**: Backup favorites to cloud
5. **Analytics**: Privacy-respecting analytics
6. **Multi-language**: English, Arabic support
7. **Themes**: Light/Dark mode toggle
8. **Bookmarks**: Mark specific text in hutbes

---

**Last Updated**: Phase 2 Implementation
**Status**: ✅ Complete and Ready for Review
