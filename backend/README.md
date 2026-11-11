# Minha Telemetry & Analytics Ingestion Backend

Production ingestion service that receives batched telemetry events, AI cost ledgers, and error reports from Minha mobile apps and streams them into **Google BigQuery**.

---

## Architecture Overview

```
                      +-----------------------------+
                      |       Minha Flutter App     |
                      |  (AnalyticsService Offline  |
                      |   Queue & Zero-PII Sanitizer|
                      +--------------+--------------+
                                     |
                                     v HTTPS POST
             +-----------------------------------------------+
             |       Google Cloud Run / Cloud Functions      |
             |       (Node.js 20 Ingestion Service)          |
             |  - Server-side PII stripping                  |
             |  - Token validation & Rate-limiting           |
             |  - High-throughput streaming inserts          |
             +-----------------------+-----------------------+
                                     |
                                     v Streaming API
                   +-----------------+-----------------+
                   |           Google BigQuery         |
                   |   minha_analytics.events_raw      |
                   |   minha_analytics.ai_usage_ledger |
                   |   minha_analytics.error_ledger    |
                   +-----------------+-----------------+
                                     |
                                     v SQL Views
                   +-----------------+-----------------+
                   |       Google Looker Studio        |
                   |   Executive BI & Operations Dash  |
                   +-----------------------------------+
```

---

## 1. Local Testing

```bash
cd backend
npm install
npm start
```

Health check:
```bash
curl http://localhost:8080/health
```

Sample event post:
```bash
curl -X POST http://localhost:8080/api/v1/telemetry/events \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {
        "event_name": "quran_reading_session_started",
        "event_time": "2026-11-11T08:00:00Z",
        "app_version": "0.1.0",
        "platform": "android",
        "environment": "production",
        "session_id": "sess_12345",
        "anonymous_install_id": "inst_67890",
        "properties": { "surah_number": 1 }
      }
    ]
  }'
```

---

## 2. One-Command Deployment to Google Cloud Run

```bash
gcloud run deploy minha-telemetry-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BIGQUERY_DATASET=minha_analytics
```

---

## 3. Alternative: Deploy to Firebase Cloud Functions

```bash
firebase deploy --only functions
```

---

## 4. Privacy & Compliance Guarantees

- **Automatic PII Stripping:** `email`, `phone`, `password`, `token`, `raw_prompt` are deleted at the server boundary before entering BigQuery.
- **Partitioning & Clustering:** Tables are partitioned by `event_time` date and clustered for optimal BigQuery query performance and low scanning cost.
