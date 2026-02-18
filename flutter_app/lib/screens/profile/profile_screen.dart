import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/tts_service.dart';
import '../../services/local_database.dart';
import '../../services/share_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalDatabase _localDb = LocalDatabase();
  final TtsService _ttsService = TtsService();
  final ShareService _shareService = ShareService();

  String _selectedCity = 'Ankara';
  String _prayerMethod = 'Diyanet';
  bool _notificationsEnabled = true;
  double _ttsSpeed = 1.0;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
  }

  Future<void> _loadPreferences() async {
    final city = await _localDb.getPreference('city');
    final method = await _localDb.getPreference('prayer_method');
    final notifications = await _localDb.getPreference('notifications');
    final speed = await _localDb.getPreference('tts_speed');

    setState(() {
      if (city != null) _selectedCity = city;
      if (method != null) _prayerMethod = method;
      if (notifications != null) _notificationsEnabled = notifications == 'true';
      if (speed != null) _ttsSpeed = double.tryParse(speed) ?? 1.0;
    });

    // Update TTS speed
    await _ttsService.setSpeed(_ttsSpeed);
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> _savePreference(String key, String value) async {
    await _localDb.setPreference(key, value);
  }

  void _showCityPicker() {
    final cities = [
      'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya',
      'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın', 'Balıkesir',
      'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis',
      'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum',
      'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
      'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari',
      'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş',
      'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kırıkkale',
      'Kırklareli', 'Kırşehir', 'Kilis', 'Kocaeli', 'Konya', 'Kütahya',
      'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
      'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya',
      'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Şanlıurfa', 'Şırnak',
      'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van',
      'Yalova', 'Yozgat', 'Zonguldak'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Şehir Seçin',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = _selectedCity == city;
                    return ListTile(
                      title: Text(
                        city,
                        style: TextStyle(
                          color: isSelected ? AppColors.gold : AppColors.textLight,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.gold)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                        });
                        _savePreference('city', city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrayerMethodPicker() {
    final methods = ['Diyanet', 'MWL', 'ISNA', 'Egyptian', 'Karachi'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesaplama Metodu',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...methods.map((method) {
                final isSelected = _prayerMethod == method;
                return ListTile(
                  title: Text(
                    method,
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.textLight,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.gold)
                      : null,
                  onTap: () {
                    setState(() {
                      _prayerMethod = method;
                    });
                    _savePreference('prayer_method', method);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showTtsSpeedSlider() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesli Okuma Hızı',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        '0.5x',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: Slider(
                          value: _ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: '${_ttsSpeed}x',
                          activeColor: AppColors.gold,
                          inactiveColor: AppColors.textMuted.withOpacity(0.3),
                          onChanged: (value) {
                            setModalState(() {
                              _ttsSpeed = value;
                            });
                            setState(() {
                              _ttsSpeed = value;
                            });
                            _ttsService.setSpeed(value);
                            _savePreference('tts_speed', value.toString());
                          },
                        ),
                      ),
                      const Text(
                        '2.0x',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${_ttsSpeed.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkMid,
          title: const Row(
            children: [
              Text(
                '🕌',
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(width: 12),
              Text(
                'Minber',
                style: TextStyle(
                  color: AppColors.gold,
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versiyon: $_appVersion',
                style: const TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              const Text(
                'Diyanet İşleri Başkanlığı\'nın tüm hutbelerine ve namaz vakitlerine kolayca erişin.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2024 Minber\nTüm hakları saklıdır.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tamam',
                style: TextStyle(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkMid
          : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema Seçimi',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textLight
                      : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                context,
                title: 'Koyu Tema',
                icon: Icons.dark_mode,
                isSelected: themeProvider.isDarkMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context,
                title: 'Açık Tema',
                icon: Icons.light_mode,
                isSelected: themeProvider.isLightMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              _buildThemeOption(
                context,
                title: 'Sistem Teması',
                icon: Icons.brightness_auto,
                isSelected: themeProvider.isSystemMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.gold : (isDark ? AppColors.textMuted : AppColors.textDarkMuted),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AppColors.gold
              : (isDark ? AppColors.textLight : AppColors.textDark),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.gold)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String themeLabel = 'Koyu';
    if (themeProvider.isLightMode) {
      themeLabel = 'Açık';
    } else if (themeProvider.isSystemMode) {
      themeLabel = 'Sistem';
    }
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkMid : AppColors.lightSurface,
        title: const Text('Profil & Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCity,
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
            height: 1,
            thickness: 0.5,
          ),

          // Settings
          _buildSettingItem(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: themeLabel,
            onTap: _showThemePicker,
          ),

          _buildSettingItem(
            icon: Icons.location_on,
            title: 'Konum Ayarı',
            subtitle: _selectedCity,
            onTap: _showCityPicker,
          ),

          _buildSettingItem(
            icon: Icons.mosque,
            title: 'Namaz Vakti Hesaplama',
            subtitle: _prayerMethod,
            onTap: _showPrayerMethodPicker,
          ),

          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Bildirimler',
            subtitle: _notificationsEnabled ? 'Açık' : 'Kapalı',
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: AppColors.gold,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _savePreference('notifications', value.toString());
              },
            ),
          ),

          _buildSettingItem(
            icon: Icons.volume_up,
            title: 'TTS Hızı',
            subtitle: '${_ttsSpeed.toStringAsFixed(1)}x',
            onTap: _showTtsSpeedSlider,
          ),

          Divider(
            color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
            height: 1,
            thickness: 0.5,
          ),

          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Uygulama Hakkında',
            subtitle: 'Versiyon $_appVersion',
            onTap: _showAboutDialog,
          ),

          _buildSettingItem(
            icon: Icons.star_border,
            title: 'Değerlendir',
            subtitle: 'Bizi değerlendirin',
            onTap: () {
              // TODO: Open app store
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mağaza sayfası açılacak'),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
          ),

          _buildSettingItem(
            icon: Icons.share,
            title: 'Uygulamayı Paylaş',
            subtitle: 'Arkadaşlarınızla paylaşın',
            onTap: () {
              _shareService.shareApp();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.gold,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
          fontSize: 13,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
          ),
      onTap: onTap,
    );
  }
}
