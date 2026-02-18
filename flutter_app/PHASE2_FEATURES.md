# Minber Flutter App - Phase 2 Features

## Overview
This document describes the Phase 2 features implemented in the Minber Flutter application, including hutbe detail screens, text-to-speech, offline mode, favorites, and sharing functionality.

## New Features

### 1. 📖 Hutbe Detail Screen
**Location:** `lib/screens/hutbe_detail/hutbe_detail_screen.dart`

A full-screen reading experience with:
- **Custom SliverAppBar** with parallax effect and emerald gradient background
- **Reading Progress Bar** that tracks scroll position
- **Text-to-Speech Controls** for audio playback
- **Favorite & Share Buttons** in the app bar
- **Formatted Content** with:
  - Drop cap effect on first paragraph
  - Quote highlighting with gold border
  - Amiri font for Arabic/Turkish text (16px, line-height 1.8)
  - Paragraph spacing (16px)
  - Active paragraph highlighting during TTS playback
- **Bottom Actions Bar** with blur backdrop
  - ❤️ Add to Favorites
  - 📤 Share
  - 🔊 Read Aloud
  - 📋 Copy Content

### 2. 🔊 Text-to-Speech (TTS)
**Location:** `lib/services/tts_service.dart`

Features:
- Turkish TTS (tr-TR locale) using `flutter_tts` package
- **Speed Control**: 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2.0x
- **Playback Controls**: Play, Pause, Stop, Resume
- **Progress Tracking**: Word and paragraph tracking
- **Mini Player Widget** (floating, persistent during playback)
  - Play/Pause button (gold circular)
  - Progress bar
  - Speed selector
  - Close button
- **Active Paragraph Highlighting** during reading

### 3. 📴 Offline Mode
**Location:** `lib/services/local_database.dart`

SQLite-based offline storage:
- **Database Tables**:
  - `saved_hutbes`: Full hutbe content
  - `reading_history`: Reading progress tracking
  - `user_preferences`: App settings
- **Features**:
  - Save hutbes for offline reading
  - Automatic fallback to offline data when no internet
  - Offline indicator banner
  - Reading progress persistence
  - Favorite status persistence

### 4. 🔖 Favorites System
**Location:** `lib/services/favorites_service.dart`, `lib/screens/favorites/favorites_screen.dart`

Features:
- **Animated Heart Button** with scale bounce effect
- **Favorites Screen** with:
  - Grid/List view of saved hutbes
  - Swipe to delete functionality
  - Empty state illustration
  - Sort by date or saved date
  - Pull-to-refresh
- **SQLite Storage** for offline access
- **Provider-based State Management**

### 5. 📤 Share System
**Location:** `lib/services/share_service.dart`

Share options:
- **Text Share**: Hutbe title + summary + app footer
- **Snippet Share**: Selected text with attribution
- **App Recommendation**: Formatted promotional text
- **Future**: Image card generation for social media (Instagram/WhatsApp story format)

### 6. 📋 Enhanced Hutbe List
**Location:** `lib/screens/hutbe_list/hutbe_list_screen.dart`

Features:
- **Search Bar**: Real-time search
- **Category Filters**: Filter chips with Tümü, İman, Aile, Ahlak, İbadet, Toplum
- **Year Selector**: Dropdown for year filtering
- **Infinite Scroll**: Pagination with "load more"
- **Pull-to-Refresh**
- **Shimmer Loading**: Skeleton loading effect
- **Offline Mode**: Shows saved hutbes when offline
- **Empty State**: User-friendly message when no results

### 7. 🕌 Prayer Times Screen
**Location:** `lib/screens/prayer_times/prayer_times_screen.dart`

Features:
- **Location-Based Times**: Auto-detects user location
- **Current Prayer Indicator**: Highlights active prayer time
- **Next Prayer Information**: Shows upcoming prayer
- **All Prayer Times**: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı
- **Refresh Functionality**
- **Error State Handling** with retry button

### 8. 👤 Profile & Settings
**Location:** `lib/screens/profile/profile_screen.dart`

Settings:
- **Location Settings**: City selector (81 Turkish cities)
- **Prayer Calculation Method**: Diyanet, MWL, ISNA, Egyptian, Karachi
- **Notifications**: Toggle on/off
- **TTS Speed**: Slider control (0.5x - 2.0x)
- **App Information**: Version, about dialog
- **Rate App**: Link to store (placeholder)
- **Share App**: Share app recommendation

### 9. 🧭 Navigation System
**Location:** `lib/screens/home/home_screen.dart`, `lib/widgets/bottom_nav_bar.dart`

Features:
- **PageView-based Navigation**: Smooth transitions between tabs
- **Bottom Navigation Bar** with 5 tabs:
  - 🏠 Ana Sayfa (Home)
  - 📖 Hutbeler (All Hutbes)
  - 🕌 Vakitler (Prayer Times)
  - 🔖 Kaydedilen (Favorites)
  - 👤 Profil (Profile)
- **State Management**: Provider-based
- **Deep Linking**: Navigate to hutbe detail from any screen

## Services Architecture

### TtsService
- Singleton pattern
- ChangeNotifier for state updates
- Automatic language detection
- Speed control persistence

