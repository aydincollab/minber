class PrayerTime {
  final String name;
  final String time;

  PrayerTime({
    required this.name,
    required this.time,
  });

  factory PrayerTime.fromJson(String name, String time) {
    return PrayerTime(
      name: name,
      time: time,
    );
  }
}

class PrayerTimings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  // Turkish aliases for compatibility
  String get imsak => fajr;
  String get gunes => sunrise;
  String get ogle => dhuhr;
  String get ikindi => asr;
  String get aksam => maghrib;
  String get yatsi => isha;

  factory PrayerTimings.fromJson(Map<String, dynamic> json) {
    // Check if we are parsing Aladhan API response directly or our own backend
    // Aladhan API structure: data.timings.Fajr
    // But here we might receive just the timings map if pre-processed
    
    // If it's a direct map of timings (from ApiService constructions)
    if (json.containsKey('Fajr') || json.containsKey('Imsak')) {
      return PrayerTimings(
        fajr: (json['Fajr'] ?? json['Imsak'] ?? '') as String,
        sunrise: (json['Sunrise'] ?? json['Gunes'] ?? '') as String,
        dhuhr: (json['Dhuhr'] ?? json['Ogle'] ?? '') as String,
        asr: (json['Asr'] ?? json['Ikindi'] ?? '') as String,
        maghrib: (json['Maghrib'] ?? json['Aksam'] ?? '') as String,
        isha: (json['Isha'] ?? json['Yatsi'] ?? '') as String,
      );
    }
    
    // Fallback or complex structure handling could go here if needed
    return PrayerTimings(
      fajr: '', sunrise: '', dhuhr: '', asr: '', maghrib: '', isha: '',
    );
  }

  List<PrayerTime> get allPrayers => [
    PrayerTime(name: getTurkishName('Fajr'), time: fajr),
    PrayerTime(name: getTurkishName('Sunrise'), time: sunrise),
    PrayerTime(name: getTurkishName('Dhuhr'), time: dhuhr),
    PrayerTime(name: getTurkishName('Asr'), time: asr),
    PrayerTime(name: getTurkishName('Maghrib'), time: maghrib),
    PrayerTime(name: getTurkishName('Isha'), time: isha),
  ];
  
  // Turkish prayer names
  static const Map<String, String> turkishNames = {
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };
  
  String getTurkishName(String englishName) {
    return turkishNames[englishName] ?? englishName;
  }
}
