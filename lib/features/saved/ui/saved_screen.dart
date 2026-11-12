import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minha/core/router/routes.dart';

import 'package:minha/features/quran/data/quran_api.dart';
import 'package:minha/core/services/store.dart';
import 'package:minha/core/theme/theme.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.grouped,
      appBar: AppBar(backgroundColor: C.grouped, surfaceTintColor: Colors.transparent),
      body: ListenableBuilder(
        listenable: Store.instance,
        builder: (context, _) {
          final keys = Store.instance.saved;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 16), child: Text('Saved', style: largeTitle())),
              if (keys.isEmpty)
                Group(child: Text('Tap Save on any verse in your feed and it will appear here.', style: ui(15, color: C.grey, height: 1.45))),
              for (final k in keys) Padding(padding: const EdgeInsets.only(bottom: 12), child: VerseCard(verseKey: k)),
            ],
          );
        },
      ),
    );
  }
}

/// Light verse card used in Saved and Ask.
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.verseKey});
  final String verseKey;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Verse>(
      future: QuranApi.instance.verse(verseKey),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Group(
            child: snap.hasError
                ? Text("Couldn't load $verseKey", style: ui(15, color: C.grey))
                : const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final v = snap.data!;
        return Group(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(v.arabic, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: arabic(25, height: 1.85)),
            const SizedBox(height: 8),
            Text(v.translation, style: serif(18, color: const Color(0xFF2C2C2E))),
            const SizedBox(height: 10),
            Row(children: [
              Text(v.reference, style: ui(13, weight: FontWeight.w600, color: C.emerald)),
              const Spacer(),
              IconButton(
                tooltip: 'Listen',
                visualDensity: VisualDensity.compact,
                onPressed: () => Store.instance.play(v),
                icon: const Icon(Icons.play_circle_outline_rounded, color: C.emerald),
              ),
              IconButton(
                tooltip: 'Share',
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push(Routes.share, extra: v),
                icon: const Icon(Icons.ios_share_rounded, color: C.emerald),
              ),
            ]),
          ]),
        );
      },
    );
  }
}
