import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/local_database.dart';
import '../../services/share_service.dart';
import '../../services/location_service.dart';
import '../../models/city_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final ShareService _shareService = ShareService();
  final LocationService _locationService = LocationService();

  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadCurrentCity();
  }

  Future<void> _loadCurrentCity() async {
    // Sadece henüz şehir belirlenmemişse konuma bak
    final preferences = Provider.of<PreferencesProvider>(context, listen: false);
    if (preferences.city == 'Ankara') {
      try {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          final city = await _locationService.getCityFromCoordinates(
            position.latitude, position.longitude,
          );
          if (city != null && mounted) {
            preferences.setCity(city);
          }
        }
      } catch (e) {
        debugPrint('Error loading city: $e');
      }
    }
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

  Future<void> _showCityPicker() async {
    final preferences = Provider.of<PreferencesProvider>(context, listen: false);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Şehir Seçin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Divider(color: Theme.of(context).dividerColor),
            Expanded(
              child: ListView.builder(
                itemCount: turkeyCities.length,
                itemBuilder: (context, index) {
                  final city = turkeyCities[index];
                  final isSelected = city == preferences.city;
                  return ListTile(
                    title: Text(city),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.gold) : null,
                    onTap: () {
                      preferences.setCity(city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrayerMethodPicker() async {
    final preferences = Provider.of<PreferencesProvider>(context, listen: false);
    final methods = ['Diyanet', 'Fazilet', 'IGMG', 'Semerkand'];
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Hesaplama Yöntemi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                final isSelected = method == preferences.prayerMethod;
                return ListTile(
                  title: Text(method),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.gold) : null,
                  onTap: () {
                    preferences.setPrayerMethod(method);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  void _showThemePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema Seçimi',
                style: Theme.of(context).textTheme.titleLarge,
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
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.gold : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.gold : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.gold)
          : null,
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkMid : AppColors.lightSurface,
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
                style: TextStyle(color: isDark ? AppColors.textLight : AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Text(
                'Diyanet İşleri Başkanlığı\'nın tüm hutbelerine ve namaz vakitlerine kolayca erişin.',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2026 Minber\nTüm hakları saklıdır.',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
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

  Future<void> _contactUs() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'appminber@gmail.com',
      queryParameters: {
        'subject': 'Minber Uygulama Geri Bildirimi',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _rateApp() async {
    // TODO: Replace with actual Play Store URL after publishing
    const storeUrl = 'https://play.google.com/store/apps';
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final preferences = Provider.of<PreferencesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String themeLabel = 'Koyu';
    if (themeProvider.isLightMode) {
      themeLabel = 'Açık';
    } else if (themeProvider.isSystemMode) {
      themeLabel = 'Sistem';
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text('Profil & Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 100),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  preferences.city,
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
            subtitle: preferences.city,
            onTap: _showCityPicker,
          ),

          _buildSettingItem(
            icon: Icons.mosque,
            title: 'Namaz Vakti Hesaplama',
            subtitle: preferences.prayerMethod,
            onTap: _showPrayerMethodPicker,
          ),

          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Bildirimler',
            subtitle: preferences.notificationsEnabled ? 'Açık' : 'Kapalı',
            trailing: Switch(
              value: preferences.notificationsEnabled,
              activeColor: AppColors.gold,
              onChanged: (value) {
                preferences.setNotificationsEnabled(value);
              },
            ),
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

          Divider(
            color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
            height: 1,
            thickness: 0.5,
          ),

          _buildSettingItem(
            icon: Icons.star_border,
            title: 'Değerlendir',
            subtitle: 'Google Play\'da puan verin',
            onTap: _rateApp,
          ),

          _buildSettingItem(
            icon: Icons.mail_outline,
            title: 'Bize Ulaşın',
            subtitle: 'Görüş ve önerileriniz için',
            onTap: _contactUs,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.textMuted.withOpacity(0.1) : AppColors.textDarkMuted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.gold,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
          fontSize: 12,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
