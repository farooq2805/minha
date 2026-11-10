import 'dart:io';
import 'dart:ui' as ui_;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'settings.dart';

class CardStyle {
  const CardStyle(this.name, this.background, this.text, this.sub, {this.gradient});
  final String name;
  final Color background;
  final Color text;
  final Color sub;
  final Gradient? gradient;
}

const cardStyles = [
  CardStyle('Dawn', C.night, Colors.white, Color(0xB3FFFFFF),
      gradient: RadialGradient(center: Alignment(-0.6, -0.7), radius: 1.3, colors: [Color(0xFF0A6B48), C.night])),
  CardStyle('Paper', Color(0xFFFBF8F1), C.ink, Color(0xFF6C6C70)),
  CardStyle('Night', Color(0xFF0B0F1A), Colors.white, Color(0xB3FFFFFF)),
  CardStyle('Rose', Color(0xFFF3D9CF), Color(0xFF3B1F18), Color(0xFF7A5148),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3D9CF), Color(0xFFE6B7A6)])),
];

enum Target { status, whatsapp, story, post }

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.verse});
  final Verse verse;
  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final cardKey = GlobalKey();
  int style = 0;
  bool post = false; // 4:5 for Instagram feed, else 9:16
  bool busy = false;

  String get link => 'https://minha.app/v/${widget.verse.key.replaceAll(':', '/')}';

  Future<void> _share(Target t) async {
    if (busy) return;
    setState(() {
      busy = true;
      post = t == Target.post;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui_.Image image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
      final bytes = await image.toByteData(format: ui_.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/minha_${widget.verse.key.replaceAll(':', '_')}_${post ? 'post' : 'story'}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      final caption = t == Target.status || t == Target.story ? null : '${widget.verse.reference} on Minha: $link';
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], text: caption);
      Store.instance.bump('reflect');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        backgroundColor: C.grouped,
        appBar: AppBar(
          backgroundColor: C.grouped,
          surfaceTintColor: Colors.transparent,
          leadingWidth: 90,
          leading: TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: ui(17, color: C.emerald))),
          centerTitle: true,
          title: Text('Share Verse', style: ui(17, weight: FontWeight.w600)),
        ),
        body: Column(children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AspectRatio(
                  aspectRatio: post ? 4 / 5 : 9 / 16,
                  child: RepaintBoundary(
                    key: cardKey,
                    child: VerseShareCard(verse: widget.verse, style: cardStyles[style], name: s.showName && s.name.isNotEmpty ? s.name : null),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 84,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < cardStyles.length; i++)
                GestureDetector(
                  onTap: () => setState(() => style = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Column(children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: cardStyles[i].background,
                          gradient: cardStyles[i].gradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: i == style ? C.emerald : Colors.black12, width: i == style ? 2.5 : .5),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(cardStyles[i].name, style: ui(12, weight: i == style ? FontWeight.w600 : FontWeight.w500, color: i == style ? C.ink : C.grey)),
                    ]),
                  ),
                ),
            ]),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _TargetButton('WhatsApp\nStatus', 'assets/share/whatsapp_status.png', const Color(0xFF1FAF5A), Icons.motion_photos_on_outlined, () => _share(Target.status)),
                _TargetButton('WhatsApp', 'assets/share/whatsapp.png', const Color(0xFF1FAF5A), Icons.chat_outlined, () => _share(Target.whatsapp)),
                _TargetButton('Instagram\nStory', 'assets/share/instagram_story.png', const Color(0xFFE1306C), Icons.amp_stories_outlined, () => _share(Target.story)),
                _TargetButton('Instagram\nPost', 'assets/share/instagram_post.png', const Color(0xFF8A3AB9), Icons.crop_portrait_rounded, () => _share(Target.post)),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: C.grouped, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  SwitchListTile(
                    dense: true,
                    title: Text('Show my name', style: ui(16)),
                    subtitle: GestureDetector(
                      onTap: () => editName(context),
                      child: Text(s.name.isEmpty ? 'Add your name' : '${s.name} · Edit', style: ui(12.5, color: C.emerald, weight: FontWeight.w600)),
                    ),
                    value: s.showName,
                    activeTrackColor: const Color(0xFF34C759),
                    onChanged: (v) async {
                      if (v && s.name.isEmpty) await editName(context);
                      await s.setShowName(v);
                    },
                  ),
                  const Divider(height: .5, thickness: .5, indent: 16, color: C.hair),
                  ListTile(
                    dense: true,
                    title: Text('Copy verse text', style: ui(16)),
                    trailing: const Icon(Icons.copy_rounded, size: 20),
                    onTap: () {
                      final v = widget.verse;
                      Clipboard.setData(ClipboardData(text: '${v.arabic}\n\n${v.translation}\n\n${v.reference}\n$link'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse copied')));
                    },
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TargetButton extends StatelessWidget {
  const _TargetButton(this.label, this.asset, this.color, this.icon, this.onTap);
  final String label;
  final String asset;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(color: color, alignment: Alignment.center, child: Icon(icon, color: Colors.white, size: 28));
    return Semantics(
      button: true,
      label: 'Share to ${label.replaceAll('\n', ' ')}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 78,
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(width: 58, height: 58, child: Image.asset(asset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: ui(11.5, height: 1.2)),
          ]),
        ),
      ),
    );
  }
}

/// The card that gets rendered to PNG.
class VerseShareCard extends StatelessWidget {
  const VerseShareCard({super.key, required this.verse, required this.style, this.name});
  final Verse verse;
  final CardStyle style;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final k = box.maxWidth / 270; // scale relative to a 270pt-wide design
      final long = verse.arabic.length > 160;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: style.background,
          gradient: style.gradient,
          borderRadius: BorderRadius.circular(20 * k),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 20))],
        ),
        padding: EdgeInsets.fromLTRB(26 * k, 24 * k, 26 * k, 20 * k),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Spacer(),
          Text(verse.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: arabic((long ? 17 : 24) * k, color: style.text, height: 1.85)),
          SizedBox(height: 12 * k),
          Text(verse.translation, maxLines: 7, overflow: TextOverflow.ellipsis, style: serif((long ? 13 : 16) * k, color: style.text, height: 1.4)),
          SizedBox(height: 12 * k),
          Text(verse.reference, style: ui(10.5 * k, color: style.sub, weight: FontWeight.w600)),
          const Spacer(),
          Row(children: [
            if (name != null) ...[
              Container(
                width: 22 * k,
                height: 22 * k,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [C.gold, Color(0xFFB8863F)])),
                child: Text(_initials(name!), style: ui(9 * k, color: C.night, weight: FontWeight.w700)),
              ),
              SizedBox(width: 7 * k),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Shared by', style: ui(8.5 * k, color: style.sub, height: 1.1)),
                  Text(name!, maxLines: 1, overflow: TextOverflow.ellipsis, style: ui(10.5 * k, color: style.text, weight: FontWeight.w600, height: 1.15)),
                ]),
              ),
            ] else
              const Spacer(),
            MinhaMark(size: 15 * k, color: style.text, star: C.gold),
            SizedBox(width: 4 * k),
            Text('minha', style: serif(12 * k, color: style.text, weight: FontWeight.w500, height: 1)),
          ]),
        ]),
      );
    });
  }

  static String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
