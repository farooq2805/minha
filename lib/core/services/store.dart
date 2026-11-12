import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:minha/features/quran/data/quran_api.dart';

String today([DateTime? dt]) {
  final n = dt ?? DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

class CityPreset {
  const CityPreset(this.name, this.lat, this.lng, this.country);
  final String name;
  final double lat;
  final double lng;
  final String country;
}

const cityPresets = [
  CityPreset('Mumbai', 19.0760, 72.8777, 'India'),
  CityPreset('Delhi', 28.7041, 77.1025, 'India'),
  CityPreset('Hyderabad', 17.3850, 78.4867, 'India'),
  CityPreset('Bengaluru', 12.9716, 77.5946, 'India'),
  CityPreset('Kolkata', 22.5726, 88.3639, 'India'),
  CityPreset('Chennai', 13.0827, 80.2707, 'India'),
  CityPreset('Lucknow', 26.8467, 80.9462, 'India'),
  CityPreset('Ahmedabad', 23.0225, 72.5714, 'India'),
  CityPreset('Dubai', 25.2048, 55.2708, 'UAE'),
  CityPreset('Mecca', 21.3891, 39.8579, 'Saudi Arabia'),
  CityPreset('Medina', 24.5247, 39.5692, 'Saudi Arabia'),
  CityPreset('London', 51.5074, -0.1278, 'UK'),
  CityPreset('New York', 40.7128, -74.0060, 'USA'),
];

/// App state kept on the device.
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

  // --- Profile & Preferences ---
  bool get onboarded => _p.getBool('onboarded') ?? false;
  String get mood => _p.getString('mood') ?? 'Anxious';
  String get name => _p.getString('name') ?? 'Farooq';
  String get email => _p.getString('email') ?? 'farooq2805@gmail.com';
  bool get isLoggedIn => _p.getBool('isLoggedIn') ?? true;
  String get authProvider => _p.getString('authProvider') ?? 'Google';
  bool get showName => _p.getBool('showName') ?? true;
  String get translation => _p.getString('translation') ?? 'en.sahih';
  List<String> get saved => _p.getStringList('saved') ?? [];
  int get streak => _p.getInt('streak') ?? 1;
  List<String> get fasts => _p.getStringList('fasts') ?? List.filled(30, '0');
  List<String> get juzDone => _p.getStringList('juzDone') ?? [];

  // --- Prayer Times & Location Engine ---
  String get cityName => _p.getString('cityName') ?? 'Mumbai';
  double get latitude => _p.getDouble('latitude') ?? 19.0760;
  double get longitude => _p.getDouble('longitude') ?? 72.8777;
  String get calcMethod => _p.getString('calcMethod') ?? 'karachi';
  String get madhab => _p.getString('madhab') ?? 'hanafi';

  // Minute offsets to match local mosque adhan
  int get offsetFajr => _p.getInt('offsetFajr') ?? 0;
  int get offsetDhuhr => _p.getInt('offsetDhuhr') ?? 0;
  int get offsetAsr => _p.getInt('offsetAsr') ?? 0;
  int get offsetMaghrib => _p.getInt('offsetMaghrib') ?? 0;
  int get offsetIsha => _p.getInt('offsetIsha') ?? 0;

  PrayerTimes getPrayerTimes([DateTime? date]) {
    final d = date ?? DateTime.now();
    final coords = Coordinates(latitude, longitude);

    CalculationParameters params;
    switch (calcMethod) {
      case 'mwl':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'isna':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'egypt':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'makkah':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'dubai':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'karachi':
      default:
        params = CalculationMethod.karachi.getParameters();
        break;
    }

    params.madhab = madhab == 'shafi' ? Madhab.shafi : Madhab.hanafi;
    params.adjustments.fajr = offsetFajr;
    params.adjustments.dhuhr = offsetDhuhr;
    params.adjustments.asr = offsetAsr;
    params.adjustments.maghrib = offsetMaghrib;
    params.adjustments.isha = offsetIsha;

    return PrayerTimes(coords, DateComponents.from(d), params);
  }

  Future<void> setLocation(String city, double lat, double lng) async {
    await _p.setString('cityName', city);
    await _p.setDouble('latitude', lat);
    await _p.setDouble('longitude', lng);
    notifyListeners();
  }

  Future<void> setCalculationMethod(String method) async {
    await _p.setString('calcMethod', method);
    notifyListeners();
  }

  Future<void> setMadhab(String m) async {
    await _p.setString('madhab', m);
    notifyListeners();
  }

  Future<void> setPrayerOffsets({int? fajr, int? dhuhr, int? asr, int? maghrib, int? isha}) async {
    if (fajr != null) await _p.setInt('offsetFajr', fajr);
    if (dhuhr != null) await _p.setInt('offsetDhuhr', dhuhr);
    if (asr != null) await _p.setInt('offsetAsr', asr);
    if (maghrib != null) await _p.setInt('offsetMaghrib', maghrib);
    if (isha != null) await _p.setInt('offsetIsha', isha);
    notifyListeners();
  }

  // --- Daily Namaz Tracker ---
  static const prayersList = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  bool isPrayerDone(String prayer, [DateTime? date]) {
    final dayKey = today(date);
    final done = _p.getStringList('namaz|$dayKey') ?? [];
    return done.contains(prayer.toLowerCase());
  }

  Future<void> togglePrayer(String prayer, [DateTime? date]) async {
    final dayKey = today(date);
    final pKey = prayer.toLowerCase();
    final list = List<String>.from(_p.getStringList('namaz|$dayKey') ?? []);
    if (list.contains(pKey)) {
      list.remove(pKey);
    } else {
      list.add(pKey);
    }
    await _p.setStringList('namaz|$dayKey', list);
    _recalcNamazStreak();
    notifyListeners();
  }

  int completedPrayersCount([DateTime? date]) {
    final dayKey = today(date);
    final done = _p.getStringList('namaz|$dayKey') ?? [];
    return done.length;
  }

  int get namazStreak => _p.getInt('namazStreak') ?? 1;

  void _recalcNamazStreak() {
    int streakCount = 0;
    var d = DateTime.now();
    while (true) {
      final key = today(d);
      final done = _p.getStringList('namaz|$key') ?? [];
      if (done.isNotEmpty) {
        streakCount++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _p.setInt('namazStreak', streakCount > 0 ? streakCount : 1);
  }

  // --- Quran Reading Progress Tracking ---
  int? get lastReadSurah => _p.getInt('lastReadSurah');
  String? get lastReadSurahName => _p.getString('lastReadSurahName');
  int? get lastReadAyah => _p.getInt('lastReadAyah');
  String? get lastReadDate => _p.getString('lastReadDate');

  List<String> get readAyahKeys => _p.getStringList('readAyahKeys') ?? [];
  int get totalVersesRead => readAyahKeys.length;
  double get quranOverallProgress => (totalVersesRead / 6236.0).clamp(0.0, 1.0);

  Future<void> setLastRead(int surah, String surahName, int ayah) async {
    await _p.setInt('lastReadSurah', surah);
    await _p.setString('lastReadSurahName', surahName);
    await _p.setInt('lastReadAyah', ayah);
    await _p.setString('lastReadDate', today());
    markAyahRead('$surah:$ayah');
    notifyListeners();
  }

  Future<void> markAyahRead(String key) async {
    final list = readAyahKeys;
    if (!list.contains(key)) {
      list.add(key);
      await _p.setStringList('readAyahKeys', list);
      bump('read');
      notifyListeners();
    }
  }

  // --- AI Companion & Gemini ---
  String get geminiApiKey => _p.getString('geminiApiKey') ?? '';
  Future<void> setGeminiApiKey(String key) async {
    await _p.setString('geminiApiKey', key.trim());
    notifyListeners();
  }

  // --- Onboarding & Account ---
  Future<void> finishOnboarding(String m, [String? userName]) async {
    await _p.setString('mood', m);
    if (userName != null && userName.trim().isNotEmpty) {
      await _p.setString('name', userName.trim());
    }
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

  Future<void> setUserProfile({required String name, String? email, String? provider}) async {
    await _p.setString('name', name.trim());
    if (email != null) await _p.setString('email', email.trim());
    if (provider != null) await _p.setString('authProvider', provider);
    await _p.setBool('isLoggedIn', true);
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

  // Daily rings: read (verses seen/read), listen (recitations played), reflect (saves and shares).
  static const goals = {'read': 10, 'listen': 5, 'reflect': 3};
  int count(String ring) => _p.getInt('$ring|${today()}') ?? 0;
  double progress(String ring) => (count(ring) / goals[ring]!).clamp(0.0, 1.0);

  void bump(String ring) {
    _p.setInt('$ring|${today()}', count(ring) + 1);
    notifyListeners();
  }

  // Ask: questions limit
  int get asksUsed => _p.getInt('asks|${today()}') ?? 0;
  int get asksBonus => _p.getInt('askBonus|${today()}') ?? 0;
  int get asksLeft => (5 + asksBonus - asksUsed).clamp(0, 99);

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
    final yesterday = today(y);
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
