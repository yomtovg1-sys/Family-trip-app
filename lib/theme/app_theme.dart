import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const seedColor = Color(0xFF2E7D6B);

  static const _textTheme = TextTheme(
    titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleSmall: TextStyle(fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(letterSpacing: 0.1, height: 1.4),
    bodySmall: TextStyle(letterSpacing: 0.1, height: 1.35),
  );

  /// Subtle, native-feeling page transitions on every platform — a soft
  /// horizontal slide (iOS-style) instead of the platform-default fade/zoom,
  /// so navigating between screens feels consistent everywhere the app runs.
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        pageTransitionsTheme: _pageTransitionsTheme,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        pageTransitionsTheme: _pageTransitionsTheme,
      );
}
