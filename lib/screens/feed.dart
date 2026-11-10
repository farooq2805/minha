import 'dart:ui';

import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'ask.dart';
import 'meaning.dart';
import 'ramadan.dart';
import 'saved.dart';
import 'settings.dart';
import 'share.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  PageController controller = PageController();
  String? _mood;
  String? _translation;
  late List<String> keys;

  void _buildKeys() {
    final s = Store.instance;
    keys = [...moods[s.mood] ?? moods.values.first, ...generalVerses];
    _mood = s.mood;
    _translation = s.translation;
    controller = PageController();
  }

  @override
  void initState() {
    super.initState();
    _buildKeys();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (context, _) {
        final s = Store.instance;
        if (s.mood != _mood || s.translation != _translation) {
          _buildKeys();
        }
        return Stack(
          children: [
            const Positioned.fill(child: MeshBackground()),
            PageView.builder(
              key: ValueKey('$_mood|$_translation'),
              controller: controller,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, i) {
                if ((i + 1) % 9 == 0) return const SponsoredCard();
                final vi = i - ((i + 1) ~/ 9);
                return VersePage(verseKey: keys[vi % keys.length], moodLine: vi < (moods[_mood] ?? []).length ? 'Because you felt ${_mood!.toLowerCase()} today' : null);
              },
            ),
            const _TopBar(),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            _Glass(
              padding: const EdgeInsets.all(3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _seg('For You', true, () {}),
                _seg('Ramadan', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanScreen()))),
                _seg('Saved', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScreen()))),
              ]),
            ),
            const Spacer(),
            if (s.showName && s.name.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _Glass(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text('Salam, ${s.name}', style: ui(12.5, color: Colors.white, weight: FontWeight.w600)),
                ),
              ),
            _Glass(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFF3BF0A0)),
                const SizedBox(width: 4),
                Text('${s.streak}', style: ui(14, color: Colors.white, weight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => showSettings(context),
              child: const _Glass(padding: EdgeInsets.all(8), child: Icon(Icons.tune_rounded, size: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(color: on ? Colors.white.withOpacity(.92) : Colors.transparent, borderRadius: BorderRadius.circular(99)),
          child: Text(label, style: ui(14, weight: on ? FontWeight.w600 : FontWeight.w500, color: on ? C.night : Colors.white.withOpacity(.85))),
        ),
      );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, required this.padding, this.radius = 99});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withOpacity(.18), width: .5),
            ),
            child: child,
          ),
        ),
      );
}

class VersePage extends StatefulWidget {
  const VersePage({super.key, required this.verseKey, this.moodLine});
  final String verseKey;
  final String? moodLine;
  @override
  State<VersePage> createState() => _VersePageState();
}

class _VersePageState extends State<VersePage> {
  late Future<Verse> future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    future = QuranApi.instance.verse(widget.verseKey).then((v) {
      Store.instance.bump('read');
      return v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 58;
    return FutureBuilder<Verse>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("Couldn't load this verse. Check your connection.", style: ui(15, color: Colors.white70)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => setState(_load), child: Text('Try again', style: ui(15, color: C.glow, weight: FontWeight.w600))),
            ]),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2));
        final v = snap.data!;
        return ListenableBuilder(
          listenable: Store.instance,
          builder: (context, _) {
            final s = Store.instance;
            final playing = s.playingKey == v.key;
            return Padding(
              padding: EdgeInsets.fromLTRB(28, 110, 28, bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text('${v.surahName} · ${v.key}', style: ui(13, weight: FontWeight.w600, color: Colors.white60)),
                          const SizedBox(height: 18),
                          Text(v.arabic, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: arabic(v.arabic.length > 220 ? 26 : 36, color: Colors.white)),
                          const SizedBox(height: 18),
                          Text(v.translation, style: serif(v.translation.length > 260 ? 18 : 22, color: Colors.white.withOpacity(.9), height: 1.45)),
                          if (widget.moodLine != null) ...[
                            const SizedBox(height: 16),
                            Text(widget.moodLine!, style: ui(13, color: Colors.white54)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Action(icon: s.isSaved(v.key) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: s.isSaved(v.key) ? 'Saved' : 'Save', onTap: () => s.toggleSave(v.key)),
                      _Action(icon: Icons.ios_share_rounded, label: 'Share', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShareScreen(verse: v)))),
                      _Action(icon: Icons.translate_rounded, label: 'Meaning', onTap: () => showMeaning(context, v)),
                      _Action(icon: Icons.chat_bubble_outline_rounded, label: 'Ask', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AskScreen(standalone: true)))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Glass(
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Mishary Alafasy', style: ui(13, color: Colors.white, weight: FontWeight.w600)),
                          Text(playing ? 'Playing ${v.key}' : 'Tap to listen', style: ui(12, color: Colors.white60)),
                        ]),
                      ),
                      IconButton(
                        tooltip: playing ? 'Pause' : 'Play recitation',
                        onPressed: () => s.play(v),
                        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        _Glass(padding: const EdgeInsets.all(16), child: Icon(icon, color: Colors.white, size: 22)),
        const SizedBox(height: 6),
        Text(label, style: ui(12, color: Colors.white.withOpacity(.92), weight: FontWeight.w500)),
      ]),
    );
  }
}

/// Native sponsored card shown after every 8th verse.
/// Test build: house card. Production: AdMob native ad, halal-filtered.
class SponsoredCard extends StatelessWidget {
  const SponsoredCard({super.key});
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 58;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 120, 20, bottom + 40),
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(99)),
            child: Text('Sponsored', style: ui(12, color: Colors.white, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF6E3C6), Color(0xFFE9C08C), Color(0xFFC98E52)]),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(18),
                  child: Text('Ad slot (test build)', style: ui(13, weight: FontWeight.w600, color: const Color(0xB33C1E0A))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Halal-checked advertiser', style: ui(12, color: C.grey, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Your brand here during Ramadan', style: ui(20, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('One sponsored card after every 8 verses. Never on a verse.', style: ui(14, color: C.grey, height: 1.45)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Text('Swipe up for the next verse', style: ui(13, color: Colors.white60)),
      ]),
    );
  }
}
