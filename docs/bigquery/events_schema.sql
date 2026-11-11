-- ========================================================================
-- MINHA ISLAMIC APP - PRODUCTION BIGQUERY ANALYTICS DDL
-- Core Event Warehouse Table: Partitioned & Clustered
-- ========================================================================

CREATE SCHEMA IF NOT EXISTS `minha_analytics`
OPTIONS (
  location = 'us-central1',
  description = 'Minha App Central Event Warehouse & BI Datamart'
);

CREATE TABLE IF NOT EXISTS `minha_analytics.events_raw`
(
  event_id STRING NOT NULL OPTIONS(description="Globally unique UUID for deduplication"),
  event_name STRING NOT NULL OPTIONS(description="Standardized event name from AnalyticsEvents"),
  event_time TIMESTAMP NOT NULL OPTIONS(description="UTC timestamp when the event was recorded"),
  ingestion_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="UTC timestamp when ingested into BigQuery"),
  app_version STRING NOT NULL OPTIONS(description="Semantic app version e.g. 0.1.0"),
  platform STRING NOT NULL OPTIONS(description="Target platform: android, ios, macos, web"),
  environment STRING NOT NULL OPTIONS(description="production, staging, or debug"),
  session_id STRING NOT NULL OPTIONS(description="Ephemeral session identifier"),
  anonymous_install_id STRING NOT NULL OPTIONS(description="Pseudonymous installation identifier; zero PII"),
  properties JSON OPTIONS(description="Typed event payload metadata")
)
PARTITION BY DATE(event_time)
CLUSTER BY event_name, platform
OPTIONS (
  partition_expiration_days = 730,
  description = "Raw ingested event logs from Minha client applications"
);

-- ========================================================================
-- TABLE: AI USAGE & FINANCIAL COST LEDGER
-- Tracks exact Gemini token usage, pricing tiers, and latency percentiles
-- ========================================================================
CREATE TABLE IF NOT EXISTS `minha_analytics.ai_usage_ledger`
(
  request_id STRING NOT NULL OPTIONS(description="Unique request UUID"),
  timestamp TIMESTAMP NOT NULL OPTIONS(description="UTC timestamp of the AI query"),
  model STRING NOT NULL OPTIONS(description="Gemini model identifier e.g. gemini-1.5-flash"),
  input_tokens INT64 NOT NULL OPTIONS(description="Prompt token count"),
  output_tokens INT64 NOT NULL OPTIONS(description="Candidate token count"),
  total_tokens INT64 NOT NULL OPTIONS(description="Total token consumption"),
  latency_ms INT64 NOT NULL OPTIONS(description="End-to-end response latency in milliseconds"),
  cost_usd NUMERIC NOT NULL OPTIONS(description="Calculated cost in USD according to pricing matrix"),
  success BOOL NOT NULL OPTIONS(description="Whether the request succeeded"),
  had_citations BOOL NOT NULL OPTIONS(description="Whether response included authentic Quran/Hadith citations"),
  topic_category STRING NOT NULL OPTIONS(description="Sanitized Islamic topic label without prompt text")
)
PARTITION BY DATE(timestamp)
CLUSTER BY model, topic_category
OPTIONS (
  partition_expiration_days = 730,
  description = "Audit ledger for AI guide cost, token burn rate, and latency"
);

-- ========================================================================
-- TABLE: CRASH & RUNTIME EXCEPTION LEDGER
-- ========================================================================
CREATE TABLE IF NOT EXISTS `minha_analytics.error_ledger`
(
  error_id STRING NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  session_id STRING NOT NULL,
  error_type STRING NOT NULL,
  message STRING,
  is_fatal BOOL NOT NULL,
  app_version STRING NOT NULL,
  platform STRING NOT NULL
)
PARTITION BY DATE(timestamp)
CLUSTER BY error_type, is_fatal
OPTIONS (
  partition_expiration_days = 365,
  description = "Client and backend runtime error reports for Crash-free calculation"
);
