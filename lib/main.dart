import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/ask.dart';
import 'screens/feed.dart';
import 'screens/journey.dart';
import 'screens/onboarding.dart';
import 'screens/quran.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Show errors on screen instead of a blank grey box, so testers can screenshot them.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFFFF4F4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Something went wrong:\n${details.exceptionAsString()}', style: const TextStyle(color: Color(0xFF8B1A1A), fontSize: 12)),
        ),
      );
  await Store.instance.load();
  runApp(const MinhaApp());
}

class MinhaApp extends StatelessWidget {
  const MinhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: Store.instance,
        builder: (context, _) => Store.instance.onboarded ? const Home() : const OnboardingScreen(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final dark = tab == 0;
    SystemChrome.setSystemUIOverlayStyle(dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: tab, children: const [FeedScreen(), QuranScreen(), AskScreen(), JourneyScreen()]),
      bottomNavigationBar: _TabBar(index: tab, dark: dark, onTap: (i) => setState(() => tab = i)),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.dark, required this.onTap});
  final int index;
  final bool dark;
  final ValueChanged<int> onTap;

  static const items = [
    (Icons.auto_awesome_outlined, 'Today'),
    (Icons.menu_book_outlined, 'Quran'),
    (Icons.chat_bubble_outline_rounded, 'Ask'),
    (Icons.donut_large_rounded, 'Journey'),
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
              height: 58,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: InkResponse(
                        onTap: () => onTap(i),
                        child: Semantics(
                          selected: i == index,
                          label: items[i].$2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(items[i].$1, size: 25, color: i == index ? on : const Color(0xFF8E8E93)),
                              const SizedBox(height: 3),
                              Text(items[i].$2,
                                  style: ui(10.5, weight: FontWeight.w600, color: i == index ? on : const Color(0xFF8E8E93))),
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
