import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics/ai_cost_tracker.dart';
import '../analytics/analytics_service.dart';
import '../analytics/business_intelligence.dart';
import '../theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.grouped,
      appBar: AppBar(
        title: Text('Business Intelligence & Health', style: ui(18, weight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: C.emerald,
          unselectedLabelColor: C.grey,
          indicatorColor: C.emerald,
          labelStyle: ui(13, weight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'AI Costs'),
            Tab(text: 'Revenue'),
            Tab(text: 'Events & Export'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: AnalyticsService.instance,
        builder: (context, _) {
          final summary = BusinessIntelligence.instance.getSummary();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(summary),
              _buildAiCostTab(summary),
              _buildRevenueTab(summary),
              _buildEventsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BiMetricsSummary s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _kpiCard('Sessions', '${s.totalSessions}', Icons.trending_up_rounded, C.emerald)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Crash-Free', '${s.crashFreeRate.toStringAsFixed(1)}%', Icons.shield_outlined, const Color(0xFF1E88E5))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _kpiCard('Today AI Cost', '\$${s.todayAiCostUsd.toStringAsFixed(4)}', Icons.auto_awesome_rounded, const Color(0xFFD97706))),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Verses Read', '${s.totalVersesRead}', Icons.menu_book_rounded, const Color(0xFF059669))),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle('System Health & Latency'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(.06))),
          child: Column(children: [
            _metricRow('P50 AI Response Latency', '${s.p50LatencyMs} ms'),
            const Divider(height: 16),
            _metricRow('P95 AI Response Latency', '${s.p95LatencyMs} ms'),
            const Divider(height: 16),
            _metricRow('Queued Telemetry Events', '${AnalyticsService.instance.queuedEventCount}'),
            const Divider(height: 16),
            _metricRow('Anonymous Client Reference', AnalyticsService.instance.anonymousInstallId.substring(0, 16) + '...'),
          ]),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Core User Funnel'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _funnelStep('1. Install & First Open', 1.0, '100%'),
            _funnelStep('2. Onboarding Complete', 0.92, '92%'),
            _funnelStep('3. Today Feed Engaged', 0.85, '85%'),
            _funnelStep('4. Prayer & Quran User', 0.68, '68%'),
            _funnelStep('5. AI Companion Prompt', 0.45, '45%'),
            _funnelStep('6. Returning D7 Retained', 0.38, '38%'),
          ]),
        ),
      ],
    );
  }

  Widget _buildAiCostTab(BiMetricsSummary s) {
    final ai = AiCostTracker.instance;
    final isDailyOver = ai.isDailyBudgetExceeded();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Budget Alert Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDailyOver ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDailyOver ? Colors.redAccent : C.emerald.withOpacity(.3)),
          ),
          child: Row(children: [
            Icon(isDailyOver ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isDailyOver ? Colors.red : C.emerald, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isDailyOver ? 'Daily AI Budget Exceeded' : 'AI Budget Healthy',
                    style: ui(15, weight: FontWeight.w700, color: isDailyOver ? Colors.red.shade900 : const Color(0xFF065F46))),
                Text('Today: \$${s.todayAiCostUsd.toStringAsFixed(4)} / \$${ai.dailyBudgetLimitUsd.toStringAsFixed(2)} limit',
                    style: ui(12.5, color: isDailyOver ? Colors.red.shade700 : const Color(0xFF047857))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: _kpiCard('Month Spend', '\$${s.monthAiCostUsd.toStringAsFixed(3)}', Icons.calendar_today_rounded, const Color(0xFFD97706))),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard('Token Consumption', '${s.totalAiTokens}', Icons.data_usage_rounded, const Color(0xFF2563EB))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _kpiCard('Avg Cost/Answer', '\$${ai.averageCostPerAnswer.toStringAsFixed(5)}', Icons.receipt_long_rounded, C.deep)),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard('Citation Accuracy', '${(ai.citationSuccessRate * 100).toStringAsFixed(1)}%', Icons.verified_rounded, const Color(0xFF059669))),
        ]),
        const SizedBox(height: 20),

        _sectionTitle('Google Gemini Pricing Model'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _metricRow('Gemini 1.5 Flash (Input)', '\$0.075 / 1M tokens'),
            const Divider(height: 16),
            _metricRow('Gemini 1.5 Flash (Output)', '\$0.300 / 1M tokens'),
            const Divider(height: 16),
            _metricRow('Total Queries Logged', '${ai.recentEntries.length}'),
            const Divider(height: 16),
            _metricRow('Monthly Projected Spend', '\$${(s.monthAiCostUsd * 1.25).toStringAsFixed(2)}'),
          ]),
        ),
      ],
    );
  }

  Widget _buildRevenueTab(BiMetricsSummary s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _kpiCard('Estimated MRR', '\$${s.mrrUsd.toStringAsFixed(2)}', Icons.attach_money_rounded, C.emerald)),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard('Paying Subscribers', '${s.payingUsersCount}', Icons.star_rounded, const Color(0xFFE28B00))),
        ]),
        const SizedBox(height: 20),

        _sectionTitle('AdMob Non-Intrusive Revenue Model'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _metricRow('Ad Status on Quran Reading', 'STRICTLY ZERO ADS (Policy)'),
            const Divider(height: 16),
            _metricRow('Ad Status on Prayer Timetable', 'ZERO ADS (Policy)'),
            const Divider(height: 16),
            _metricRow('Eligible Placements', 'Sponsored Card in Today Feed, Video Discovery'),
            const Divider(height: 16),
            _metricRow('Target eCPM (India/MENA/Global)', '\$1.45 - \$4.20'),
          ]),
        ),
        const SizedBox(height: 20),

        _sectionTitle('Subscription Tier Entitlements'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            _metricRow('Free Tier Entitlement', '5 AI questions/day + Ad unlock'),
            const Divider(height: 16),
            _metricRow('Minha Plus Plan', 'Unlimited AI questions + 100% Ad-free'),
            const Divider(height: 16),
            _metricRow('Monthly Plan Price', '₹99 / \$1.99 per month'),
          ]),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    final events = AnalyticsService.instance.recentEvents;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Export BigQuery JSON'),
              style: ElevatedButton.styleFrom(backgroundColor: C.emerald, foregroundColor: Colors.white),
              onPressed: () {
                final jsonStr = BusinessIntelligence.instance.exportBigQueryNdjson();
                Share.share(jsonStr, subject: 'minha_events_bigquery.ndjson');
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_rounded, size: 18),
              label: const Text('Export AI Cost CSV'),
              onPressed: () {
                final csv = BusinessIntelligence.instance.exportAiCostCsv();
                Share.share(csv, subject: 'minha_ai_cost_ledger.csv');
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionTitle('Live Event Stream (Last 100 Events)'),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('No events tracked yet in this session.', style: ui(14, color: C.grey))),
          )
        else
          for (final ev in events.reversed.take(40))
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(.05))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: C.emerald.withOpacity(.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(ev.eventName, style: ui(12.5, weight: FontWeight.w700, color: C.deep)),
                  ),
                  const Spacer(),
                  Text(ev.eventTime.substring(11, 19) + ' UTC', style: ui(11, color: C.grey)),
                ]),
                if (ev.properties.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    ev.properties.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ui(12, color: const Color(0xFF4B5563)),
                  ),
                ],
              ]),
            ),
      ],
    );
  }

  Widget _kpiCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
        ]),
        const SizedBox(height: 10),
        Text(val, style: ui(22, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(title, style: ui(12, color: C.grey)),
      ]),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: ui(13.5, color: const Color(0xFF374151)))),
        Text(value, style: ui(13.5, weight: FontWeight.w700, color: C.ink)),
      ]),
    );
  }

  Widget _funnelStep(String title, double ratio, String pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: ui(13, weight: FontWeight.w600)),
          const Spacer(),
          Text(pct, style: ui(13, weight: FontWeight.w700, color: C.emerald)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(C.emerald),
          ),
        ),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: ui(14, weight: FontWeight.w700, color: const Color(0xFF4B5563))),
    );
  }
}
