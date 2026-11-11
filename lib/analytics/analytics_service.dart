import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_cost_tracker.dart';
import 'business_intelligence.dart';
import 'error_monitor.dart';
import 'event_types.dart';

/// Centralized, enterprise-grade Analytics Service for Minha.
/// Enforces standard event schemas, offline queuing, retry logic,
/// privacy-preservation, and GA4 / BigQuery streaming compatibility.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  late SharedPreferences _prefs;
  bool _initialized = false;
  bool isDebugMode = kDebugMode;
  bool isTrackingEnabled = true;

  String _sessionId = '';
  String _anonymousInstallId = '';
  int _sessionStartTime = 0;
  Timer? _sessionHeartbeat;
  Timer? _flushTimer;

  final List<AnalyticsEvent> _eventQueue = [];
  final List<AnalyticsEvent> _recentEventsBuffer = [];

  // Configuration for GA4 / BigQuery ingestion endpoint
  String ga4MeasurementId = '';
  String ga4ApiSecret = '';
  String customIngestEndpoint = '';

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Load or generate anonymous install id (pseudonymous UUID)
    _anonymousInstallId = _prefs.getString('analytics_install_id') ?? '';
    if (_anonymousInstallId.isEmpty) {
      _anonymousInstallId = _generateUuid();
      await _prefs.setString('analytics_install_id', _anonymousInstallId);
    }

    isTrackingEnabled = _prefs.getBool('analytics_enabled') ?? true;
    isDebugMode = _prefs.getBool('analytics_debug') ?? kDebugMode;
    ga4MeasurementId = _prefs.getString('ga4_measurement_id') ?? '';
    ga4ApiSecret = _prefs.getString('ga4_api_secret') ?? '';
    customIngestEndpoint = _prefs.getString('custom_ingest_endpoint') ?? '';

    // Initialize sub-monitors
    await AiCostTracker.instance.init(_prefs);
    await ErrorMonitor.instance.init(_prefs);
    await BusinessIntelligence.instance.init(_prefs);

    _loadOfflineQueue();
    _startNewSession();

    // Periodic flush timer for offline queue (every 60 seconds)
    _flushTimer = Timer.periodic(const Duration(seconds: 60), (_) => flushQueue());

    _initialized = true;
  }

  void _startNewSession() {
    _sessionId = _generateUuid();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;

    final sessionCount = (_prefs.getInt('total_session_count') ?? 0) + 1;
    _prefs.setInt('total_session_count', sessionCount);

    track(AnalyticsEvents.sessionStart, properties: {
      'session_number': sessionCount,
    });

    // Session heartbeat to measure duration accurately
    _sessionHeartbeat?.cancel();
    _sessionHeartbeat = Timer.periodic(const Duration(minutes: 5), (_) {
      final durationMinutes = (DateTime.now().millisecondsSinceEpoch - _sessionStartTime) ~/ 60000;
      track(AnalyticsEvents.userEngagement, properties: {
        'engagement_time_msec': durationMinutes * 60000,
      });
    });
  }

  void _loadOfflineQueue() {
    final rawList = _prefs.getStringList('analytics_offline_queue') ?? [];
    for (final raw in rawList) {
      try {
        _eventQueue.add(AnalyticsEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  Future<void> _saveOfflineQueue() async {
    final rawList = _eventQueue.take(500).map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('analytics_offline_queue', rawList);
  }

  /// Central Event Tracking Method.
  /// Validates parameters, scrubs PII, records locally, and enqueues for delivery.
  void track(String eventName, {Map<String, dynamic>? properties}) {
    if (!isTrackingEnabled) return;

    final sanitizedProps = _sanitizeProperties(properties ?? {});
    final event = AnalyticsEvent(
      eventName: eventName,
      eventId: _generateUuid(),
      eventTime: DateTime.now().toUtc().toIso8601String(),
      appVersion: '0.1.0+1',
      platform: _resolvePlatform(),
      environment: isDebugMode ? 'debug' : 'production',
      sessionId: _sessionId,
      anonymousInstallId: _anonymousInstallId,
      properties: sanitizedProps,
    );

    _eventQueue.add(event);
    _recentEventsBuffer.add(event);
    if (_recentEventsBuffer.length > 100) {
      _recentEventsBuffer.removeAt(0);
    }

    _saveOfflineQueue();
    notifyListeners();

    if (isDebugMode) {
      debugPrint('[Analytics] Tracked: $eventName -> ${jsonEncode(sanitizedProps)}');
    }

    // Auto-flush when queue exceeds 10 items
    if (_eventQueue.length >= 10) {
      flushQueue();
    }
  }

  /// Flushes queued events to the cloud analytics / BigQuery ingestion gateway.
  Future<void> flushQueue() async {
    if (_eventQueue.isEmpty || !isTrackingEnabled) return;

    final batch = List<AnalyticsEvent>.from(_eventQueue);

    // If custom ingest endpoint or GA4 measurement protocol configured
    if (customIngestEndpoint.isNotEmpty) {
      try {
        final payload = jsonEncode({
          'events': batch.map((e) => e.toJson()).toList(),
          'client_id': _anonymousInstallId,
        });

        final res = await http
            .post(
              Uri.parse(customIngestEndpoint),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          _eventQueue.removeWhere((e) => batch.contains(e));
          await _saveOfflineQueue();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('[Analytics] Flush error: $e');
      }
    }

    // Keep queue trimmed so device storage remains lightweight
    if (_eventQueue.length > 200) {
      _eventQueue.removeRange(0, _eventQueue.length - 200);
      await _saveOfflineQueue();
    }
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    isTrackingEnabled = enabled;
    await _prefs.setBool('analytics_enabled', enabled);
    notifyListeners();
  }

  Future<void> setDebugMode(bool debug) async {
    isDebugMode = debug;
    await _prefs.setBool('analytics_debug', debug);
    notifyListeners();
  }

  Future<void> setGa4Credentials({required String measurementId, required String apiSecret}) async {
    ga4MeasurementId = measurementId.trim();
    ga4ApiSecret = apiSecret.trim();
    await _prefs.setString('ga4_measurement_id', ga4MeasurementId);
    await _prefs.setString('ga4_api_secret', ga4ApiSecret);
    notifyListeners();
  }

  Future<void> setCustomEndpoint(String endpoint) async {
    customIngestEndpoint = endpoint.trim();
    await _prefs.setString('custom_ingest_endpoint', customIngestEndpoint);
    notifyListeners();
  }

  /// Strictly filters out personal identifiable information (PII)
  Map<String, dynamic> _sanitizeProperties(Map<String, dynamic> raw) {
    final sanitized = <String, dynamic>{};
    final piiKeys = {'email', 'password', 'phone', 'token', 'secret', 'auth', 'address', 'card'};

    raw.forEach((k, v) {
      final lowerKey = k.toLowerCase();
      final isPii = piiKeys.any((p) => lowerKey.contains(p));
      if (!isPii) {
        if (v is String && _containsPotentialPii(v)) {
          sanitized[k] = '[REDACTED_PII]';
        } else {
          sanitized[k] = v;
        }
      }
    });

    return sanitized;
  }

  bool _containsPotentialPii(String text) {
    // Check for email pattern
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b').hasMatch(text)) {
      return true;
    }
    // Check for phone number pattern (> 9 digits)
    if (RegExp(r'\b\+?[0-9]{10,13}\b').hasMatch(text)) {
      return true;
    }
    return false;
  }

  String _resolvePlatform() {
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWeb) return 'web';
    } catch (_) {}
    return 'unknown';
  }

  String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now ^ 0x5DEECE66D).abs().toRadixString(16);
    return 'ev_${now.toRadixString(16)}_$rand';
  }

  String get anonymousInstallId => _anonymousInstallId;
  String get sessionId => _sessionId;
  int get queuedEventCount => _eventQueue.length;
  List<AnalyticsEvent> get recentEvents => List.unmodifiable(_recentEventsBuffer);

  @override
  void dispose() {
    _sessionHeartbeat?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }
}
