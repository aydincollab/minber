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
  double _speed = 1.0;
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

      // Set up callbacks
      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
        notifyListeners();
        debugPrint('TTS Started');
      });

      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.stopped;
        _currentPosition = 0.0;
        _currentWordStart = 0;
        _currentWordEnd = 0;
        notifyListeners();
        debugPrint('TTS Completed');
      });

      _flutterTts.setCancelHandler(() {
        _ttsState = TtsState.stopped;
        _currentPosition = 0.0;
        notifyListeners();
        debugPrint('TTS Cancelled');
      });

      _flutterTts.setErrorHandler((message) {
        _ttsState = TtsState.stopped;
        notifyListeners();
        debugPrint('TTS Error: $message');
      });

      _flutterTts.setPauseHandler(() {
        _ttsState = TtsState.paused;
        notifyListeners();
        debugPrint('TTS Paused');
      });

      _flutterTts.setContinueHandler(() {
        _ttsState = TtsState.playing;
        notifyListeners();
        debugPrint('TTS Continued');
      });

      // Progress handler for word tracking
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

      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    _currentText = text;
    _currentPosition = 0.0;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _ttsState = TtsState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      // Flutter TTS doesn't have a direct resume, so we continue
      if (_ttsState == TtsState.paused) {
        _ttsState = TtsState.playing;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }

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

  Future<void> setSpeed(double speed) async {
    if (speed < 0.5 || speed > 2.0) return;
    
    _speed = speed;
    try {
      await _flutterTts.setSpeechRate(speed);
      notifyListeners();
      debugPrint('TTS speed set to: $speed');
    } catch (e) {
      debugPrint('Error setting speed: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      debugPrint('TTS language set to: $language');
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  // Get current paragraph being read
  int getCurrentParagraphIndex(List<String> paragraphs) {
    if (_currentText.isEmpty || paragraphs.isEmpty) return -1;

    int totalChars = 0;
    for (int i = 0; i < paragraphs.length; i++) {
      totalChars += paragraphs[i].length;
      if (_currentWordStart < totalChars) {
        return i;
      }
    }
    return paragraphs.length - 1;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
