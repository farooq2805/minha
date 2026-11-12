import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:minha/app.dart';
import 'package:minha/core/analytics/analytics_service.dart';
import 'package:minha/core/services/store.dart';
import 'package:minha/core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Show errors on screen instead of a blank grey box, so testers can screenshot them.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFFFF4F4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Something went wrong:\n${details.exceptionAsString()}',
              style: ui(12, color: const Color(0xFF8B1A1A))),
        ),
      );
  _registerFontLicenses();
  await Store.instance.load();
  await AnalyticsService.instance.init();
  runApp(const ProviderScope(child: MinhaApp()));
}

/// Shows the bundled fonts' SIL Open Font Licences on the system licences page.
void _registerFontLicenses() {
  const fonts = {
    'Inter Tight': 'intertight',
    'Newsreader': 'newsreader',
    'Amiri Quran': 'amiriquran',
    'Noto Naskh Arabic': 'notonaskharabic',
  };
  LicenseRegistry.addLicense(() async* {
    for (final e in fonts.entries) {
      final text = await rootBundle.loadString('assets/fonts/licenses/${e.value}-OFL.txt');
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}
