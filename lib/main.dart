import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/lock_service.dart';
import 'services/budget_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService().init();
  await LockService().init();
  await BudgetService().init();
  _applySystemUI(ThemeService().isDark);
  runApp(const MoneyTrackerApp());
}

void _applySystemUI(bool isDark) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  ));
}

class MoneyTrackerApp extends StatefulWidget {
  const MoneyTrackerApp({super.key});
  @override
  State<MoneyTrackerApp> createState() => _MoneyTrackerAppState();
}

class _MoneyTrackerAppState extends State<MoneyTrackerApp> {
  final _theme = ThemeService();

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    _applySystemUI(_theme.isDark);
    setState(() {});
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _theme.isDark;
    return MaterialApp(
      title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        colorSchemeSeed: AppColors.accent,
        useMaterial3: true,
      ),
      home: const LockScreen(child: HomeScreen()),
    );
  }
}
