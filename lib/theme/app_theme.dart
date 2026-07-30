import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const seedColor = Color(0xFF2E7D6B);

  // No letterSpacing overrides here: Roboto's own metrics already read as
  // natural, native-feeling type at every weight below, so tracking is left
  // at Flutter's default (0) unless a specific piece of UI has a real
  // reason to deviate (e.g. an all-caps eyebrow label, which keeps its own
  // explicit letterSpacing where it's used).
  static const _textTheme = TextTheme(
    titleLarge: TextStyle(fontWeight: FontWeight.w800),
    titleMedium: TextStyle(fontWeight: FontWeight.w700),
    titleSmall: TextStyle(fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(height: 1.4),
    bodySmall: TextStyle(height: 1.35),
  );

  /// Bundled font that covers glyphs Roboto doesn't — flag emoji and trip
  /// icons. Ships with the app, so resolving text through it never needs a
  /// network fetch, online or offline. (Plain symbol glyphs like ★ are
  /// covered separately — see web/index.html and web/fallback_fonts/.)
  static const _emojiFallbackFamilies = ['NotoColorEmoji'];

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

  static ThemeData get light {
    final base = ThemeData(
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
    // Applied to the theme's fully-resolved TextTheme (after Flutter has
    // merged _textTheme onto its own Material defaults) rather than to
    // _textTheme directly, so every text style gets the fallback — not
    // just the handful of styles _textTheme happens to override.
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: _emojiFallbackFamilies),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
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
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamilyFallback: _emojiFallbackFamilies),
    );
  }
}
