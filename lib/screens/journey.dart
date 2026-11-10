import 'dart:math';

import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import 'ramadan.dart';

const ringColors = {'read': C.emerald, 'listen': Color(0xFFC4964F), 'reflect': Color(0xFF3E7CB1)};
const ringLabels = {'read': 'Read', 'listen': 'Listen', 'reflect': 'Reflect'};
const ringUnits = {'read': 'verses', 'listen': 'recitations', 'reflect': 'saves or shares'};

final ramadanStart = DateTime(2027, 2, 8); // expected, by moon sighting

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 74;
    return Scaffold(
      backgroundColor: C.grouped,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Store.instance,
          builder: (context, _) {
            final s = Store.instance;
            final now = DateTime.now();
            final days = ramadanStart.difference(DateTime(now.year, now.month, now.day)).inDays;
            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_dateLine(now), style: ui(13, color: C.grey, weight: FontWeight.w600)),
                    Text('Journey', style: largeTitle()),
                  ]),
                ),
                const SizedBox(height: 16),
                Group(
                  child: Row(children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(painter: RingsPainter([for (final r in ringColors.keys) (ringColors[r]!, s.progress(r))])),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final r in ringColors.keys)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ringLabels[r]!, style: ui(15, weight: FontWeight.w600, color: ringColors[r]!)),
                              Text('${s.count(r)}/${Store.goals[r]} ${ringUnits[r]}', style: ui(16, weight: FontWeight.w600)),
                            ]),
                          ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const RadialGradient(center: Alignment(0.8, -0.7), radius: 1.4, colors: [Color(0xFF5A4A2A), C.night]),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(days > 0 ? 'Ramadan 1448 begins in' : 'Ramadan Mubarak', style: ui(13, color: Colors.white70)),
                          Text(days > 0 ? '$days days' : 'Open Ramadan', style: ui(34, weight: FontWeight.w700, color: Colors.white, spacing: -0.6)),
                          Text('Expected 8 Feb 2027, by moon sighting', style: ui(12, color: Colors.white60)),
                        ]),
                      ),
                      const Icon(Icons.nightlight_round, color: C.gold, size: 46),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(children: [
                    Text('Juz tracker', style: ui(20, weight: FontWeight.w600)),
                    const Spacer(),
                    Text('${s.juzDone.length} of 30 · tap to mark', style: ui(13, color: C.grey)),
                  ]),
                ),
                const SizedBox(height: 8),
                Group(
                  padding: const EdgeInsets.all(12),
                  child: GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.25,
                    children: [
                      for (var j = 1; j <= 30; j++)
                        GestureDetector(
                          onTap: () => s.toggleJuz(j),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: s.juzDone.contains('$j') ? C.emerald : C.grouped,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$j', style: ui(13, weight: FontWeight.w600, color: s.juzDone.contains('$j') ? Colors.white : const Color(0xFF8E8E93))),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Group(
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_rounded, color: C.emerald),
                    const SizedBox(width: 10),
                    Text('${s.streak}-day streak', style: ui(16, weight: FontWeight.w600)),
                    const Spacer(),
                    Text('Open daily to keep it', style: ui(13, color: C.grey)),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _dateLine(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class RingsPainter extends CustomPainter {
  RingsPainter(this.rings);
  final List<(Color, double)> rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const w = 13.0;
    for (var i = 0; i < rings.length; i++) {
      final r = size.width / 2 - w / 2 - i * (w + 4);
      final rect = Rect.fromCircle(center: c, radius: r);
      final bg = Paint()
        ..color = rings[i].$1.withOpacity(.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w;
      canvas.drawCircle(c, r, bg);
      final fg = Paint()
        ..color = rings[i].$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round;
      final sweep = max(0.001, rings[i].$2) * 2 * pi;
      canvas.drawArc(rect, -pi / 2, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant RingsPainter old) => true;
}
