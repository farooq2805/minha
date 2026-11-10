import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import 'quran.dart';
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
            final times = s.getPrayerTimes(now);

            return ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_dateLine(now), style: ui(13, color: C.grey, weight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('Journey', style: largeTitle()),
                        const Spacer(),
                        if (s.name.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: C.emerald.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                            child: Text(s.name, style: ui(13, weight: FontWeight.w600, color: C.deep)),
                          ),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // --- DAILY NAMAZ TRACKER ---
                _NamazTrackerCard(times: times),
                const SizedBox(height: 14),

                // --- QURAN READING PROGRESS ---
                _QuranProgressCard(),
                const SizedBox(height: 14),

                // --- ACTIVITY RINGS ---
                Group(
                  child: Row(children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(painter: RingsPainter([for (final r in ringColors.keys) (ringColors[r]!, s.progress(r))])),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final r in ringColors.keys)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ringLabels[r]!, style: ui(14, weight: FontWeight.w600, color: ringColors[r]!)),
                              Text('${s.count(r)}/${Store.goals[r]} ${ringUnits[r]}', style: ui(15, weight: FontWeight.w600)),
                            ]),
                          ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // --- RAMADAN CARD ---
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
                          Text(days > 0 ? '$days days' : 'Open Ramadan', style: ui(32, weight: FontWeight.w700, color: Colors.white, spacing: -0.6)),
                          Text('Expected 8 Feb 2027, by moon sighting', style: ui(12, color: Colors.white60)),
                        ]),
                      ),
                      const Icon(Icons.nightlight_round, color: C.gold, size: 44),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // --- JUZ TRACKER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(children: [
                    Text('Juz tracker', style: ui(19, weight: FontWeight.w600)),
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

                // --- STREAK FOOTER ---
                Group(
                  child: Row(children: [
                    const Icon(Icons.local_fire_department_rounded, color: C.emerald),
                    const SizedBox(width: 10),
                    Text('${s.streak}-day app streak', style: ui(16, weight: FontWeight.w600)),
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

class _NamazTrackerCard extends StatelessWidget {
  const _NamazTrackerCard({required this.times});
  final PrayerTimes times;

  String _fmt(DateTime t) {
    final l = t.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    return '$h:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    final completed = s.completedPrayersCount();

    final prayers = [
      ('Fajr', times.fajr, 'fajr'),
      ('Dhuhr', times.dhuhr, 'dhuhr'),
      ('Asr', times.asr, 'asr'),
      ('Maghrib', times.maghrib, 'maghrib'),
      ('Isha', times.isha, 'isha'),
    ];

    return Group(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: C.emerald.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.access_time_rounded, color: C.emerald, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily Namaz Tracker', style: ui(17, weight: FontWeight.w700)),
            Text('${s.cityName} · $completed/5 offered today', style: ui(12.5, color: C.grey)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFF3DC), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE28B00), size: 16),
              const SizedBox(width: 3),
              Text('${s.namazStreak}d streak', style: ui(12, weight: FontWeight.w700, color: const Color(0xFF9A5500))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final p in prayers)
              _prayerPill(
                context,
                name: p.$1,
                time: _fmt(p.$2),
                done: s.isPrayerDone(p.$3),
                onTap: () => s.togglePrayer(p.$3),
              ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => showMosqueAdjustDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune_rounded, size: 14, color: C.emerald),
                const SizedBox(width: 5),
                Text('Adjust mosque times & calculation method', style: ui(12.5, color: C.emerald, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _prayerPill(
    BuildContext context, {
    required String name,
    required String time,
    required bool done,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: done ? C.emerald : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: done ? C.emerald : const Color(0xFFE5E5EA), width: 1),
          boxShadow: done ? [BoxShadow(color: C.emerald.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Column(children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? Colors.white : const Color(0xFF8E8E93), size: 18),
          const SizedBox(height: 5),
          Text(name, style: ui(13, weight: FontWeight.w700, color: done ? Colors.white : C.ink)),
          const SizedBox(height: 2),
          Text(time, maxLines: 1, overflow: TextOverflow.ellipsis, style: ui(9.5, color: done ? Colors.white.withOpacity(.9) : C.grey, weight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _QuranProgressCard extends StatelessWidget {
  const _QuranProgressCard();

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    final hasLastRead = s.lastReadSurah != null;

    return Group(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF3E7CB1).withOpacity(.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF3E7CB1), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quran Progress', style: ui(17, weight: FontWeight.w700)),
              Text('${s.totalVersesRead} of 6,236 verses read · ${(s.quranOverallProgress * 100).toStringAsFixed(1)}%',
                  style: ui(12.5, color: C.grey)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: s.quranOverallProgress > 0 ? s.quranOverallProgress : 0.005,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E5EA),
            valueColor: const AlwaysStoppedAnimation(C.emerald),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.grouped, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hasLastRead ? 'Last read' : 'Start reading', style: ui(11, color: C.grey, weight: FontWeight.w600)),
                Text(hasLastRead ? '${s.lastReadSurahName} (Ayah ${s.lastReadAyah})' : 'Surah Al-Fatihah (1:1)',
                    style: ui(15, weight: FontWeight.w700)),
              ]),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: C.emerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                final surahNum = s.lastReadSurah ?? 1;
                final surahName = s.lastReadSurahName ?? 'Al-Fatihah';
                final highlightKey = hasLastRead ? '${s.lastReadSurah}:${s.lastReadAyah}' : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(surah: surahNum, title: surahName, highlight: highlightKey),
                  ),
                );
              },
              child: Text(hasLastRead ? 'Resume' : 'Read', style: ui(13, weight: FontWeight.w600, color: Colors.white)),
            ),
          ]),
        ),
      ]),
    );
  }
}

void showMosqueAdjustDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const FractionallySizedBox(heightFactor: .82, child: _MosqueAdjustSheet()),
  );
}

class _MosqueAdjustSheet extends StatefulWidget {
  const _MosqueAdjustSheet();
  @override
  State<_MosqueAdjustSheet> createState() => _MosqueAdjustSheetState();
}

class _MosqueAdjustSheetState extends State<_MosqueAdjustSheet> {
  late int f = Store.instance.offsetFajr;
  late int d = Store.instance.offsetDhuhr;
  late int a = Store.instance.offsetAsr;
  late int m = Store.instance.offsetMaghrib;
  late int i = Store.instance.offsetIsha;
  late String method = Store.instance.calcMethod;
  late String madhab = Store.instance.madhab;
  late String city = Store.instance.cityName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Mosque Adjustments', style: ui(18, weight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () async {
              await Store.instance.setPrayerOffsets(fajr: f, dhuhr: d, asr: a, maghrib: m, isha: i);
              await Store.instance.setCalculationMethod(method);
              await Store.instance.setMadhab(madhab);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Done', style: ui(16, color: C.emerald, weight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('City / Location', style: ui(13, color: C.grey, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cityPresets)
              ChoiceChip(
                label: Text(c.name),
                selected: city == c.name,
                showCheckmark: false,
                onSelected: (val) {
                  if (val) {
                    setState(() => city = c.name);
                    Store.instance.setLocation(c.name, c.lat, c.lng);
                  }
                },
                selectedColor: C.emerald,
                backgroundColor: C.grouped,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: ui(13, color: city == c.name ? Colors.white : C.ink, weight: FontWeight.w600),
              ),
          ]),
          const SizedBox(height: 18),
          Text('Calculation Method', style: ui(13, color: C.grey, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: method,
            decoration: InputDecoration(
              filled: true,
              fillColor: C.grouped,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(value: 'karachi', child: Text('Karachi (Univ. Islamic Sciences - India/PK)')),
              DropdownMenuItem(value: 'mwl', child: Text('Muslim World League (MWL)')),
              DropdownMenuItem(value: 'isna', child: Text('ISNA (North America)')),
              DropdownMenuItem(value: 'egypt', child: Text('Egyptian General Authority')),
              DropdownMenuItem(value: 'makkah', child: Text('Umm al-Qura (Makkah)')),
              DropdownMenuItem(value: 'dubai', child: Text('Dubai (UAE)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => method = v);
            },
          ),
          const SizedBox(height: 16),
          Text('Asr School (Madhab)', style: ui(13, color: C.grey, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Hanafi (Standard in India/PK)')),
                selected: madhab == 'hanafi',
                showCheckmark: false,
                onSelected: (_) => setState(() => madhab = 'hanafi'),
                selectedColor: C.emerald,
                labelStyle: ui(13, color: madhab == 'hanafi' ? Colors.white : C.ink, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Shafi / Standard')),
                selected: madhab == 'shafi',
                showCheckmark: false,
                onSelected: (_) => setState(() => madhab = 'shafi'),
                selectedColor: C.emerald,
                labelStyle: ui(13, color: madhab == 'shafi' ? Colors.white : C.ink, weight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Text('Minute Adjustments (Match Mosque Adhan)', style: ui(13, color: C.grey, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _stepperRow('Fajr', f, (v) => setState(() => f = v)),
          _stepperRow('Dhuhr', d, (v) => setState(() => d = v)),
          _stepperRow('Asr', a, (v) => setState(() => a = v)),
          _stepperRow('Maghrib', m, (v) => setState(() => m = v)),
          _stepperRow('Isha', i, (v) => setState(() => i = v)),
        ],
      ),
    );
  }

  Widget _stepperRow(String label, int val, ValueChanged<int> onChg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: C.grouped, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Text(label, style: ui(15, weight: FontWeight.w600)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline_rounded, color: C.emerald),
          onPressed: val > -30 ? () => onChg(val - 1) : null,
        ),
        SizedBox(
          width: 55,
          child: Text(
            val == 0 ? '0 min' : (val > 0 ? '+$val min' : '$val min'),
            textAlign: TextAlign.center,
            style: ui(14, weight: FontWeight.w700, color: val != 0 ? C.emerald : C.ink),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: C.emerald),
          onPressed: val < 30 ? () => onChg(val + 1) : null,
        ),
      ]),
    );
  }
}

class RingsPainter extends CustomPainter {
  RingsPainter(this.rings);
  final List<(Color, double)> rings;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const w = 12.0;
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
