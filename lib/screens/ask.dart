import 'package:flutter/material.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'saved.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key, this.standalone = false});
  final bool standalone;
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _Exchange {
  _Exchange(this.question, this.topic);
  final String question;
  final AskTopic topic;
}

class _AskScreenState extends State<AskScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  final List<_Exchange> history = [];

  Future<void> _ask(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    final s = Store.instance;
    if (s.asksLeft <= 0) {
      _limitSheet();
      return;
    }
    await s.useAsk();
    setState(() => history.add(_Exchange(q, matchTopic(q))));
    ctrl.clear();
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  void _limitSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: C.emerald.withOpacity(.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: C.emerald, size: 30),
            ),
            const SizedBox(height: 14),
            Text("You've used today's free questions", textAlign: TextAlign.center, style: ui(22, weight: FontWeight.w700, spacing: -0.3)),
            const SizedBox(height: 8),
            Text('Watch a short ad to ask one more, or go Plus for unlimited questions and no ads.',
                textAlign: TextAlign.center, style: ui(15, color: C.grey, height: 1.45)),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Watch an ad for 1 question',
              onTap: () {
                // Production: AdMob rewarded ad; grant on reward callback.
                Store.instance.unlockAsk();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test build: 1 question unlocked without an ad')));
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Get Minha Plus · ₹99 a month', light: true, onTap: () => Navigator.pop(ctx)),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Come back tomorrow', style: ui(15, color: C.emerald, weight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomBar = widget.standalone ? 0.0 : MediaQuery.of(context).padding.bottom + 58;
    return Scaffold(
      backgroundColor: C.grouped,
      appBar: widget.standalone ? AppBar(backgroundColor: C.grouped, surfaceTintColor: Colors.transparent) : null,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Store.instance,
          builder: (context, _) => Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, widget.standalone ? 0 : 12, 20, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Ask', style: largeTitle()),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${Store.instance.asksLeft} left today', style: ui(13, color: C.grey)),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (history.isEmpty) ...[
                    Group(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Tell us what's on your heart", style: ui(17, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Describe what you are going through. Minha answers with verses from the Quran and their references, never with rulings.',
                            style: ui(14.5, color: C.grey, height: 1.45)),
                      ]),
                    ),
                  ],
                  for (final e in history) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, left: 60),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                        decoration: const BoxDecoration(
                          color: C.emerald,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6)),
                        ),
                        child: Text(e.question, style: ui(16, color: Colors.white, height: 1.4)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                      child: Text('Verses on ${e.topic.label.toLowerCase()}:', style: ui(15, color: const Color(0xFF3A3A3C))),
                    ),
                    for (final k in e.topic.verses.take(3)) Padding(padding: const EdgeInsets.only(bottom: 10), child: VerseCard(verseKey: k)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('Verses with their sources, not a ruling. For what is permitted, ask a scholar you trust.',
                          style: ui(12.5, color: C.grey, height: 1.45)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              color: C.grouped,
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomBar + 10 + (widget.standalone ? MediaQuery.of(context).padding.bottom : 0)),
              child: Column(children: [
                SizedBox(
                  height: 36,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final t in ['Exams', 'Grief', 'Patience', 'Parents', 'Marriage', 'Money', 'Anger', 'Gratitude'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(t, style: ui(14)),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.black.withOpacity(.06)),
                          shape: const StadiumBorder(),
                          onPressed: () => _ask('I need guidance about ${t.toLowerCase()}'),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "What's on your heart?",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Colors.black.withOpacity(.12))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Colors.black.withOpacity(.12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(backgroundColor: C.emerald, fixedSize: const Size(46, 46)),
                    onPressed: () => _ask(ctrl.text),
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
