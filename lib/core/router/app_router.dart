import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:minha/core/providers.dart';
import 'package:minha/core/services/store.dart';
import 'package:minha/features/ask/ui/ask_screen.dart';
import 'package:minha/features/feed/ui/feed_screen.dart';
import 'package:minha/features/journey/ui/journey_screen.dart';
import 'package:minha/features/onboarding/ui/onboarding_screen.dart';
import 'package:minha/features/quran/data/quran_api.dart';
import 'package:minha/features/quran/ui/quran_screen.dart';
import 'package:minha/features/ramadan/ui/ramadan_screen.dart';
import 'package:minha/features/saved/ui/saved_screen.dart';
import 'package:minha/features/share/ui/share_screen.dart';

import 'routes.dart';
import 'tab_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Sends people who have not finished onboarding to the welcome screen, and
/// people who have away from it. Pure so it can be unit tested.
String? onboardingRedirect({required bool onboarded, required String location}) {
  final atWelcome = location == Routes.welcome;
  if (!onboarded && !atWelcome) return Routes.welcome;
  if (onboarded && atWelcome) return Routes.today;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final store = ref.read(storeProvider);
  final router = buildRouter(store);
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildRouter(Store store) => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: Routes.today,
      refreshListenable: store,
      redirect: (context, state) => onboardingRedirect(onboarded: store.onboarded, location: state.matchedLocation),
      routes: [
        GoRoute(path: Routes.welcome, builder: (_, __) => const OnboardingScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => TabShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: Routes.today, builder: (_, __) => const FeedScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.quran, builder: (_, __) => const QuranScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.ask, builder: (_, __) => const AskScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.journey, builder: (_, __) => const JourneyScreen())]),
          ],
        ),
        // Pages below cover the tab bar.
        GoRoute(
          path: '/reader/:surah',
          builder: (_, state) => ReaderScreen(
            surah: int.tryParse(state.pathParameters['surah'] ?? '') ?? 1,
            title: state.uri.queryParameters['title'] ?? '',
            highlight: state.uri.queryParameters['highlight'],
          ),
        ),
        GoRoute(
          path: '/verse/:key',
          redirect: (_, state) {
            final key = state.pathParameters['key'] ?? '';
            final surah = int.tryParse(key.split(':').first);
            if (surah == null || surah < 1 || surah > 114) return Routes.today;
            return Routes.reader(surah, title: 'Surah $surah', highlight: key);
          },
        ),
        GoRoute(path: Routes.askChat, builder: (_, __) => const AskScreen(standalone: true)),
        GoRoute(path: Routes.saved, builder: (_, __) => const SavedScreen()),
        GoRoute(
          path: Routes.ramadan,
          builder: (_, __) => const RamadanScreen(),
          routes: [
            GoRoute(
              path: 'iftar',
              builder: (_, state) => IftarScreen(startOnQadr: state.uri.queryParameters['qadr'] == '1'),
            ),
          ],
        ),
        GoRoute(
          path: Routes.share,
          redirect: (_, state) => state.extra is Verse ? null : Routes.today,
          builder: (_, state) => ShareScreen(verse: state.extra! as Verse),
        ),
      ],
    );
