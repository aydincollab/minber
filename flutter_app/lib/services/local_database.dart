import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/hutbe.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'minber.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Saved hutbes table
    await db.execute('''
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
    ''');

    // Reading history table
    await db.execute('''
      CREATE TABLE reading_history (
        hutbe_id TEXT PRIMARY KEY,
        last_read_at TEXT NOT NULL,
        read_count INTEGER NOT NULL DEFAULT 1,
        scroll_position REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (hutbe_id) REFERENCES saved_hutbes (id) ON DELETE CASCADE
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    debugPrint('Database tables created successfully');
  }

  // Hutbe operations
  Future<void> saveHutbe(Hutbe hutbe) async {
    final db = await database;
    
    await db.insert(
      'saved_hutbes',
      {
        'id': hutbe.id,
        'title': hutbe.title,
        'content': hutbe.content,
        'summary': hutbe.summary,
        'date': hutbe.date.toIso8601String(),
        'year': hutbe.year,
        'category': hutbe.category,
        'reading_time_minutes': hutbe.readingTimeMinutes,
        'source_url': hutbe.sourceUrl,
        'is_favorite': 0,
        'saved_at': DateTime.now().toIso8601String(),
        'created_at': hutbe.createdAt.toIso8601String(),
        'updated_at': hutbe.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    debugPrint('Hutbe saved: ${hutbe.id}');
  }

  Future<void> removeHutbe(String id) async {
    final db = await database;
    await db.delete(
      'saved_hutbes',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('Hutbe removed: $id');
  }

  Future<List<Hutbe>> getSavedHutbes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_hutbes',
      orderBy: 'saved_at DESC',
    );

    return maps.map((map) => Hutbe(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      date: DateTime.parse(map['date'] as String),
      year: map['year'] as int,
      category: map['category'] as String?,
      readingTimeMinutes: map['reading_time_minutes'] as int?,
      sourceUrl: map['source_url'] as String?,
      isFeatured: false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<bool> isHutbeSaved(String id) async {
    final db = await database;
    final result = await db.query(
      'saved_hutbes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<Hutbe?> getHutbeById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_hutbes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    return Hutbe(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      date: DateTime.parse(map['date'] as String),
      year: map['year'] as int,
      category: map['category'] as String?,
      readingTimeMinutes: map['reading_time_minutes'] as int?,
      sourceUrl: map['source_url'] as String?,
      isFeatured: false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Favorites operations
  Future<void> toggleFavorite(String hutbeId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'saved_hutbes',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [hutbeId],
    );
    debugPrint('Favorite toggled for: $hutbeId');
  }

  Future<List<Hutbe>> getFavoriteHutbes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_hutbes',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'saved_at DESC',
    );

    return maps.map((map) => Hutbe(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      date: DateTime.parse(map['date'] as String),
      year: map['year'] as int,
      category: map['category'] as String?,
      readingTimeMinutes: map['reading_time_minutes'] as int?,
      sourceUrl: map['source_url'] as String?,
      isFeatured: false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    )).toList();
  }

  Future<bool> isFavorite(String hutbeId) async {
    final db = await database;
    final result = await db.query(
      'saved_hutbes',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [hutbeId],
      limit: 1,
    );
    
    if (result.isEmpty) return false;
    return result.first['is_favorite'] == 1;
  }

  // Reading history operations
  Future<void> updateReadingProgress(String hutbeId, double scrollPosition) async {
    final db = await database;
    
    final existing = await db.query(
      'reading_history',
      where: 'hutbe_id = ?',
      whereArgs: [hutbeId],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('reading_history', {
        'hutbe_id': hutbeId,
        'last_read_at': DateTime.now().toIso8601String(),
        'read_count': 1,
        'scroll_position': scrollPosition,
      });
    } else {
      await db.update(
        'reading_history',
        {
          'last_read_at': DateTime.now().toIso8601String(),
          'read_count': (existing.first['read_count'] as int) + 1,
          'scroll_position': scrollPosition,
        },
        where: 'hutbe_id = ?',
        whereArgs: [hutbeId],
      );
    }
  }

  Future<double> getReadingProgress(String hutbeId) async {
    final db = await database;
    final result = await db.query(
      'reading_history',
      columns: ['scroll_position'],
      where: 'hutbe_id = ?',
      whereArgs: [hutbeId],
      limit: 1,
    );
    
    if (result.isEmpty) return 0.0;
    return result.first['scroll_position'] as double;
  }

  // User preferences operations
  Future<void> setPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await database;
    final result = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  // Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('saved_hutbes');
    await db.delete('reading_history');
    await db.delete('user_preferences');
    debugPrint('All data cleared');
  }
}
