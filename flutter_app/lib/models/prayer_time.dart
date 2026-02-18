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
  final String imsak;
  final String? date;
  final String? hijriDate;
  final String? location;

  PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    String? imsak,
    this.date,
    this.hijriDate,
    this.location,
  }) : imsak = imsak ?? fajr;

  // Turkish aliases for compatibility
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
        fajr: (json['Fajr'] ?? '') as String,
        imsak: json['Imsak'] as String?,
        sunrise: (json['Sunrise'] ?? json['Gunes'] ?? '') as String,
        dhuhr: (json['Dhuhr'] ?? json['Ogle'] ?? '') as String,
        asr: (json['Asr'] ?? json['Ikindi'] ?? '') as String,
        maghrib: (json['Maghrib'] ?? json['Aksam'] ?? '') as String,
        isha: (json['Isha'] ?? json['Yatsi'] ?? '') as String,
        date: json['date'] as String?,
        hijriDate: json['hijriDate'] as String?,
        location: json['location'] as String?,
      );
    }
    
    // Fallback or complex structure handling could go here if needed
    return PrayerTimings(
      fajr: '', sunrise: '', dhuhr: '', asr: '', maghrib: '', isha: '',
    );
  }

  List<PrayerTime> get allPrayers => [
    PrayerTime(name: getTurkishName('Imsak'), time: imsak),
    PrayerTime(name: getTurkishName('Sunrise'), time: sunrise),
    PrayerTime(name: getTurkishName('Dhuhr'), time: dhuhr),
    PrayerTime(name: getTurkishName('Asr'), time: asr),
    PrayerTime(name: getTurkishName('Maghrib'), time: maghrib),
    PrayerTime(name: getTurkishName('Isha'), time: isha),
  ];
  
  // Turkish prayer names
  static const Map<String, String> turkishNames = {
    'Imsak': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };
  
  String getTurkishName(String englishName) {
    return turkishNames[englishName] ?? englishName;
  }
  
  // Calculate next prayer time and name
  String get nextPrayerName {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = [
      {'name': 'Imsak', 'time': imsak},
      {'name': 'Sunrise', 'time': sunrise},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];
    
    for (var prayer in prayers) {
      if (_compareTime(currentTime, prayer['time']!) < 0) {
        return prayer['name']!;
      }
    }
    
    // If all prayers have passed, next prayer is tomorrow's Imsak
    return 'Imsak';
  }
  
  String get nextPrayerTime {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final prayers = [
      {'name': 'Imsak', 'time': imsak},
      {'name': 'Sunrise', 'time': sunrise},
      {'name': 'Dhuhr', 'time': dhuhr},
      {'name': 'Asr', 'time': asr},
      {'name': 'Maghrib', 'time': maghrib},
      {'name': 'Isha', 'time': isha},
    ];
    
    for (var prayer in prayers) {
      if (_compareTime(currentTime, prayer['time']!) < 0) {
        return prayer['time']!;
      }
    }
    
    // If all prayers have passed, next prayer is tomorrow's Imsak
    return imsak;
  }
  
  // Compare two time strings in HH:mm format
  int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');
    
    final hour1 = int.tryParse(parts1[0]) ?? 0;
    final min1 = int.tryParse(parts1[1]) ?? 0;
    final hour2 = int.tryParse(parts2[0]) ?? 0;
    final min2 = int.tryParse(parts2[1]) ?? 0;
    
    if (hour1 != hour2) return hour1 - hour2;
    return min1 - min2;
  }
}
