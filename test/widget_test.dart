// Named widget_test.dart on purpose: `flutter create` in CI only writes its
// sample test when this file is missing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:minha/core/router/app_router.dart';
import 'package:minha/core/router/routes.dart';
import 'package:minha/core/router/tab_shell.dart';
import 'package:minha/core/theme/theme.dart';

void main() {
  group('onboarding redirect', () {
    test('sends new users to welcome', () {
      expect(onboardingRedirect(onboarded: false, location: Routes.today), Routes.welcome);
      expect(onboardingRedirect(onboarded: false, location: '/reader/1'), Routes.welcome);
    });
    test('leaves new users on welcome', () {
      expect(onboardingRedirect(onboarded: false, location: Routes.welcome), isNull);
    });
    test('moves onboarded users off welcome', () {
      expect(onboardingRedirect(onboarded: true, location: Routes.welcome), Routes.today);
    });
    test('lets onboarded users go anywhere else', () {
      expect(onboardingRedirect(onboarded: true, location: Routes.quran), isNull);
    });
  });

  group('routes', () {
    test('reader encodes title and highlight', () {
      final uri = Uri.parse(Routes.reader(2, title: 'Al-Baqara', highlight: '2:286'));
      expect(uri.path, '/reader/2');
      expect(uri.queryParameters['title'], 'Al-Baqara');
      expect(uri.queryParameters['highlight'], '2:286');
    });
    test('reader without highlight has no highlight parameter', () {
      final uri = Uri.parse(Routes.reader(1, title: 'Al-Faatiha'));
      expect(uri.queryParameters.containsKey('highlight'), isFalse);
    });
    test('iftar and verse links', () {
      expect(Routes.iftar(), '/ramadan/iftar');
      expect(Routes.iftar(qadr: true), '/ramadan/iftar?qadr=1');
      expect(Routes.verse('2:286'), '/verse/2:286');
    });
  });

  group('design system', () {
    test('theme uses bundled Inter Tight and the grouped background', () {
      final t = buildTheme();
      expect(t.textTheme.bodyMedium?.fontFamily, Fonts.ui);
      expect(t.scaffoldBackgroundColor, C.grouped);
    });
    test('text styles map to the right families', () {
      expect(ui(14).fontFamily, Fonts.ui);
      expect(serif(14).fontFamily, Fonts.serif);
      expect(serif(14, italic: true).fontStyle, FontStyle.italic);
      expect(arabic(24).fontFamily, Fonts.quran);
      expect(naskh(24).fontFamily, Fonts.naskh);
      expect(largeTitle().fontSize, 34);
      expect(largeTitle().fontWeight, FontWeight.w700);
    });

    testWidgets('PrimaryButton taps, is labelled and meets the touch target', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: Center(child: PrimaryButton(label: 'Continue', onTap: () => taps++))),
      ));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.bySemanticsLabel('Continue'), findsOneWidget);
      expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(Space.touch));
      semantics.dispose();
    });

    testWidgets('MinhaMark and Wordmark render', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Column(children: const [MinhaMark(size: 64, color: C.emerald), Wordmark()])),
      ));
      expect(find.byType(MinhaMark), findsOneWidget);
      expect(find.text('minha'), findsOneWidget);
    });
  });

  testWidgets('tab bar shows four tabs and reports taps', (tester) async {
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(bottomNavigationBar: TabBarBlur(index: 0, dark: true, onTap: (i) => tapped = i)),
    ));
    for (final label in ['Today', 'Quran', 'Ask', 'Journey']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Journey'));
    expect(tapped, 3);
  });
}
