import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hutbe.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;

  ShareService._internal();

  /// Share hutbe as text with title and summary
  Future<void> shareHutbe(Hutbe hutbe) async {
    try {
      final text = _formatHutbeText(hutbe);
      await Share.share(
        text,
        subject: hutbe.title,
      );
      debugPrint('Hutbe shared: ${hutbe.id}');
    } catch (e) {
      debugPrint('Error sharing hutbe: $e');
    }
  }

  /// Share a selected text snippet from hutbe
  Future<void> shareSnippet(String snippet, String hutbeTitle) async {
    try {
      final text = _formatSnippet(snippet, hutbeTitle);
      await Share.share(text);
      debugPrint('Snippet shared from: $hutbeTitle');
    } catch (e) {
      debugPrint('Error sharing snippet: $e');
    }
  }

  /// Share hutbe with files (for future image sharing)
  Future<void> shareWithFiles(
    String text,
    List<String> filePaths, {
    String? subject,
  }) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        files,
        text: text,
        subject: subject,
      );
      debugPrint('Shared with ${files.length} files');
    } catch (e) {
      debugPrint('Error sharing with files: $e');
    }
  }

  /// Share app recommendation
  Future<void> shareApp() async {
    try {
      const text = '''
🕌 Minber - Hutbe & Namaz Vakitleri

Diyanet İşleri Başkanlığı'nın tüm hutbelerine ve namaz vakitlerine ulaşın.

✨ Özellikler:
📖 Tüm hutbelere ücretsiz erişim
🔊 Sesli okuma özelliği
📴 Çevrimdışı okuma
🔖 Favori hutbelerinizi kaydedin
🕌 Konum bazlı namaz vakitleri

Hemen indirin ve manevi dünyanızı zenginleştirin!

#Minber #Hutbe #NamazVakitleri #Diyanet
''';
      await Share.share(text);
      debugPrint('App recommendation shared');
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  String _formatHutbeText(Hutbe hutbe) {
    final buffer = StringBuffer();
    
    // Title
    buffer.writeln('📖 ${hutbe.title}');
    buffer.writeln();
    
    // Summary if available
    if (hutbe.summary != null && hutbe.summary!.isNotEmpty) {
      buffer.writeln(hutbe.summary);
      buffer.writeln();
    }
    
    // Meta info
    buffer.writeln('📅 ${_formatDate(hutbe.date)}');
    if (hutbe.category != null) {
      buffer.writeln('🏷️ Kategori: ${hutbe.category}');
    }
    if (hutbe.readingTimeMinutes != null) {
      buffer.writeln('⏱️ Okuma süresi: ${hutbe.readingTimeMinutes} dakika');
    }
    buffer.writeln();
    
    // Footer
    buffer.writeln('───────────────────');
    buffer.writeln('Minber uygulamasından paylaşıldı 🕌');
    buffer.writeln('Diyanet İşleri Başkanlığı');
    
    return buffer.toString();
  }

  String _formatSnippet(String snippet, String hutbeTitle) {
    final buffer = StringBuffer();
    
    buffer.writeln('«$snippet»');
    buffer.writeln();
    buffer.writeln('───────────────────');
    buffer.writeln('— $hutbeTitle');
    buffer.writeln('Minber 🕌');
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
