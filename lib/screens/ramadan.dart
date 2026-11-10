import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import 'quran.dart';

/// Test build uses Mumbai. Production: device location with permission.
const _city = 'Mumbai';
final _coords = Coordinates(19.0760, 72.8777);

PrayerTimes _times(DateTime day) {
  final params = CalculationMethod.karachi.getParameters();
  params.madhab = Madhab.hanafi;
  return PrayerTimes(_coords, DateComponents.from(day), params);
}

String fmtTime(DateTime t) {
  final l = t.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  return '$h:${l.minute.toString().padLeft(2, '0')} ${l.hour < 12 ? 'AM' : 'PM'}';
}

String fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});
  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  late Timer timer;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => now = DateTime.now()));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _times(now);
    final suhoor = t.fajr.toLocal();
    final iftar = t.maghrib.toLocal();
    final beforeIftar = now.isBefore(iftar);
    final target = beforeIftar ? iftar : _times(now.add(const Duration(days: 1))).fajr.toLocal();
    final left = target.difference(now);
    final start = DateTime(2027, 2, 8);
    final day = now.difference(start).inDays + 1;
    final inRamadan = day >= 1 && day <= 30;

    return Scaffold(
      backgroundColor: C.grouped,
      appBar: AppBar(backgroundColor: C.grouped, surfaceTintColor: Colors.transparent),
      body: ListenableBuilder(
        listenable: Store.instance,
        builder: (context, _) {
          final s = Store.instance;
          final kept = s.fasts.where((f) => f == '1').length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(inRamadan ? 'Day $day of 30 · $_city' : 'Preview · $_city', style: ui(13, color: C.grey, weight: FontWeight.w600)),
                  Text('Ramadan', style: largeTitle()),
                ]),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IftarScreen())),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const RadialGradient(center: Alignment(0.85, -0.8), radius: 1.5, colors: [Color(0xFF6B5630), C.night]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(beforeIftar ? 'Iftar in' : 'Suhoor ends in', style: ui(13, color: Colors.white70)),
                          Text(fmtDuration(left),
                              style: ui(44, weight: FontWeight.w700, color: Colors.white, spacing: -1.2).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                        ]),
                      ),
                      const Icon(Icons.nightlight_round, color: C.gold, size: 44),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _timeBox('Suhoor ends', fmtTime(suhoor))),
                      const SizedBox(width: 10),
                      Expanded(child: _timeBox('Iftar (Maghrib)', fmtTime(iftar))),
                    ]),
                    const SizedBox(height: 12),
                    Text('Open the iftar dua', style: ui(13, color: C.gold, weight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Group(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Fasts kept', style: ui(15, weight: FontWeight.w600)),
                    const Spacer(),
                    Text('$kept of 30 · tap a day', style: ui(13, color: C.grey)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    for (var i = 0; i < 30; i++)
                      GestureDetector(
                        onTap: () => s.toggleFast(i),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: s.fasts[i] == '1' ? C.emerald : C.grouped, shape: BoxShape.circle),
                          child: Text('${i + 1}', style: ui(12, weight: FontWeight.w600, color: s.fasts[i] == '1' ? Colors.white : C.grey)),
                        ),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _tile(Icons.nightlight_outlined, 'Duas for fasting', 'Iftar and Laylat al-Qadr', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IftarScreen()))),
                  _tile(Icons.menu_book_outlined, 'Khatam plan', '20 pages a day for 30 days', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()))),
                  _tile(Icons.auto_awesome_outlined, 'Last 10 nights', 'Qadr dua and night reminders', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IftarScreen(startOnQadr: true)))),
                  _tile(Icons.volunteer_activism_outlined, 'Zakat and sadaqah', 'Calculator coming next', null),
                ],
              ),
              const SizedBox(height: 12),
              Group(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [Color(0xFFF6D7B0), Color(0xFFE3A869)]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Iftar partner · Sponsored', style: ui(11, color: const Color(0xFF8E8E93), weight: FontWeight.w600)),
                      Text('Sponsor slot (test build)', style: ui(15, weight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Text('Times: University of Islamic Sciences, Karachi method, Hanafi Asr. Always follow your local mosque announcement.',
                  style: ui(12, color: C.grey, height: 1.45)),
            ],
          );
        },
      ),
    );
  }

  Widget _timeBox(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: ui(12, color: Colors.white60)),
          Text(value, style: ui(17, color: Colors.white, weight: FontWeight.w600)),
        ]),
      );

  Widget _tile(IconData icon, String title, String sub, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: C.emerald.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: C.emerald, size: 19),
            ),
            const Spacer(),
            Text(title, style: ui(15, weight: FontWeight.w600)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ui(12.5, color: C.grey)),
          ]),
        ),
      );
}

