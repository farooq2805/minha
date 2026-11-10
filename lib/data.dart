import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Test-build data source: api.alquran.cloud (text, translation) and
/// cdn.islamic.network (Alafasy audio). Production switches to the licensed
/// Quran Foundation API.
class Verse {
  Verse({
    required this.key,
    required this.number,
    required this.arabic,
    required this.translation,
    required this.surahName,
    required this.surahEnglish,
  });

  final String key; // "2:286"
  final int number; // global ayah number, used for audio
  final String arabic;
  final String translation;
  final String surahName; // transliterated, e.g. Al-Baqara
  final String surahEnglish; // e.g. The Cow

  String get reference => '$surahName $key';
  String get audioUrl => 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3';

  Map<String, dynamic> toJson() => {
        'key': key,
        'number': number,
        'arabic': arabic,
        'translation': translation,
        'surahName': surahName,
        'surahEnglish': surahEnglish,
      };

  factory Verse.fromJson(Map<String, dynamic> j) => Verse(
        key: j['key'] as String,
        number: j['number'] as int,
        arabic: j['arabic'] as String,
        translation: j['translation'] as String,
        surahName: j['surahName'] as String,
        surahEnglish: j['surahEnglish'] as String,
      );
}

class Translation {
  const Translation(this.id, this.label);
  final String id;
  final String label;
}

const translations = [
  Translation('en.sahih', 'English (Saheeh International)'),
  Translation('hi.hindi', 'Hindi (Suhel Farooq Khan)'),
  Translation('ur.jalandhry', 'Urdu (Jalandhry)'),
  Translation('id.indonesian', 'Indonesian'),
];

const _bismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

String stripBismillah(String text, String key) {
  // alquran.cloud prefixes verse 1 of most surahs with the Bismillah.
  if (key.endsWith(':1') && key != '1:1' && text.startsWith(_bismillah)) {
    return text.substring(_bismillah.length).trim();
  }
  return text;
}

class QuranApi {
  QuranApi._();
  static final QuranApi instance = QuranApi._();

  final Map<String, Verse> _memory = {};
  String translation = 'en.sahih';

  Future<Verse> verse(String key) async {
    final cacheKey = '$translation|$key';
    final hit = _memory[cacheKey];
    if (hit != null) return hit;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('v|$cacheKey');
    if (stored != null) {
      final v = Verse.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      _memory[cacheKey] = v;
      return v;
    }
    final uri = Uri.parse('https://api.alquran.cloud/v1/ayah/$key/editions/quran-uthmani,$translation');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Could not load verse $key');
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>;
    final ar = data[0] as Map<String, dynamic>;
    final tr = data[1] as Map<String, dynamic>;
    final surah = ar['surah'] as Map<String, dynamic>;
    final v = Verse(
      key: key,
      number: ar['number'] as int,
      arabic: stripBismillah(ar['text'] as String, key),
      translation: tr['text'] as String,
      surahName: surah['englishName'] as String,
      surahEnglish: surah['englishNameTranslation'] as String,
    );
    _memory[cacheKey] = v;
    await prefs.setString('v|$cacheKey', jsonEncode(v.toJson()));
    return v;
  }

  Future<List<SurahInfo>> surahs() async {
    final prefs = await SharedPreferences.getInstance();
    var body = prefs.getString('surahs');
    if (body == null) {
      final res = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah')).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('Could not load surahs');
      body = res.body;
      await prefs.setString('surahs', body);
    }
    final list = (jsonDecode(body) as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return SurahInfo(
        number: m['number'] as int,
        arabicName: m['name'] as String,
        name: m['englishName'] as String,
        meaning: m['englishNameTranslation'] as String,
        ayahs: m['numberOfAyahs'] as int,
        revelation: m['revelationType'] as String,
      );
    }).toList();
  }

  Future<List<Verse>> surah(int n) async {
    final uri = Uri.parse('https://api.alquran.cloud/v1/surah/$n/editions/quran-uthmani,$translation');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Could not load surah $n');
    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>;
    final ar = data[0] as Map<String, dynamic>;
    final tr = data[1] as Map<String, dynamic>;
    final arAyahs = ar['ayahs'] as List<dynamic>;
    final trAyahs = tr['ayahs'] as List<dynamic>;
    final out = <Verse>[];
    for (var i = 0; i < arAyahs.length; i++) {
      final a = arAyahs[i] as Map<String, dynamic>;
      final t = trAyahs[i] as Map<String, dynamic>;
      final key = '$n:${a['numberInSurah']}';
      out.add(Verse(
        key: key,
        number: a['number'] as int,
        arabic: stripBismillah(a['text'] as String, key),
        translation: t['text'] as String,
        surahName: ar['englishName'] as String,
        surahEnglish: ar['englishNameTranslation'] as String,
      ));
    }
    return out;
  }

  /// Word-by-word meaning from the public Quran.com v4 API.
  Future<List<WordMeaning>> words(String key) async {
    final uri = Uri.parse('https://api.quran.com/api/v4/verses/by_key/$key?words=true&language=en&word_fields=text_uthmani');
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('No word data');
    final verse = (jsonDecode(res.body) as Map<String, dynamic>)['verse'] as Map<String, dynamic>;
    final words = verse['words'] as List<dynamic>;
    return words
        .map((w) => w as Map<String, dynamic>)
        .where((w) => w['char_type_name'] == 'word')
        .map((w) => WordMeaning(
              arabic: (w['text_uthmani'] ?? w['text'] ?? '') as String,
              meaning: ((w['translation'] as Map<String, dynamic>?)?['text'] ?? '') as String,
              transliteration: ((w['transliteration'] as Map<String, dynamic>?)?['text'] ?? '') as String,
            ))
        .toList();
  }
}

