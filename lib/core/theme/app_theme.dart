import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// App-wide theme. Material is only the engine underneath: every component is
/// restyled toward an iOS-like grouped look so nothing reads as default Material.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.emerald,
    primary: C.emerald,
    surface: Colors.white,
    onSurface: C.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: Fonts.ui,
    scaffoldBackgroundColor: C.grouped,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.black.withValues(alpha: .04),
    // Native iOS-style swipe-back transitions on every platform.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: C.grouped,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: C.ink,
      titleTextStyle: ui(17, weight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(color: C.hair, thickness: .5, space: .5),
    listTileTheme: ListTileThemeData(
      iconColor: C.emerald,
      titleTextStyle: ui(16),
      subtitleTextStyle: ui(13, color: C.grey),
      minVerticalPadding: 10,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.switchOn : C.hair),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.emerald,
        textStyle: ui(16, weight: FontWeight.w600),
        minimumSize: const Size(Space.touch, Space.touch),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.card)),
      titleTextStyle: ui(17, weight: FontWeight.w600),
      contentTextStyle: ui(14, color: C.grey, height: 1.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.grouped,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: C.hair,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      contentTextStyle: ui(14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.card)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: C.grouped,
      selectedColor: C.emerald,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: ui(14, weight: FontWeight.w500),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: ui(16, color: C.tertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.card), borderSide: BorderSide.none),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.emerald),
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: C.emerald),
  );
}
