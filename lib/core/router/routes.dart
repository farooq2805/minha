/// Every location in the app. Screens navigate with `context.push(Routes.x)`,
/// never by building routes by hand, so deep links (shared verses, reminders)
/// land in the same place.
abstract final class Routes {
  static const welcome = '/welcome';

  // Tabs.
  static const today = '/today';
  static const quran = '/quran';
  static const ask = '/ask';
  static const journey = '/journey';

  // Full-screen pages pushed above the tab bar.
  static const askChat = '/chat';
  static const saved = '/saved';
  static const ramadan = '/ramadan';
  static const share = '/share';

  static String reader(int surah, {required String title, String? highlight}) => Uri(
        path: '/reader/$surah',
        queryParameters: {'title': title, if (highlight != null) 'highlight': highlight},
      ).toString();

  static String iftar({bool qadr = false}) => qadr ? '/ramadan/iftar?qadr=1' : '/ramadan/iftar';

  /// Deep link to a verse in the reader, e.g. from a share card: /verse/2:286.
  static String verse(String key) => '/verse/$key';
}
