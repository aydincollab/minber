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
  double _speed = 0.45; // Comfortable default for Turkish
  double _currentPosition = 0.0;
  int _currentWordStart = 0;
  int _currentWordEnd = 0;
  String _currentText = '';

  TtsState get ttsState => _ttsState;
  double get speed => _speed;
  double get currentPosition => _currentPosition;
  int get currentWordStart => _currentWordStart;
  int get currentWordEnd => _currentWordEnd;
  bool get isPlaying => _ttsState == TtsState.playing;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isStopped => _ttsState == TtsState.stopped;

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
        _ttsState = TtsState.stopped;
        _currentPosition = 1.0;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        _currentText = '';
        notifyListeners();
      });

      _flutterTts.setCancelHandler(() {
        _ttsState = TtsState.stopped;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((message) {
        _ttsState = TtsState.stopped;
        notifyListeners();
        debugPrint('TTS Error: $message');
      });

      _flutterTts.setPauseHandler(() {
        _ttsState = TtsState.paused;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        _ttsState = TtsState.playing;
        notifyListeners();
      });

      _flutterTts.setProgressHandler(
        (String text, int start, int end, String word) {
          _currentWordStart = start;
          _currentWordEnd = end;
          if (_currentText.isNotEmpty) {
            _currentPosition = start / _currentText.length;
          }
          notifyListeners();
        },
      );

      debugPrint('TTS initialized — speed: $_speed');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Speak the given text from the beginning.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    // Stop any ongoing speech first
    await _flutterTts.stop();

    _currentText = text;
    _currentPosition = 0.0;

    try {
      // Always re-apply speed before speaking — Android TTS can reset it
      await _flutterTts.setSpeechRate(_speed);
      await _flutterTts.setLanguage('tr-TR');
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  /// Pause current speech.
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      // Fallback: stop and remember position
      await _flutterTts.stop();
      _ttsState = TtsState.paused;
      notifyListeners();
      debugPrint('TTS pause fallback (stop): $e');
    }
  }

  /// Resume — flutter_tts doesn't truly support resume on Android,
  /// so we restart from the beginning of the current text.
  Future<void> resume() async {
    if (_currentText.isEmpty) return;
    // Re-speak the full text; this is the best we can do cross-platform
    await speak(_currentText);
  }

  /// Stop and clear.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      _currentPosition = 0.0;
      _currentWordStart = 0;
      _currentWordEnd = 0;
      _currentText = '';
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  /// Update speech rate. Re-applies immediately even if already speaking.
  Future<void> setSpeed(double speed) async {
    if (speed < 0.25 || speed > 2.0) return;
    _speed = speed;
    try {
      await _flutterTts.setSpeechRate(speed);
      notifyListeners();

      // If currently playing, restart with new speed
      if (_ttsState == TtsState.playing && _currentText.isNotEmpty) {
        await speak(_currentText);
      }
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  // Get which paragraph index is currently being spoken
  int getCurrentParagraphIndex(List<String> paragraphs) {
    if (_currentText.isEmpty || paragraphs.isEmpty) return -1;
    int totalChars = 0;
    for (int i = 0; i < paragraphs.length; i++) {
      totalChars += paragraphs[i].length + 1; // +1 for separator
      if (_currentWordStart < totalChars) return i;
    }
    return paragraphs.length - 1;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
