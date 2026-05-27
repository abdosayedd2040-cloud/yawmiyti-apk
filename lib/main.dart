import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ggzdxvoiwcbzwsvryoun.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnemR4dm9pd2NiendzdnJ5b3VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MjA4OTUsImV4cCI6MjA5Mzk5Njg5NX0.gI-bfLg-lD8CoZmCU5wzinabPItDF-u-K8t67Lqxm2c',
  );

  final prefs = await SharedPreferences.getInstance();
  final String userId = prefs.getString('user_id') ?? '';
  final bool isDark = prefs.getBool('dark_mode') ?? false;
  final String lang = prefs.getString('language') ?? 'ar';

  runApp(MyApp(
    isLoggedIn: userId.isNotEmpty,
    isDark: isDark,
    language: lang,
  ));
}

final supabase = Supabase.instance.client;

// Global key للتحكم في التطبيق
final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isDark;
  final String language;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.isDark,
    required this.language,
  });

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDark;
  late String language;

  @override
  void initState() {
    super.initState();
    isDark = widget.isDark;
    language = widget.language;
  }

  Future<void> toggleDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => isDark = value);
  }

  Future<void> toggleLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: language == 'ar' ? 'يوميتي - ون شيفت' : 'Yawmiyti - One Shift',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Cairo',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002366),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF002366),
          foregroundColor: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF002366);
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF002366).withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Cairo',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002366),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1E1E30),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF001144),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E30),
          selectedItemColor: Color(0xFF4D79FF),
          unselectedItemColor: Colors.grey,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF4D79FF);
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF4D79FF).withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        useMaterial3: true,
      ),
      home: widget.isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}