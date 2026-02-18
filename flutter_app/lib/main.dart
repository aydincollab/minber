import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // Add providers here as needed
        // ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
        // ChangeNotifierProvider(create: (_) => HutbeProvider()),
      ],
      child: const MinberApp(),
    ),
  );
}
