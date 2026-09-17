import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/error_review_screen.dart';
import 'services/error_bag_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ErrorBagService.instance.init();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const SignLanguageApp());
}

/// Punto de entrada de MaxiSeñas LSP.
class SignLanguageApp extends StatefulWidget {
  const SignLanguageApp({super.key});

  @override
  State<SignLanguageApp> createState() => _SignLanguageAppState();
}

class _SignLanguageAppState extends State<SignLanguageApp> {
  bool _isDarkMode = true;

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MaxiSeñas LSP',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
            ),
        '/vocabulario': (context) => VocabularyScreen(
              isDarkMode: _isDarkMode,
              onToggleTheme: _toggleTheme,
            ),
        '/practica': (context) => const PracticeScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/repaso': (context) => const ErrorReviewScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6C63FF),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      );

  ThemeData _buildDarkTheme() => ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C63FF),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      );
}
