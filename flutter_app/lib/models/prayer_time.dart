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
  final PrayerTime fajr;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;
  final String date;
  final String hijriDate;
  final String location;
  final String? nextPrayerName;
  final String? nextPrayerTime;

  PrayerTimings({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.hijriDate,
    required this.location,
    this.nextPrayerName,
    this.nextPrayerTime,
  });

  factory PrayerTimings.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final dateInfo = json['date'] as Map<String, dynamic>;
    final nextPrayer = json['next_prayer'] as Map<String, dynamic>?;

    return PrayerTimings(
      fajr: PrayerTime.fromJson('Fajr', timings['Fajr'] as String),
      dhuhr: PrayerTime.fromJson('Dhuhr', timings['Dhuhr'] as String),
      asr: PrayerTime.fromJson('Asr', timings['Asr'] as String),
      maghrib: PrayerTime.fromJson('Maghrib', timings['Maghrib'] as String),
      isha: PrayerTime.fromJson('Isha', timings['Isha'] as String),
      date: dateInfo['readable'] as String,
      hijriDate: dateInfo['hijri'] as String,
      location: json['location'] as String? ?? '',
      nextPrayerName: nextPrayer?['name'] as String?,
      nextPrayerTime: nextPrayer?['time'] as String?,
    );
  }

  List<PrayerTime> get allPrayers => [fajr, dhuhr, asr, maghrib, isha];
  
  // Turkish prayer names
  static const Map<String, String> turkishNames = {
    'Fajr': 'İmsak',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };
  
  String getTurkishName(String englishName) {
    return turkishNames[englishName] ?? englishName;
  }
}
