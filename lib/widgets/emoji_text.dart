import 'package:flutter/material.dart';

/// Bundled font that covers glyphs Roboto doesn't — flag emoji, place and
/// reservation category icons, and other pictographs used throughout the
/// app. Ships with the app, so resolving text through it never needs a
/// network fetch, online or offline.
///
/// Deliberately declared only here, and only applied through [EmojiText] —
/// never globally through [ThemeData.textTheme]. Declaring it on every
/// text style at once (via `textTheme.apply(fontFamilyFallback: ...)`) was
/// the trigger for a Safari/CanvasKit text-shaping bug that corrupted
/// letter-spacing on plain text too, not just the emoji it was meant for.
/// Scoping it to the handful of widgets that actually render emoji avoids
/// that blast radius entirely.
const emojiFallbackFonts = ['NotoColorEmoji'];

/// A [Text] that resolves through [emojiFallbackFonts]. Use this instead
/// of [Text] anywhere the string may contain an emoji or flag glyph —
/// country flags, place/reservation category icons, a trip's hero emoji.
class EmojiText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const EmojiText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle();
    return Text(
      data,
      style: base.copyWith(
        fontFamilyFallback: [...?base.fontFamilyFallback, ...emojiFallbackFonts],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
