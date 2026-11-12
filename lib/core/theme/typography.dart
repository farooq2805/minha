import 'package:flutter/painting.dart';

import 'colors.dart';

/// Font families bundled in assets/fonts and declared in pubspec.yaml.
/// Nothing is fetched at runtime.
abstract final class Fonts {
  static const ui = 'InterTight';
  static const serif = 'Newsreader';

  /// Quran text only.
  static const quran = 'AmiriQuran';

  /// Duas and all other Arabic.
  static const naskh = 'NotoNaskhArabic';
}

/// Interface text (Inter Tight).
TextStyle ui(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double? height, double spacing = 0}) =>
    TextStyle(fontFamily: Fonts.ui, fontSize: size, color: color, fontWeight: weight, height: height, letterSpacing: spacing);

/// Translations and the wordmark (Newsreader).
TextStyle serif(double size,
        {Color color = C.ink, double height = 1.4, FontWeight weight = FontWeight.w400, bool italic = false}) =>
    TextStyle(
      fontFamily: Fonts.serif,
      fontSize: size,
      color: color,
      height: height,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );

/// Quran text (Amiri Quran). Use only for verses of the Quran.
TextStyle arabic(double size, {Color color = C.ink, double height = 1.9}) =>
    TextStyle(fontFamily: Fonts.quran, fontSize: size, color: color, height: height);

/// Duas and other Arabic text (Noto Naskh Arabic).
TextStyle naskh(double size, {Color color = C.ink, double height = 1.8, FontWeight weight = FontWeight.w400}) =>
    TextStyle(fontFamily: Fonts.naskh, fontSize: size, color: color, height: height, fontWeight: weight);

/// 34/700 large title, Apple style.
TextStyle largeTitle({Color color = C.ink}) => ui(34, color: color, weight: FontWeight.w700, spacing: -0.75, height: 1.1);
