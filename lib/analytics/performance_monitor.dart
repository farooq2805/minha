import 'dart:async';
import 'analytics_service.dart';
import 'event_types.dart';

class PerformanceMonitor {
  PerformanceMonitor._();
  static final PerformanceMonitor instance = PerformanceMonitor._();

  final Map<String, Stopwatch> _activeTraces = {};
  DateTime? appStartTime;

  void markAppStarted() {
    appStartTime = DateTime.now();
  }

  void startTrace(String traceName) {
    _activeTraces[traceName] = Stopwatch()..start();
  }

  int stopTrace(String traceName, {Map<String, dynamic>? extraProperties}) {
    final watch = _activeTraces.remove(traceName);
    if (watch == null) return 0;
    watch.stop();
    final durationMs = watch.elapsedMilliseconds;

    final props = {
      'trace_name': traceName,
      'duration_ms': durationMs,
      ...?extraProperties,
    };

    AnalyticsService.instance.track(
      AnalyticsEvents.performanceTrace,
      properties: props,
    );

    return durationMs;
  }

  /// Convenience wrapper to time asynchronous operations (e.g. network or DB)
  Future<T> traceAsync<T>(String traceName, Future<T> Function() action, {Map<String, dynamic>? extraProperties}) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      AnalyticsService.instance.track(
        AnalyticsEvents.performanceTrace,
        properties: {
          'trace_name': traceName,
          'duration_ms': sw.elapsedMilliseconds,
          'status': 'success',
          ...?extraProperties,
        },
      );
      return result;
    } catch (e) {
      sw.stop();
      AnalyticsService.instance.track(
        AnalyticsEvents.performanceTrace,
        properties: {
          'trace_name': traceName,
          'duration_ms': sw.elapsedMilliseconds,
          'status': 'error',
          'error_type': e.runtimeType.toString(),
          ...?extraProperties,
        },
      );
      rethrow;
    }
  }
}
