-- ========================================================================
-- MINHA ISLAMIC APP - LOOKER STUDIO / BI SQL VIEWS
-- Optimized reporting queries for Executive BI Dashboards
-- ========================================================================

-- 1. Daily Active Users, Sessions, and Engagement
CREATE OR REPLACE VIEW `minha_analytics.v_daily_active_users` AS
SELECT
  DATE(event_time) AS event_date,
  COUNT(DISTINCT anonymous_install_id) AS dau,
  COUNT(DISTINCT session_id) AS total_sessions,
  COUNTIF(event_name = 'app_first_open') AS new_installs,
  COUNTIF(event_name = 'onboarding_completed') AS onboarded_users,
  SAFE_DIVIDE(COUNTIF(event_name = 'onboarding_completed'), COUNTIF(event_name = 'app_first_open')) * 100 AS onboarding_conversion_rate,
  platform
FROM `minha_analytics.events_raw`
GROUP BY event_date, platform;

-- 2. Quran & Worship Analytics (Strictly preserving privacy)
CREATE OR REPLACE VIEW `minha_analytics.v_quran_and_worship` AS
SELECT
  DATE(event_time) AS event_date,
  COUNTIF(event_name = 'quran_reading_session_started') AS reading_sessions_started,
  COUNTIF(event_name = 'quran_reading_session_completed') AS reading_sessions_completed,
  COUNTIF(event_name = 'quran_bookmark_added') AS bookmarks_saved,
  COUNTIF(event_name = 'namaz_prayer_completed') AS prayers_offered,
  COUNTIF(event_name = 'ramadan_dashboard_opened') AS ramadan_views,
  COUNT(DISTINCT anonymous_install_id) AS active_worshippers
FROM `minha_analytics.events_raw`
GROUP BY event_date;

-- 3. AI Companion Costs, Latency Percentiles & Quality Ledger
CREATE OR REPLACE VIEW `minha_analytics.v_ai_financials_and_latency` AS
SELECT
  DATE(timestamp) AS usage_date,
  model,
  COUNT(*) AS total_queries,
  SUM(input_tokens) AS total_input_tokens,
  SUM(output_tokens) AS total_output_tokens,
  SUM(total_tokens) AS grand_total_tokens,
  ROUND(SUM(cost_usd), 4) AS total_cost_usd,
  ROUND(AVG(cost_usd), 6) AS avg_cost_per_query_usd,
  -- Latency percentiles
  APPROX_QUANTILES(latency_ms, 100)[OFFSET(50)] AS p50_latency_ms,
  APPROX_QUANTILES(latency_ms, 100)[OFFSET(95)] AS p95_latency_ms,
  SAFE_DIVIDE(COUNTIF(had_citations), COUNT(*)) * 100 AS citation_accuracy_rate,
  SAFE_DIVIDE(COUNTIF(success), COUNT(*)) * 100 AS ai_success_rate
FROM `minha_analytics.ai_usage_ledger`
GROUP BY usage_date, model;

-- 4. Crash-Free Rates & Technical Health (Crashlytics equivalent)
CREATE OR REPLACE VIEW `minha_analytics.v_technical_health` AS
WITH session_totals AS (
  SELECT
    DATE(event_time) AS date,
    COUNT(DISTINCT session_id) AS total_sessions,
    COUNT(DISTINCT anonymous_install_id) AS total_users
  FROM `minha_analytics.events_raw`
  GROUP BY date
),
crashes AS (
  SELECT
    DATE(timestamp) AS date,
    COUNT(DISTINCT session_id) AS crashed_sessions,
    COUNT(DISTINCT session_id) AS crashed_users,
    COUNTIF(is_fatal) AS fatal_crashes,
    COUNT(*) AS total_exceptions
  FROM `minha_analytics.error_ledger`
  GROUP BY date
)
SELECT
  s.date,
  s.total_sessions,
  s.total_users,
  COALESCE(c.fatal_crashes, 0) AS fatal_crashes,
  COALESCE(c.total_exceptions, 0) AS total_exceptions,
  ROUND(SAFE_DIVIDE((s.total_sessions - COALESCE(c.crashed_sessions, 0)), s.total_sessions) * 100, 2) AS crash_free_session_percentage,
  ROUND(SAFE_DIVIDE((s.total_users - COALESCE(c.crashed_users, 0)), s.total_users) * 100, 2) AS crash_free_user_percentage
FROM session_totals s
LEFT JOIN crashes c ON s.date = c.date;
