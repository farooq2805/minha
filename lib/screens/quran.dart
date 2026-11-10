import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'meaning.dart';
import 'share.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<SurahInfo>> future = QuranApi.instance.surahs();
  String query = '';

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 70;
    return Scaffold(
      backgroundColor: C.grouped,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<SurahInfo>>(
          future: future,
          builder: (context, snap) {
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Quran', style: largeTitle()),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => query = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search surah by name or number',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0x1F767680),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ]),
                ),
              ),
              if (snap.hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Text("Couldn't load the surah list. Check your connection.", style: ui(15, color: C.grey)),
                      TextButton(onPressed: () => setState(() {
                        future = QuranApi.instance.surahs();
                      }), child: const Text('Try again')),
                    ]),
                  ),
                )
              else if (!snap.hasData)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                  sliver: SliverToBoxAdapter(
                    child: Group(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        for (final s in snap.data!.where((s) => query.isEmpty || s.name.toLowerCase().contains(query) || s.meaning.toLowerCase().contains(query) || '${s.number}' == query))
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(surah: s.number, title: s.name))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hair, width: .5))),
                              child: Row(children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: C.emerald.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text('${s.number}', style: ui(13, weight: FontWeight.w700, color: C.deep)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.name, style: ui(16, weight: FontWeight.w600)),
                                    Text('${s.meaning} · ${s.ayahs} verses', style: ui(13, color: C.grey)),
                                  ]),
                                ),
                                Text(s.arabicName, textDirection: TextDirection.rtl, style: arabic(20, height: 1.3, color: C.emerald)),
                              ]),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.surah, required this.title, this.highlight});
  final int surah;
  final String title;
  final String? highlight;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<Verse>> future = QuranApi.instance.surah(widget.surah);
  bool showTranslation = true;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Record reading activity
    Store.instance.bump('read');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title, style: ui(17, weight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: showTranslation ? 'Hide translation' : 'Show translation',
            onPressed: () => setState(() => showTranslation = !showTranslation),
            icon: Icon(showTranslation ? Icons.subtitles_rounded : Icons.subtitles_off_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Verse>>(
        future: future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text("Couldn't load this surah.", style: ui(15, color: C.grey)));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          final verses = snap.data!;
          return ListenableBuilder(
            listenable: Store.instance,
            builder: (context, _) => ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: verses.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(children: [
                      if (widget.surah != 1 && widget.surah != 9)
                        Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, style: arabic(26, color: C.deep)),
                      const Divider(color: C.hair),
                    ]),
                  );
                }
                final v = verses[i - 1];
                final on = Store.instance.playingKey == v.key || widget.highlight == v.key;
                final isLastRead = Store.instance.lastReadSurah == widget.surah && Store.instance.lastReadAyah == i;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Store.instance.markAyahRead(v.key);
                    Store.instance.play(v);
                  },
                  onLongPress: () => _verseMenu(context, v, i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLastRead
                          ? const Color(0xFFF0FDF4)
                          : on
                              ? C.emerald.withOpacity(.08)
                              : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isLastRead ? Border.all(color: C.emerald.withOpacity(.4)) : null,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (isLastRead)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.bookmark_rounded, size: 14, color: C.emerald),
                            const SizedBox(width: 4),
                            Text('Last Read Position', style: ui(11, color: C.emerald, weight: FontWeight.w600)),
                          ]),
                        ),
                      Text('${v.arabic}  ﴿${_arabicDigits(i)}﴾', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: arabic(27, height: 2.1, color: on ? C.deep : C.ink)),
                      if (showTranslation) ...[
                        const SizedBox(height: 6),
                        Text('$i. ${v.translation}', style: serif(16.5, color: const Color(0xFF3A3A3C))),
                      ],
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _verseMenu(BuildContext context, Verse v, int ayahIndex) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.bookmark_add_rounded, color: C.emerald),
            title: const Text('Mark as Last Read'),
            subtitle: Text('${widget.title} : $ayahIndex'),
            onTap: () {
              Store.instance.setLastRead(widget.surah, widget.title, ayahIndex);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Marked ${widget.title} : $ayahIndex as last read')),
              );
            },
          ),
          ListTile(leading: const Icon(Icons.translate_rounded), title: const Text('Word-by-word meaning'), onTap: () {
            Navigator.pop(ctx);
            showMeaning(context, v);
          }),
          ListTile(leading: const Icon(Icons.ios_share_rounded), title: const Text('Share as card'), onTap: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ShareScreen(verse: v)));
          }),
          ListTile(
            leading: Icon(Store.instance.isSaved(v.key) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            title: Text(Store.instance.isSaved(v.key) ? 'Remove from saved' : 'Save verse'),
            onTap: () {
              Store.instance.toggleSave(v.key);
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }

  static String _arabicDigits(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }
}
