import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

String today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// App state kept on the device. Nothing leaves the phone.
class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();

  late SharedPreferences _p;
  final player = AudioPlayer();
  String? playingKey;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    QuranApi.instance.translation = translation;
    _touchStreak();
    player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        playingKey = null;
        notifyListeners();
      }
    });
  }

  bool get onboarded => _p.getBool('onboarded') ?? false;
  String get mood => _p.getString('mood') ?? 'Anxious';
  String get name => _p.getString('name') ?? '';
  bool get showName => _p.getBool('showName') ?? true;
  String get translation => _p.getString('translation') ?? 'en.sahih';
  List<String> get saved => _p.getStringList('saved') ?? [];
  int get streak => _p.getInt('streak') ?? 1;
  List<String> get fasts => _p.getStringList('fasts') ?? List.filled(30, '0');
  List<String> get juzDone => _p.getStringList('juzDone') ?? [];

  Future<void> finishOnboarding(String m) async {
    await _p.setString('mood', m);
    await _p.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> setMood(String m) async {
    await _p.setString('mood', m);
    notifyListeners();
  }

  Future<void> setName(String n) async {
    await _p.setString('name', n.trim());
    notifyListeners();
  }

  Future<void> setShowName(bool v) async {
    await _p.setBool('showName', v);
    notifyListeners();
  }

  Future<void> setTranslation(String t) async {
    await _p.setString('translation', t);
    QuranApi.instance.translation = t;
    notifyListeners();
  }

  bool isSaved(String key) => saved.contains(key);

  Future<void> toggleSave(String key) async {
    final s = saved;
    if (s.contains(key)) {
      s.remove(key);
    } else {
      s.insert(0, key);
      bump('reflect');
    }
    await _p.setStringList('saved', s);
    notifyListeners();
  }

  Future<void> toggleFast(int i) async {
    final f = fasts;
    f[i] = f[i] == '1' ? '0' : '1';
    await _p.setStringList('fasts', f);
    notifyListeners();
  }

  Future<void> toggleJuz(int j) async {
    final d = juzDone;
    final k = '$j';
    if (d.contains(k)) {
      d.remove(k);
    } else {
      d.add(k);
    }
    await _p.setStringList('juzDone', d);
    notifyListeners();
  }

  // Daily rings: read (verses seen), listen (recitations played), reflect (saves and shares).
  static const goals = {'read': 10, 'listen': 5, 'reflect': 3};
  int count(String ring) => _p.getInt('$ring|${today()}') ?? 0;
  double progress(String ring) => (count(ring) / goals[ring]!).clamp(0.0, 1.0);

  void bump(String ring) {
    _p.setInt('$ring|${today()}', count(ring) + 1);
    notifyListeners();
  }

  // Ask: three free questions a day, plus any unlocked.
  int get asksUsed => _p.getInt('asks|${today()}') ?? 0;
  int get asksBonus => _p.getInt('askBonus|${today()}') ?? 0;
  int get asksLeft => (3 + asksBonus - asksUsed).clamp(0, 99);

  Future<void> useAsk() async {
    await _p.setInt('asks|${today()}', asksUsed + 1);
    notifyListeners();
  }

  Future<void> unlockAsk() async {
    await _p.setInt('askBonus|${today()}', asksBonus + 1);
    notifyListeners();
  }

  void _touchStreak() {
    final last = _p.getString('lastOpen');
    final now = today();
    if (last == now) return;
    final y = DateTime.now().subtract(const Duration(days: 1));
    final yesterday = '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    _p.setInt('streak', last == yesterday ? streak + 1 : 1);
    _p.setString('lastOpen', now);
  }

  Future<void> play(Verse v) async {
    try {
      if (playingKey == v.key && player.playing) {
        await player.pause();
        playingKey = null;
        notifyListeners();
        return;
      }
      playingKey = v.key;
      notifyListeners();
      await player.setUrl(v.audioUrl);
      bump('listen');
      await player.play();
    } catch (_) {
      playingKey = null;
      notifyListeners();
    }
  }
}
