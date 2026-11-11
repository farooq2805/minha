# Minha - Privacy, Telemetry & Compliance Architecture

This document outlines the strict privacy boundaries and zero-PII enforcement built into the Minha analytics and business intelligence system.

---

## 1. Zero-PII Invariant

Minha adheres to a strict zero-personally-identifiable-information (Zero-PII) architecture:
- **No Email Addresses:** User account emails are stored strictly locally in encrypted SharedPreferences and are **never** included in analytics events or telemetry payloads.
- **No Passwords or Tokens:** Passwords, API keys, and session tokens are strictly filtered out by client and server sanitizers.
- **No Private Worship Recording:** The app **never** tracks private du'a text, personal doubts, or private spiritual reflections.
- **Pseudonymous Identifiers:** Every user device generates an anonymous `anonymous_install_id` (`UUIDv4`) stored locally. This ID cannot be reverse-engineered to identify a physical individual.

---

## 2. Sanctity of Worship & Ethical Monetization (Ad Policy)

In accordance with Islamic values and user respect:
1. **Quran Reader Screen:** **100% strictly ad-free.** No banner, interstitial, or rewarded ads are ever permitted while a user is reading or reciting the Holy Quran.
2. **Namaz & Adhan Screen:** **100% strictly ad-free.** Prayer timetables and Qibla compass screens are sacred utility spaces with zero promotional interruptions.
3. **AI Companion:** Standard daily quota with optional ad-unlock for additional queries, with clear disclaimer that answers are educational and require scholar verification for formal fatwas.
4. **Eligible Ad Placements:** Non-intrusive sponsor cards in the general discovery feed only.

---

## 3. Data Flow & Security Boundaries

```
[Minha App] 
     |
     | (1) Client-side Zero-PII sanitization
     v
[Offline Queue / Local Storage]
     |
     | (2) HTTPS TLS 1.3 Transmission
     v
[Google Cloud Run Ingestion]
     |
     | (3) Server-side Recursive Key Stripping
     v
[Google BigQuery Warehouse] (Partitioned, 730-day retention)
     |
     v
[Looker Studio Executive Dashboard]
```

---

## 4. Consent & User Control

Users have full autonomy:
- In `Settings > Privacy & Diagnostics`, users can toggle off telemetry at any time.
- When toggled off, `AnalyticsService.setTrackingEnabled(false)` purges the offline queue and drops all future event dispatches.
- The app operates with 100% full offline capability without requiring network connectivity.
