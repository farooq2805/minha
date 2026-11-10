import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'quran.dart';

void showMeaning(BuildContext context, Verse v) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.grouped,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    builder: (_) => FractionallySizedBox(heightFactor: .9, child: MeaningSheet(verse: v)),
  );
}

class MeaningSheet extends StatefulWidget {
  const MeaningSheet({super.key, required this.verse});
  final Verse verse;
  @override
  State<MeaningSheet> createState() => _MeaningSheetState();
}

class _MeaningSheetState extends State<MeaningSheet> {
  late final Future<List<WordMeaning>> words = QuranApi.instance.words(widget.verse.key);

  @override
  Widget build(BuildContext context) {
    final v = widget.verse;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v.surahName} ${v.key}', style: ui(28, weight: FontWeight.w700, spacing: -0.5)),
            const SizedBox(height: 8),
            Text(v.translation, style: serif(19, color: const Color(0xFF3A3A3C), height: 1.45)),
          ]),
        ),
        const SizedBox(height: 22),
        Padding(padding: const EdgeInsets.only(left: 20, bottom: 6), child: Text('Word by word', style: ui(13, color: C.grey))),
        FutureBuilder<List<WordMeaning>>(
          future: words,
          builder: (context, snap) {
            if (snap.hasError) {
              return Group(child: Text('Word-by-word meaning is unavailable right now.', style: ui(15, color: C.grey)));
            }
            if (!snap.hasData) return const Group(child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            final list = snap.data!;
            return Group(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < list.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(border: i == list.length - 1 ? null : const Border(bottom: BorderSide(color: C.hair, width: .5))),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(list[i].meaning, style: ui(17)),
                          if (list[i].transliteration.isNotEmpty) Text(list[i].transliteration, style: ui(13, color: C.grey)),
                        ]),
                      ),
                      Text(list[i].arabic, textDirection: TextDirection.rtl, style: arabic(26, color: i == 0 ? C.emerald : C.ink, height: 1.6)),
                    ]),
                  ),
              ]),
            );
          },
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: PrimaryButton(label: 'Listen', light: true, onTap: () => Store.instance.play(v))),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: 'Open surah',
              onTap: () {
                final n = int.parse(v.key.split(':').first);
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(MaterialPageRoute(builder: (_) => ReaderScreen(surah: n, title: v.surahName, highlight: v.key)));
              },
            ),
          ),
        ]),
      ],
    );
  }
}
