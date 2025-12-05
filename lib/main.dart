import 'package:flutter/material.dart';
import 'screens/root_screen.dart';

void main() {
  runApp(const NovelShelfApp());
}

class NovelShelfApp extends StatelessWidget {
  const NovelShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F1115);
    const surface = Color(0xFF151922);
    const accent = Color(0xFF5B7CFF);

    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NovelShelf',
      theme: theme,
      home: const RootScreen(),
    );
  }
}
