import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_cost_tracker.dart';
import 'analytics_service.dart';
import 'error_monitor.dart';

class BiMetricsSummary {
  BiMetricsSummary({
    required this.estimatedDau,
    required this.totalSessions,
    required this.totalEventsRecorded,
    required this.todayAiCostUsd,
    required this.monthAiCostUsd,
    required this.totalAiTokens,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
    required this.crashFreeRate,
    required this.mrrUsd,
    required this.payingUsersCount,
    required this.totalPrayersCompleted,
    required this.totalVersesRead,
  });

  final int estimatedDau;
  final int totalSessions;
  final int totalEventsRecorded;
  final double todayAiCostUsd;
  final double monthAiCostUsd;
  final int totalAiTokens;
  final int p50LatencyMs;
  final int p95LatencyMs;
  final double crashFreeRate;
  final double mrrUsd;
  final int payingUsersCount;
  final int totalPrayersCompleted;
  final int totalVersesRead;
}

class BusinessIntelligence {
  BusinessIntelligence._();
  static final BusinessIntelligence instance = BusinessIntelligence._();

  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  BiMetricsSummary getSummary() {
    final aiTracker = AiCostTracker.instance;
    final errMonitor = ErrorMonitor.instance;

    final totalSessions = _prefs?.getInt('total_session_count') ?? 1;
    final totalVerses = (_prefs?.getStringList('readAyahKeys') ?? []).length;

    // Count today's namaz completions
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final prayersDone = (_prefs?.getStringList('namaz|$todayKey') ?? []).length;

    // Subscription estimations
    final isPremium = _prefs?.getBool('is_premium') ?? false;
    final mrr = isPremium ? 1.99 : 0.0;

    return BiMetricsSummary(
      estimatedDau: 1, // Single device local view
      totalSessions: totalSessions,
      totalEventsRecorded: AnalyticsService.instance.recentEvents.length,
      todayAiCostUsd: aiTracker.getTodayCost(),
      monthAiCostUsd: aiTracker.getMonthCost(),
      totalAiTokens: aiTracker.getMonthTokens(),
      p50LatencyMs: aiTracker.p50LatencyMs,
      p95LatencyMs: aiTracker.p95LatencyMs,
      crashFreeRate: errMonitor.crashFreeUsersPercentage,
      mrrUsd: mrr,
      payingUsersCount: isPremium ? 1 : 0,
      totalPrayersCompleted: prayersDone,
      totalVersesRead: totalVerses,
    );
  }

  /// Exports all collected telemetry and AI costs as BigQuery-compatible NDJSON format
  String exportBigQueryNdjson() {
    final buffer = StringBuffer();
    final events = AnalyticsService.instance.recentEvents;

    for (final event in events) {
      buffer.writeln(jsonEncode(event.toJson()));
    }

    return buffer.toString();
  }

  /// Exports the AI cost ledger as CSV format
  String exportAiCostCsv() {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,model,input_tokens,output_tokens,cost_usd,latency_ms,success,had_citations,category,user_tier');

    final entries = AiCostTracker.instance.recentEntries;
    for (final e in entries) {
      buffer.writeln('${e.timestamp},${e.model},${e.inputTokens},${e.outputTokens},${e.costUsd},${e.latencyMs},${e.success},${e.hadCitations},${e.category},${e.userTier}');
    }

    return buffer.toString();
  }
}
