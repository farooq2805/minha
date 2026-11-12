import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:minha/core/analytics/analytics_service.dart';
import 'package:minha/core/services/store.dart';

/// On-device state (profile, progress, prayer settings). Loaded in main()
/// before the app starts. Screens move from `Store.instance` to
/// `ref.watch(storeProvider)` as each feature is rebuilt.
final storeProvider = ChangeNotifierProvider<Store>((ref) => Store.instance);

final analyticsProvider = Provider<AnalyticsService>((ref) => AnalyticsService.instance);
