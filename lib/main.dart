import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI if running on desktop or test environment
  DatabaseHelper.initializeFfiIfNeeded();

  runApp(const EmergencySosApp());
}

class EmergencySosApp extends StatelessWidget {
  const EmergencySosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency SOS & Medical Card',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