class SurahInfo {
  SurahInfo({required this.number, required this.arabicName, required this.name, required this.meaning, required this.ayahs, required this.revelation});
  final int number;
  final String arabicName;
  final String name;
  final String meaning;
  final int ayahs;
  final String revelation;
}

class WordMeaning {
  WordMeaning({required this.arabic, required this.meaning, required this.transliteration});
  final String arabic;
  final String meaning;
  final String transliteration;
}

/// Moods offered at onboarding, each with a curated verse list.
const moods = <String, List<String>>{
  'Anxious': ['94:5', '13:28', '2:286', '65:3', '9:40', '3:139', '2:153', '20:46', '3:173'],
  'Grateful': ['14:7', '55:13', '2:152', '16:18', '31:12', '93:11', '27:40'],
  'Grieving': ['2:156', '3:185', '12:86', '94:6', '93:3', '2:155', '57:23'],
  'Hopeful': ['39:53', '12:87', '65:2', '93:4', '2:186', '94:5', '3:139'],
  'Feeling lost': ['1:6', '93:7', '2:186', '29:69', '6:162', '2:2', '20:2'],
  'Tired': ['94:7', '2:286', '29:69', '3:200', '94:8', '2:45', '13:28'],
  'Seeking forgiveness': ['39:53', '4:110', '3:135', '66:8', '7:23', '25:70', '11:90'],
  'At peace': ['13:28', '89:27', '10:62', '36:58', '56:26', '89:28', '48:4'],
};

/// Verses mixed into every feed after the mood list.
const generalVerses = ['2:255', '112:1', '59:22', '24:35', '3:26', '57:4', '50:16', '55:26', '67:2', '103:3'];

class AskTopic {
  const AskTopic(this.label, this.words, this.verses);
  final String label;
  final List<String> words;
  final List<String> verses;
}

const askTopics = [
  AskTopic('Studies and exams', ['exam', 'study', 'studies', 'test', 'result', 'college', 'school', 'focus', 'marks'], ['20:114', '94:5', '65:3', '2:286']),
  AskTopic('Anxiety and worry', ['anxious', 'anxiety', 'worry', 'worried', 'stress', 'stressed', 'fear', 'scared', 'panic', 'overthink'], ['13:28', '2:286', '9:40', '3:173']),
  AskTopic('Grief and loss', ['grief', 'died', 'death', 'passed', 'loss', 'lost my', 'funeral', 'miss him', 'miss her'], ['2:156', '3:185', '2:155', '93:3']),
  AskTopic('Parents', ['parent', 'parents', 'mother', 'father', 'mom', 'dad', 'ammi', 'abbu'], ['17:23', '17:24', '31:14', '46:15']),
  AskTopic('Marriage', ['marriage', 'married', 'spouse', 'husband', 'wife', 'nikah', 'rishta'], ['30:21', '25:74', '4:19', '2:187']),
  AskTopic('Money and work', ['money', 'job', 'work', 'rizq', 'debt', 'salary', 'business', 'loan', 'career', 'interview'], ['65:3', '11:6', '65:2', '2:268']),
  AskTopic('Anger', ['anger', 'angry', 'rage', 'fight', 'argument'], ['3:134', '41:34', '42:37', '7:199']),
  AskTopic('Loneliness', ['lonely', 'alone', 'nobody', 'isolated', 'friends'], ['2:186', '50:16', '20:46', '9:40']),
  AskTopic('Illness', ['sick', 'ill', 'illness', 'health', 'hospital', 'pain', 'disease'], ['26:80', '17:82', '21:83', '2:155']),
  AskTopic('Sin and guilt', ['sin', 'guilt', 'guilty', 'forgive', 'forgiveness', 'regret', 'shame', 'mistake'], ['39:53', '4:110', '25:70', '3:135']),
  AskTopic('Patience', ['patience', 'patient', 'sabr', 'hard', 'difficult', 'struggle', 'tough', 'waiting'], ['2:153', '3:200', '94:5', '39:10']),
  AskTopic('Gratitude', ['grateful', 'thank', 'thankful', 'blessed', 'shukr'], ['14:7', '2:152', '16:18']),
  AskTopic('Children', ['child', 'children', 'kids', 'baby', 'son', 'daughter', 'pregnant'], ['25:74', '14:40', '18:46', '3:38']),
];

const fallbackTopic = AskTopic('A verse for your heart', [], ['2:186', '94:5', '13:28']);

AskTopic matchTopic(String question) {
  final q = question.toLowerCase();
  AskTopic? best;
  var bestScore = 0;
  for (final t in askTopics) {
    var score = 0;
    for (final w in t.words) {
      if (q.contains(w)) score++;
    }
    if (score > bestScore) {
      best = t;
      bestScore = score;
    }
  }
  return best ?? fallbackTopic;
}
