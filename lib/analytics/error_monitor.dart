import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'event_types.dart';

class ErrorReport {
  ErrorReport({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.stackTrace,
    required this.isFatal,
    this.context,
  });

  final String id;
  final String timestamp;
  final String message;
  final String stackTrace;
  final bool isFatal;
  final String? context;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'message': message,
        'stack_trace': stackTrace,
        'is_fatal': isFatal,
        'context': context,
      };

  factory ErrorReport.fromJson(Map<String, dynamic> j) => ErrorReport(
        id: j['id'] as String,
        timestamp: j['timestamp'] as String,
        message: j['message'] as String,
        stackTrace: j['stack_trace'] as String,
        isFatal: j['is_fatal'] as bool? ?? false,
        context: j['context'] as String?,
      );
}

class ErrorMonitor {
  ErrorMonitor._();
  static final ErrorMonitor instance = ErrorMonitor._();

  late SharedPreferences _prefs;
  final List<ErrorReport> _reports = [];

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _loadReports();

    // Hook into Flutter global error handling
    FlutterError.onError = (details) {
      logException(
        details.exception,
        stack: details.stack,
        context: details.context?.toString(),
        isFatal: false,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logException(error, stack: stack, isFatal: true);
      return true;
    };
  }

  void _loadReports() {
    final raw = _prefs.getStringList('error_reports') ?? [];
    _reports.clear();
    for (final item in raw) {
      try {
        _reports.add(ErrorReport.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  void logException(
    Object exception, {
    StackTrace? stack,
    String? context,
    bool isFatal = false,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final sanitizedStack = _sanitizeStackTrace(stack?.toString() ?? '');
    final report = ErrorReport(
      id: '${DateTime.now().millisecondsSinceEpoch}_${exception.hashCode}',
      timestamp: now,
      message: exception.toString(),
      stackTrace: sanitizedStack,
      isFatal: isFatal,
      context: context,
    );

    _reports.add(report);
    if (_reports.length > 100) {
      _reports.removeRange(0, _reports.length - 100);
    }

    final raw = _reports.map((r) => jsonEncode(r.toJson())).toList();
    _prefs.setStringList('error_reports', raw);

    // Track via Central Analytics Service
    AnalyticsService.instance.track(
      isFatal ? AnalyticsEvents.appFatalCrash : AnalyticsEvents.appException,
      properties: {
        'error_type': exception.runtimeType.toString(),
        'error_message': _truncate(exception.toString(), 150),
        'is_fatal': isFatal,
        if (context != null) 'context': _truncate(context, 100),
      },
    );
  }

  double get crashFreeUsersPercentage {
    final totalSessions = _prefs.getInt('total_session_count') ?? 1;
    final fatalCrashes = _reports.where((r) => r.isFatal).length;
    if (totalSessions == 0) return 100.0;
    final rate = ((totalSessions - fatalCrashes) / totalSessions) * 100.0;
    return rate.clamp(0.0, 100.0);
  }

  List<ErrorReport> get recentReports => List.unmodifiable(_reports);

  String _sanitizeStackTrace(String raw) {
    // Strips out local username paths to avoid PII in stack traces
    return raw.replaceAll(RegExp(r'/Users/[^/]+/'), '/Users/developer/');
  }

  String _truncate(String val, int maxLen) {
    if (val.length <= maxLen) return val;
    return val.substring(0, maxLen);
  }
}
