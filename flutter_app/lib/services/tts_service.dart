import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  double _speed = 0.45;
  String _currentText = '';

  // ── Paragraph-by-paragraph list playback ─────────────────────────
  List<String> _playlist = [];
  int _playlistIndex = -1;

  TtsState get ttsState => _ttsState;
  double get speed => _speed;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isStopped => _ttsState == TtsState.stopped;

  /// Index of the paragraph currently being read (-1 if not in list mode).
  int get currentParagraphIndex => _playlistIndex;

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.setSpeechRate(_speed);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        // If we're in list mode and there's a next paragraph, auto-advance
        if (_playlistIndex >= 0 &&
            _playlistIndex + 1 < _playlist.length) {
          _playlistIndex++;
          _speakCurrent();
        } else {
          _ttsState = TtsState.stopped;
          _currentText = '';
          _playlist = [];
          _playlistIndex = -1;
          notifyListeners();
        }
      });

      _flutterTts.setCancelHandler(() {
        _ttsState = TtsState.stopped;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _ttsState = TtsState.stopped;
        notifyListeners();
        debugPrint('TTS Error: $msg');
      });

      _flutterTts.setPauseHandler(() {
        _ttsState = TtsState.paused;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        _ttsState = TtsState.playing;
        notifyListeners();
      });

      debugPrint('TTS initialized — speed: $_speed');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // ── Internal helper ───────────────────────────────────────────────
  Future<void> _speakCurrent() async {
    if (_playlistIndex < 0 || _playlistIndex >= _playlist.length) return;
    final text = _playlist[_playlistIndex];
    _currentText = text;
    try {
      await _flutterTts.setSpeechRate(_speed);
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking paragraph: $e');
    }
    notifyListeners(); // notify index change immediately
  }

  // ── Public API ────────────────────────────────────────────────────

  /// Speak a list of paragraphs one by one, auto-advancing on completion.
  /// [startIndex] lets you resume from a specific paragraph.
  Future<void> speakList(List<String> paragraphs, {int startIndex = 0}) async {
    if (paragraphs.isEmpty) return;
    await _flutterTts.stop();
    _playlist = List.unmodifiable(paragraphs);
    _playlistIndex = startIndex.clamp(0, paragraphs.length - 1);
    await _speakCurrent();
  }

  /// Speak a single text (legacy / share preview etc.)
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.stop();
    _playlist = [];
    _playlistIndex = -1;
    _currentText = text;
    try {
      await _flutterTts.setSpeechRate(_speed);
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  /// Pause. On Android, flutter_tts pause may not work; fallback to stop
  /// while keeping our list position so resume() works correctly.
  Future<void> pause() async {
    try {
      final result = await _flutterTts.pause();
      if (result != 1) {
        // Pause not supported — stop but remember position
        await _flutterTts.stop();
        _ttsState = TtsState.paused;
        notifyListeners();
      }
    } catch (e) {
      await _flutterTts.stop();
      _ttsState = TtsState.paused;
      notifyListeners();
    }
  }

  /// Resume from exactly where we paused.
  /// In list mode: re-speaks the current paragraph index.
  /// In single-text mode: re-speaks the text from the beginning.
  Future<void> resume() async {
    if (_playlist.isNotEmpty && _playlistIndex >= 0) {
      // List mode — re-speak current paragraph
      await _speakCurrent();
    } else if (_currentText.isNotEmpty) {
      await speak(_currentText);
    }
  }

  /// Jump to a specific paragraph (and start speaking from there).
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _flutterTts.stop();
    _playlistIndex = index;
    await _speakCurrent();
  }

  /// Stop and clear everything.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _ttsState = TtsState.stopped;
    _currentText = '';
    _playlist = [];
    _playlistIndex = -1;
    notifyListeners();
  }

  /// Update speech rate. If playing, restarts current paragraph with new speed.
  Future<void> setSpeed(double speed) async {
    if (speed < 0.25 || speed > 2.0) return;
    _speed = speed;
    try {
      await _flutterTts.setSpeechRate(speed);
      notifyListeners();
      if (_ttsState == TtsState.playing) {
        // Restart current paragraph / text with new speed
        if (_playlist.isNotEmpty && _playlistIndex >= 0) {
          await _flutterTts.stop();
          await _speakCurrent();
        } else if (_currentText.isNotEmpty) {
          await speak(_currentText);
        }
      }
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
