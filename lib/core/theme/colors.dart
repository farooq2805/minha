import 'package:flutter/painting.dart';

/// Minha palette (docs/REBUILD_PLAN.md, section 4).
abstract final class C {
  static const emerald = Color(0xFF00875A);
  static const emeraldTop = Color(0xFF00A86B);
  static const emeraldBottom = Color(0xFF00804F);
  static const deep = Color(0xFF00573A);
  static const glow = Color(0xFF2BE08F);
  static const gold = Color(0xFFE7C48A);
  static const night = Color(0xFF04201A);
  static const ink = Color(0xFF1C1C1E);
  static const grey = Color(0xFF6C6C70);
  static const grouped = Color(0xFFF2F2F7);
  static const hair = Color(0xFFD1D1D6);

  /// Inactive tab and tertiary label grey.
  static const tertiary = Color(0xFF8E8E93);

  /// iOS-style switch "on" track.
  static const switchOn = Color(0xFF34C759);

  /// Mesh gradient accents behind the feed and iftar screen.
  static const meshGreen = Color(0xFF00C878);
  static const meshBlue = Color(0xFF274C78);
  static const meshAmber = Color(0xFFC49660);
}

/// Radii and spacing shared by every screen.
abstract final class R {
  static const card = 14.0;
  static const sheet = 16.0;
  static const button = 14.0;
}

abstract final class Space {
  static const gutter = 16.0;
  static const section = 20.0;

  /// Minimum touch target (accessibility).
  static const touch = 44.0;
}
