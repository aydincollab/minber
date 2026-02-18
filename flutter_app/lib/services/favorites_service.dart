import 'package:flutter/foundation.dart';
import '../models/hutbe.dart';
import 'local_database.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;

  FavoritesService._internal() {
    _loadFavorites();
  }

  final LocalDatabase _db = LocalDatabase();
  List<Hutbe> _favorites = [];
  bool _isLoading = false;

  List<Hutbe> get favorites => _favorites;
  int get favoriteCount => _favorites.length;
  bool get isLoading => _isLoading;

  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _db.getFavoriteHutbes();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Hutbe hutbe) async {
    try {
      // Check if hutbe is already saved
      final isSaved = await _db.isHutbeSaved(hutbe.id);
      
      if (!isSaved) {
        // Save the hutbe first if not already saved
        await _db.saveHutbe(hutbe);
      }

      // Check current favorite status
      final currentlyFavorite = await _db.isFavorite(hutbe.id);
      
      // Toggle favorite status
      await _db.toggleFavorite(hutbe.id, !currentlyFavorite);
      
      // Reload favorites
      await _loadFavorites();
      
      debugPrint('Favorite toggled for: ${hutbe.id}, now: ${!currentlyFavorite}');
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<bool> isFavorite(String hutbeId) async {
    try {
      return await _db.isFavorite(hutbeId);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  Future<void> removeFavorite(String hutbeId) async {
    try {
      await _db.toggleFavorite(hutbeId, false);
      await _loadFavorites();
      debugPrint('Favorite removed: $hutbeId');
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  Future<void> refresh() async {
    await _loadFavorites();
  }

  // Sort favorites
  void sortByDate({bool ascending = false}) {
    if (ascending) {
      _favorites.sort((a, b) => a.date.compareTo(b.date));
    } else {
      _favorites.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  void sortBySavedDate({bool ascending = false}) {
    // Note: We would need to add saved_at to Hutbe model for this to work properly
    // For now, we'll keep the default order from database
    notifyListeners();
  }
}