### LocalDatabase
- Singleton pattern
- SQLite operations wrapper
- Async/await for all operations
- Error handling and logging

### FavoritesService
- ChangeNotifier for reactive updates
- Integration with LocalDatabase
- Favorite count tracking
- Sort and filter capabilities

### ShareService
- Share text and files
- Custom formatting for different share types
- Future-ready for image sharing

### ConnectivityService
- Real-time network status monitoring
- ChangeNotifier for status updates
- Connection type detection

## Design Consistency

All screens follow the established design system:
- **Colors**: Gold (#C9A84C), Emerald (#1B5E3B), Dark (#0D1F14)
- **Fonts**: 
  - Playfair Display (headings)
  - DM Sans (body)
  - Amiri (hutbe content)
- **Animations**: Smooth, 300ms duration
- **Spacing**: Consistent 16px/20px padding
- **Blur Effects**: Backdrop filters for overlay elements

## State Management

Using Provider package:
- `TtsService`: Global TTS state
- `FavoritesService`: Favorites management
- `ConnectivityService`: Network status

## Data Flow

```
UI Layer (Screens/Widgets)
    ↓
Services Layer (Business Logic)
    ↓
Data Layer (API/Database)
```

### Example: Adding to Favorites
1. User taps favorite button
2. FavoritesService.toggleFavorite() called
3. LocalDatabase saves/updates hutbe
4. FavoritesService notifies listeners
5. UI updates automatically

## Testing Recommendations

### Manual Testing Checklist
- [ ] Hutbe detail screen loads and scrolls smoothly
- [ ] TTS plays, pauses, and stops correctly
- [ ] Speed control changes TTS speed
- [ ] Favorites can be added and removed
- [ ] Offline mode shows saved hutbes
- [ ] Search filters hutbes correctly
- [ ] Category and year filters work
- [ ] Prayer times display correctly
- [ ] Profile settings persist
- [ ] Share functionality works
- [ ] Navigation between tabs is smooth

### Unit Testing (Future)
- TtsService state management
- LocalDatabase CRUD operations
- FavoritesService toggle logic
- ShareService text formatting

## Dependencies Added

```yaml
flutter_tts: ^4.0.2           # Text-to-speech
sqflite: ^2.3.0               # SQLite database
path_provider: ^2.1.1         # File system paths
share_plus: ^7.2.1            # Share functionality
connectivity_plus: ^5.0.2     # Network status
shimmer: ^3.0.0               # Loading animations
package_info_plus: ^5.0.1     # App version info
```

## File Structure

```
flutter_app/lib/
├── services/
│   ├── tts_service.dart              # Text-to-speech
│   ├── favorites_service.dart        # Favorites management
│   ├── local_database.dart           # SQLite operations
│   ├── share_service.dart            # Share functionality
│   └── connectivity_service.dart     # Network monitoring
├── screens/
│   ├── hutbe_detail/
│   │   ├── hutbe_detail_screen.dart  # Main detail screen
│   │   └── widgets/
│   │       ├── hutbe_content.dart    # Content display
│   │       ├── tts_mini_player.dart  # TTS controls
│   │       ├── reading_progress.dart # Progress bar
│   │       └── share_card.dart       # Share card design
│   ├── hutbe_list/
│   │   └── hutbe_list_screen.dart    # Enhanced list
│   ├── favorites/
│   │   └── favorites_screen.dart     # Favorites screen
│   ├── prayer_times/
│   │   └── prayer_times_screen.dart  # Prayer times
│   ├── profile/
│   │   └── profile_screen.dart       # Settings
│   └── home/
│       └── home_screen.dart          # Main navigation
├── widgets/
│   ├── bottom_nav_bar.dart           # Navigation bar
│   ├── favorite_button.dart          # Animated button
│   └── offline_banner.dart           # Offline indicator
└── main.dart                         # App entry with providers
```

## Performance Considerations

1. **Lazy Loading**: Hutbe list uses pagination
2. **Caching**: SQLite caches frequently accessed data
3. **Image Optimization**: Future feature for share cards
4. **State Management**: Provider minimizes rebuilds
5. **Async Operations**: All I/O operations are async

## Future Enhancements

1. **Image Share Cards**: Generate beautiful cards for social media
2. **Push Notifications**: Prayer time reminders
3. **Bookmarks**: Mark specific paragraphs in hutbes
4. **Notes**: Personal notes on hutbes
5. **Reading Statistics**: Track reading habits
6. **Dark/Light Theme**: Theme switching
7. **Multiple Languages**: English, Arabic support
8. **Background Audio**: Continue TTS when app is backgrounded

## Known Limitations

1. TTS requires internet for first-time language download
2. Offline mode requires manual save (no auto-sync yet)
3. Share cards are text-only (image generation pending)
4. No user authentication yet
5. Limited to Turkish prayer calculation methods

## Troubleshooting

### TTS Not Working
- Check device language settings
- Ensure Turkish TTS is installed
- Verify audio permissions

### Offline Mode Issues
- Check storage permissions
- Verify SQLite initialization
- Clear app data and retry

### Navigation Problems
- Check PageController state
- Verify provider setup in main.dart

## Credits

Developed for Minber - Hutbe & Namaz Vakitleri
Design System: Emerald & Gold theme
Content Source: Diyanet İşleri Başkanlığı