class Dua {
  const Dua(this.tab, this.arabic, this.transliteration, this.meaning, this.source);
  final String tab;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String source;
}

const duas = [
  Dua('Iftar', 'ذَهَبَ ٱلظَّمَأُ وَٱبْتَلَّتِ ٱلْعُرُوقُ وَثَبَتَ ٱلْأَجْرُ إِنْ شَآءَ ٱللَّهُ', "Dhahaba al-ẓama'u wabtallatil-'urūqu wa thabatal-ajru in shā' Allāh",
      'The thirst is gone, the veins are moist, and the reward is certain, if Allah wills.', 'Sunan Abi Dawud 2357'),
  Dua('Allāhumma laka ṣumtu', 'ٱللَّهُمَّ لَكَ صُمْتُ وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ', "Allāhumma laka ṣumtu wa 'alā rizqika afṭartu",
      'O Allah, for You I have fasted and with Your provision I break my fast.', 'Sunan Abi Dawud 2358 (chain graded weak by many scholars)'),
  Dua('Laylat al-Qadr', 'ٱللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ ٱلْعَفْوَ فَٱعْفُ عَنِّي', "Allāhumma innaka 'afuwwun tuḥibbul-'afwa fa'fu 'annī",
      'O Allah, You are pardoning and You love to pardon, so pardon me.', "Jami' at-Tirmidhi 3513"),
];

class IftarScreen extends StatefulWidget {
  const IftarScreen({super.key, this.startOnQadr = false});
  final bool startOnQadr;
  @override
  State<IftarScreen> createState() => _IftarScreenState();
}

class _IftarScreenState extends State<IftarScreen> {
  late int i = widget.startOnQadr ? 2 : 0;

  @override
  Widget build(BuildContext context) {
    final iftar = _times(DateTime.now()).maghrib.toLocal();
    final d = duas[i];
    return Scaffold(
      backgroundColor: C.night,
      body: Stack(children: [
        const Positioned.fill(child: MeshBackground(goldTop: true)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(children: [
                IconButton(
                  tooltip: 'Close',
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(.14)),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Text('Maghrib · ${fmtTime(iftar)} · $_city', style: ui(13, color: Colors.white70)),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
              const SizedBox(height: 24),
              const Icon(Icons.nightlight_round, color: C.gold, size: 54),
              const SizedBox(height: 10),
              Text(i == 2 ? 'The last ten nights' : 'Time to break your fast', textAlign: TextAlign.center, style: serif(32, color: Colors.white, weight: FontWeight.w500, height: 1.15)),
              const SizedBox(height: 6),
              Text(i == 2 ? 'Recite often on the odd nights' : 'Say this as you open your fast', style: ui(14, color: Colors.white60)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(.2), width: .5),
                ),
                child: Column(children: [
                  Text(d.arabic, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arabic(28, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(d.transliteration, textAlign: TextAlign.center, style: ui(15, color: C.gold, height: 1.5).copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Text(d.meaning, textAlign: TextAlign.center, style: serif(18, color: Colors.white.withOpacity(.9), height: 1.45)),
                  const SizedBox(height: 10),
                  Text(d.source, textAlign: TextAlign.center, style: ui(12, color: Colors.white54)),
                ]),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                for (var k = 0; k < duas.length; k++)
                  ChoiceChip(
                    label: Text(duas[k].tab),
                    selected: k == i,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => i = k),
                    selectedColor: Colors.white.withOpacity(.92),
                    backgroundColor: Colors.white.withOpacity(.1),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: ui(13, weight: FontWeight.w600, color: k == i ? C.night : Colors.white70),
                  ),
              ]),
              const Spacer(),
              PrimaryButton(
                label: i == 2 ? 'Done' : "I've opened my fast",
                onTap: () {
                  if (i != 2) {
                    final start = DateTime(2027, 2, 8);
                    final day = DateTime.now().difference(start).inDays;
                    if (day >= 0 && day < 30 && Store.instance.fasts[day] != '1') Store.instance.toggleFast(day);
                  }
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ]),
    );
  }
}
