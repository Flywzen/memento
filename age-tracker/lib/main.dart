import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgeTrackerApp());
}

class AgeTrackerApp extends StatelessWidget {
  const AgeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Age Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC8B89A),
          surface: Color(0xFF111111),
          onPrimary: Color(0xFF0A0A0A),
          onSurface: Color(0xFFE8E4DC),
        ),
        textTheme: GoogleFonts.syneTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFE8E4DC),
          displayColor: const Color(0xFFE8E4DC),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
