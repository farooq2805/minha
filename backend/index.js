/**
 * Minha Islamic App - Production Telemetry & Analytics Ingestion Service
 * Handles batched events, AI cost ledgers, and error reports.
 * Deploys seamlessly to Google Cloud Functions, Google Cloud Run, or App Engine.
 */

const express = require('express');
const cors = require('cors');
const { BigQuery } = require('@google-cloud/bigquery');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '2mb' }));

// Initialize Google Cloud BigQuery client
const DATASET_ID = process.env.BIGQUERY_DATASET || 'minha_analytics';
const bigquery = new BigQuery();

// Blacklist of forbidden PII fields
const FORBIDDEN_PII_KEYS = new Set([
  'email',
  'password',
  'phone',
  'phone_number',
  'token',
  'auth_token',
  'secret',
  'credit_card',
  'raw_prompt',
  'query_text',
  'private_note'
]);

/**
 * Recursively strips PII from an object
 */
function sanitizeProperties(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(sanitizeProperties);

  const clean = {};
  for (const [key, val] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    if (FORBIDDEN_PII_KEYS.has(lowerKey)) {
      continue; // Drop completely
    }
    if (typeof val === 'object' && val !== null) {
      clean[key] = sanitizeProperties(val);
    } else {
      clean[key] = val;
    }
  }
  return clean;
}

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'minha-telemetry-backend',
    dataset: DATASET_ID,
    timestamp: new Date().toISOString()
  });
});

/**
 * POST /api/v1/telemetry/events
 * Batched event ingestion into BigQuery `events_raw`
 */
app.post('/api/v1/telemetry/events', async (req, res) => {
  const events = req.body?.events;
  if (!Array.isArray(events) || events.length === 0) {
    return res.status(400).json({ error: 'Payload must contain a non-empty "events" array' });
  }

  const sanitizedRows = events.map(ev => ({
    event_id: String(ev.event_id || `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`),
    event_name: String(ev.event_name || 'unknown_event'),
    event_time: ev.event_time ? new Date(ev.event_time).toISOString() : new Date().toISOString(),
    ingestion_time: new Date().toISOString(),
    app_version: String(ev.app_version || '0.1.0'),
    platform: String(ev.platform || 'android'),
    environment: String(ev.environment || 'production'),
    session_id: String(ev.session_id || 'unknown_session'),
    anonymous_install_id: String(ev.anonymous_install_id || 'unknown_install'),
    properties: JSON.stringify(sanitizeProperties(ev.properties || {}))
  }));

  try {
    if (process.env.NODE_ENV === 'production' || process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      await bigquery
        .dataset(DATASET_ID)
        .table('events_raw')
        .insert(sanitizedRows, { raw: false });
    } else {
      // In local/emulated environment, log structured JSON for Cloud Logging sinks
      console.log(JSON.stringify({
        severity: 'INFO',
        message: `Ingested ${sanitizedRows.length} telemetry events`,
        eventCount: sanitizedRows.length,
        sampleEvent: sanitizedRows[0].event_name
      }));
    }

    return res.status(200).json({
      success: true,
      ingested: sanitizedRows.length
    });
  } catch (err) {
    console.error('BigQuery Streaming Ingestion Error:', err);
    return res.status(500).json({
      error: 'Failed to stream events to analytics warehouse',
      details: err.message
    });
  }
});

/**
 * POST /api/v1/telemetry/ai-usage
 * Ingestion into BigQuery `ai_usage_ledger`
 */
app.post('/api/v1/telemetry/ai-usage', async (req, res) => {
  const entries = req.body?.entries;
  if (!Array.isArray(entries) || entries.length === 0) {
    return res.status(400).json({ error: 'Payload must contain an "entries" array' });
  }

  const rows = entries.map(item => ({
    request_id: String(item.request_id || `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`),
    timestamp: item.timestamp ? new Date(item.timestamp).toISOString() : new Date().toISOString(),
    model: String(item.model || 'gemini-1.5-flash'),
    input_tokens: Number(item.input_tokens || 0),
    output_tokens: Number(item.output_tokens || 0),
    total_tokens: Number((item.input_tokens || 0) + (item.output_tokens || 0)),
    latency_ms: Number(item.latency_ms || 0),
    cost_usd: Number(item.cost_usd || 0.0),
    success: Boolean(item.success !== false),
    had_citations: Boolean(item.had_citations),
    topic_category: String(item.topic_category || 'general')
  }));

  try {
    if (process.env.NODE_ENV === 'production' || process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      await bigquery
        .dataset(DATASET_ID)
        .table('ai_usage_ledger')
        .insert(rows, { raw: false });
    } else {
      console.log(JSON.stringify({
        severity: 'INFO',
        message: `Ingested ${rows.length} AI cost ledger entries`,
        entriesCount: rows.length
      }));
    }

    return res.status(200).json({ success: true, ingested: rows.length });
  } catch (err) {
    console.error('AI Cost Ledger Ingestion Error:', err);
    return res.status(500).json({ error: 'Failed to stream AI usage', details: err.message });
  }
});

/**
 * POST /api/v1/telemetry/errors
 * Ingestion into BigQuery `error_ledger`
 */
app.post('/api/v1/telemetry/errors', async (req, res) => {
  const errors = req.body?.errors;
  if (!Array.isArray(errors) || errors.length === 0) {
    return res.status(400).json({ error: 'Payload must contain an "errors" array' });
  }

  const rows = errors.map(err => ({
    error_id: String(err.error_id || `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`),
    timestamp: err.timestamp ? new Date(err.timestamp).toISOString() : new Date().toISOString(),
    session_id: String(err.session_id || 'unknown'),
    error_type: String(err.error_type || 'UnknownException'),
    message: String(err.message || '').substring(0, 500),
    is_fatal: Boolean(err.is_fatal),
    app_version: String(err.app_version || '0.1.0'),
    platform: String(err.platform || 'android')
  }));

  try {
    if (process.env.NODE_ENV === 'production' || process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      await bigquery
        .dataset(DATASET_ID)
        .table('error_ledger')
        .insert(rows, { raw: false });
    } else {
      console.log(JSON.stringify({
        severity: 'WARNING',
        message: `Ingested ${rows.length} client exceptions`,
        errorsCount: rows.length
      }));
    }

    return res.status(200).json({ success: true, ingested: rows.length });
  } catch (err) {
    console.error('Error Ledger Ingestion Error:', err);
    return res.status(500).json({ error: 'Failed to stream errors', details: err.message });
  }
});

const PORT = process.env.PORT || 8080;
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Minha Analytics Ingestion Service listening on port ${PORT}`);
  });
}

// Export for Google Cloud Functions
module.exports = { app };
