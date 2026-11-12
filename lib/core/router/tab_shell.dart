import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:minha/core/analytics/analytics_service.dart';
import 'package:minha/core/analytics/event_types.dart';
import 'package:minha/core/theme/theme.dart';

/// Scaffold around the four tabs with the translucent blurred tab bar.
/// The Today tab sits on the dark mesh, so the bar and status bar go dark there.
class TabShell extends StatelessWidget {
  const TabShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _screenNames = ['today_feed', 'quran_reader', 'ask_minha', 'journey_dashboard'];

  void _onTap(int i) {
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
    AnalyticsService.instance.track(AnalyticsEvents.screenView, properties: {'screen_name': _screenNames[i]});
  }

  @override
  Widget build(BuildContext context) {
    final dark = shell.currentIndex == 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: TabBarBlur(index: shell.currentIndex, dark: dark, onTap: _onTap),
      ),
    );
  }
}

class TabBarBlur extends StatelessWidget {
  const TabBarBlur({super.key, required this.index, required this.dark, required this.onTap});
  final int index;
  final bool dark;
  final ValueChanged<int> onTap;

  /// Height of the bar above the bottom safe area. Screens pad their content by this.
  static const height = 58.0;

  static const items = [
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Today'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Quran'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Ask'),
    (Icons.donut_large_rounded, Icons.donut_large_rounded, 'Journey'),
  ];

  @override
  Widget build(BuildContext context) {
    final on = dark ? Colors.white : C.emerald;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xB814181A) : const Color(0xE6F9F9F9),
            border: Border(top: BorderSide(color: dark ? Colors.white12 : Colors.black12, width: .5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: items[i].$3,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(i == index ? items[i].$2 : items[i].$1, size: 25, color: i == index ? on : C.tertiary),
                              const SizedBox(height: 3),
                              Text(
                                items[i].$3,
                                maxLines: 1,
                                textScaler: TextScaler.noScaling,
                                style: ui(10.5, weight: FontWeight.w600, color: i == index ? on : C.tertiary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
