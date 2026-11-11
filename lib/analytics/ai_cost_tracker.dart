import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiModelPricing {
  const AiModelPricing({
    required this.modelId,
    required this.inputPricePerMillion,
    required this.outputPricePerMillion,
  });

  final String modelId;
  final double inputPricePerMillion; // in USD
  final double outputPricePerMillion; // in USD

  double calculateCost(int inputTokens, int outputTokens) {
    final inCost = (inputTokens / 1000000.0) * inputPricePerMillion;
    final outCost = (outputTokens / 1000000.0) * outputPricePerMillion;
    return inCost + outCost;
  }
}

class AiCostLedgerEntry {
  AiCostLedgerEntry({
    required this.timestamp,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.costUsd,
    required this.latencyMs,
    required this.success,
    required this.hadCitations,
    required this.category,
    this.userTier = 'free',
  });

  final String timestamp;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final double costUsd;
  final int latencyMs;
  final bool success;
  final bool hadCitations;
  final String category; // Non-sensitive topic e.g. "patience", "prayer", "fasting"
  final String userTier;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'model': model,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cost_usd': costUsd,
        'latency_ms': latencyMs,
        'success': success,
        'had_citations': hadCitations,
        'category': category,
        'user_tier': userTier,
      };

  factory AiCostLedgerEntry.fromJson(Map<String, dynamic> j) => AiCostLedgerEntry(
        timestamp: j['timestamp'] as String,
        model: j['model'] as String,
        inputTokens: j['input_tokens'] as int,
        outputTokens: j['output_tokens'] as int,
        costUsd: (j['cost_usd'] as num).toDouble(),
        latencyMs: j['latency_ms'] as int,
        success: j['success'] as bool? ?? true,
        hadCitations: j['had_citations'] as bool? ?? true,
        category: j['category'] as String? ?? 'general',
        userTier: j['user_tier'] as String? ?? 'free',
      );
}

class AiCostTracker {
  AiCostTracker._();
  static final AiCostTracker instance = AiCostTracker._();

  late SharedPreferences _prefs;
  final List<AiCostLedgerEntry> _recentEntries = [];

  // Default Pricing models for Google Gemini
  static const Map<String, AiModelPricing> pricingCatalog = {
    'gemini-1.5-flash': AiModelPricing(
      modelId: 'gemini-1.5-flash',
      inputPricePerMillion: 0.075,
      outputPricePerMillion: 0.30,
    ),
    'gemini-1.5-pro': AiModelPricing(
      modelId: 'gemini-1.5-pro',
      inputPricePerMillion: 1.25,
      outputPricePerMillion: 5.00,
    ),
    'gemini-2.0-flash': AiModelPricing(
      modelId: 'gemini-2.0-flash',
      inputPricePerMillion: 0.10,
      outputPricePerMillion: 0.40,
    ),
  };

  // Configurable budget limits in USD
  double dailyBudgetLimitUsd = 5.00;
  double monthlyBudgetLimitUsd = 100.00;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    dailyBudgetLimitUsd = _prefs.getDouble('ai_daily_budget') ?? 5.00;
    monthlyBudgetLimitUsd = _prefs.getDouble('ai_monthly_budget') ?? 100.00;
    _loadRecentEntries();
  }

  void _loadRecentEntries() {
    final raw = _prefs.getStringList('ai_cost_entries') ?? [];
    _recentEntries.clear();
    for (final item in raw) {
      try {
        _recentEntries.add(AiCostLedgerEntry.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  Future<void> recordRequest({
    required String model,
    required int inputTokens,
    required int outputTokens,
    required int latencyMs,
    required bool success,
    required bool hadCitations,
    required String topicCategory,
    String userTier = 'free',
  }) async {
    final pricing = pricingCatalog[model] ?? pricingCatalog['gemini-1.5-flash']!;
    final cost = pricing.calculateCost(inputTokens, outputTokens);
    final now = DateTime.now().toUtc().toIso8601String();

    final entry = AiCostLedgerEntry(
      timestamp: now,
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      costUsd: cost,
      latencyMs: latencyMs,
      success: success,
      hadCitations: hadCitations,
      category: topicCategory,
      userTier: userTier,
    );

    _recentEntries.add(entry);
    if (_recentEntries.length > 500) {
      _recentEntries.removeRange(0, _recentEntries.length - 500);
    }

    final raw = _recentEntries.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('ai_cost_entries', raw);

    // Update cumulative token and spend counters
    final todayKey = now.substring(0, 10);
    final monthKey = now.substring(0, 7);

    final todayCost = (_prefs.getDouble('ai_cost|$todayKey') ?? 0.0) + cost;
    await _prefs.setDouble('ai_cost|$todayKey', todayCost);

    final monthCost = (_prefs.getDouble('ai_cost|$monthKey') ?? 0.0) + cost;
    await _prefs.setDouble('ai_cost|$monthKey', monthCost);

    final todayTokens = (_prefs.getInt('ai_tokens|$todayKey') ?? 0) + inputTokens + outputTokens;
    await _prefs.setInt('ai_tokens|$todayKey', todayTokens);

    final monthTokens = (_prefs.getInt('ai_tokens|$monthKey') ?? 0) + inputTokens + outputTokens;
    await _prefs.setInt('ai_tokens|$monthKey', monthTokens);
  }

  double getTodayCost() {
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _prefs.getDouble('ai_cost|$todayKey') ?? 0.0;
  }

  double getMonthCost() {
    final monthKey = DateTime.now().toUtc().toIso8601String().substring(0, 7);
    return _prefs.getDouble('ai_cost|$monthKey') ?? 0.0;
  }

  int getTodayTokens() {
    final todayKey = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _prefs.getInt('ai_tokens|$todayKey') ?? 0;
  }

  int getMonthTokens() {
    final monthKey = DateTime.now().toUtc().toIso8601String().substring(0, 7);
    return _prefs.getInt('ai_tokens|$monthKey') ?? 0;
  }

  int getTodayRequestCount() {
    final todayPrefix = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    return _recentEntries.where((e) => e.timestamp.startsWith(todayPrefix)).length;
  }

  int getMonthRequestCount() {
    final monthPrefix = DateTime.now().toUtc().toIso8601String().substring(0, 7);
    return _recentEntries.where((e) => e.timestamp.startsWith(monthPrefix)).length;
  }

  bool isDailyBudgetExceeded() {
    return getTodayCost() >= dailyBudgetLimitUsd;
  }

  bool isMonthlyBudgetExceeded() {
    return getMonthCost() >= monthlyBudgetLimitUsd;
  }

  /// Calculates percentile latency in milliseconds
  int getLatencyPercentile(double percentile) {
    if (_recentEntries.isEmpty) return 0;
    final latencies = _recentEntries.map((e) => e.latencyMs).toList()..sort();
    final index = (latencies.length * percentile).clamp(0, latencies.length - 1).toInt();
    return latencies[index];
  }

  int get p50LatencyMs => getLatencyPercentile(0.50);
  int get p95LatencyMs => getLatencyPercentile(0.95);

  double get averageCostPerAnswer {
    if (_recentEntries.isEmpty) return 0.0;
    final total = _recentEntries.fold<double>(0.0, (acc, e) => acc + e.costUsd);
    return total / _recentEntries.length;
  }

  double get citationSuccessRate {
    if (_recentEntries.isEmpty) return 1.0;
    final cited = _recentEntries.where((e) => e.hadCitations).length;
    return cited / _recentEntries.length;
  }

  List<AiCostLedgerEntry> get recentEntries => List.unmodifiable(_recentEntries);
}
