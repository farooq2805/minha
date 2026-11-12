MASTER DEVELOPMENT PROMPT

COMPLETE ANALYTICS, TRACKING, MONITORING & BUSINESS INTELLIGENCE SYSTEM

Act as a senior mobile application architect, Firebase engineer, Google Analytics specialist, backend developer, data engineer, product analyst, security engineer and SaaS business intelligence architect.

I am developing a premium global Islamic application containing:

- Quran.
- AI Islamic Guide.
- Quran reading and tracking.
- Salah.
- Ramadan.
- Sehri and Iftar.
- Dua library.
- Islamic education.
- YouTube Islamic lectures.
- Zakat calculator.
- Advertisements.
- Premium subscriptions.
- User accounts.

I now want to implement a complete production-grade analytics, tracking, backend monitoring and business intelligence system.

This is a mandatory part of the application architecture.

The goal is to give the application owner complete visibility into user acquisition, engagement, retention, feature performance, revenue, AI costs, technical health, security and business growth.

IMPORTANT:

First inspect my existing codebase and identify its current framework, backend, database, authentication provider, deployment environment and installed packages.

Do not blindly replace existing architecture.

Preserve existing working features and implement the tracking architecture around the actual project.

If a different technology is already in use, adapt the recommended implementation rather than creating conflicting backend systems.

PART 1: CORE TRACKING ARCHITECTURE

Implement an integrated tracking ecosystem.

Recommended stack:

1. Firebase Analytics.
2. Google Analytics 4.
3. Firebase Crashlytics.
4. Firebase Performance Monitoring.
5. Firebase Cloud Messaging.
6. Firebase Remote Config.
7. Firebase App Check.
8. Google BigQuery.
9. Google Looker Studio.
10. Google Cloud Functions or Cloud Run.
11. Google Cloud Logging.
12. Google Play Console.
13. Apple App Store Connect.
14. Google AdMob.
15. Subscription analytics.
16. Custom backend analytics.

Use Firebase Analytics for app-level event tracking.

Use BigQuery as the detailed analytics warehouse.

Use Looker Studio or a custom web dashboard for business reporting.

Use Firebase Crashlytics and Performance Monitoring for technical health.

Use secure server-side logging for backend events, API usage, AI costs and financial records.

Do not treat Firebase Analytics as a replacement for the application's own business database.

PART 2: CENTRAL EVENT TRACKING SYSTEM

Build a reusable, centralised analytics service.

Create a common tracking interface that all modules can use.

Example event structure:

{
"event_name": "quran_reader_opened",
"event_id": "unique_event_id",
"event_time": "UTC_TIMESTAMP",
"app_version": "1.0.0",
"platform": "android",
"environment": "production",
"session_id": "session_reference",
"anonymous_install_id": "pseudonymous_install_reference",
"properties": {
"screen_name": "quran_reader"
}
}

This is an illustrative schema. Implement the actual event structure according to the selected analytics SDK and backend.

Requirements:

- Central analytics service.
- Standard event naming.
- Event validation.
- Typed event properties.
- Duplicate event protection where applicable.
- Offline event queue.
- Retry handling.
- Event delivery monitoring.
- Debug mode.
- Production mode.
- Consent-aware tracking.
- Analytics enable/disable controls.

Do not allow every module to implement its own unrelated tracking logic.

All events must use the central analytics service.

PART 3: USER ACQUISITION TRACKING

Track:

- First app launch.
- App installation attribution where available.
- App source.
- Organic acquisition.
- Paid acquisition.
- Referral acquisition.
- Campaign name.
- Campaign source.
- Campaign medium.
- Campaign ID.
- Country.
- Platform.
- App version.
- Device category.
- Registration source.

Registration events:

- signup_started
- signup_completed
- signup_failed
- login_started
- login_completed
- login_failed
- google_login
- apple_login
- email_login
- phone_login
- otp_verified
- guest_session_started
- guest_to_registered_conversion
- onboarding_started
- onboarding_completed
- account_deleted

Never include email addresses, phone numbers, passwords or authentication tokens in analytics events.

PART 4: USER ENGAGEMENT ANALYTICS

Measure:

- Daily Active Users.
- Weekly Active Users.
- Monthly Active Users.
- New users.
- Returning users.
- Session count.
- Session duration.
- Session frequency.
- Screen views.
- Feature usage.
- Retention.
- Churn.
- Reactivation.
- Onboarding completion.
- Feature adoption.

Create retention reports:

- Day 1.
- Day 7.
- Day 14.
- Day 30.
- Day 60.
- Day 90.

Create funnels:

INSTALL → FIRST OPEN → ONBOARDING → REGISTRATION → FIRST QURAN SESSION → RETURNING USER → PREMIUM CONVERSION.

Create cohort reports based on acquisition period and consent-compatible, non-sensitive dimensions.

PART 5: QURAN ANALYTICS

Create product analytics for:

- Quran reader opened.
- Reading session started.
- Reading session completed.
- Audio player opened.
- Audio playback started.
- Audio playback completed.
- Bookmark created.
- Bookmark removed.
- Reading target created.
- Reading target completed.
- Khatam tracker opened.
- Hifz mode opened.

Maintain private Quran reading progress in the application database.

Provide aggregate reporting for:

- Reading activity.
- Total reading sessions.
- Reading feature adoption.
- Audio feature adoption.
- Reading target completion rates.
- Khatam feature usage.
- Hifz feature usage.

Do not send identifiable worship records or individual reading histories to third-party advertising systems.

PART 6: AI ISLAMIC GUIDE ANALYTICS

This is a major part of the business and must have dedicated reporting.

Track:

- AI questions submitted.
- AI responses generated.
- Successful responses.
- Failed responses.
- Retrieval success.
- Citation validation success.
- Citation validation failure.
- Insufficient evidence responses.
- Average response time.
- P50 response time.
- P95 response time.
- Average input tokens.
- Average output tokens.
- Cost per response.
- Daily AI cost.
- Monthly AI cost.
- AI usage by subscription entitlement.
- User feedback.
- Response helpfulness.
- Follow-up usage.
- Scholar escalation count.
- Safety intervention count.
- API errors.

Build an AI cost dashboard.

Show:

- AI requests today.
- AI requests this month.
- Total token consumption.
- Cost by model.
- Cost by provider.
- Average cost per answer.
- AI cost per active user, using internal pseudonymous accounting.
- Cost by application module.
- Failed request cost.
- Estimated monthly AI expenditure.

Create budget alerts.

Allow administrators to configure daily and monthly AI expenditure limits.

Implement rate limits and subscription-based usage entitlements.

IMPORTANT PRIVACY REQUIREMENT:

Never send raw AI prompts, private answers, conversation transcripts, religious doubts, marriage problems, medical details or personal sensitive information to Firebase Analytics, Google Analytics, advertising platforms or marketing attribution tools.

Do not use sensitive religious question categories to create advertising audiences.

Keep detailed conversation records in a separate, access-restricted private system.

For product analytics, use carefully designed aggregate counters and privacy-preserving reporting.

PART 7: RAMADAN AND ISLAMIC MODULE ANALYTICS

Create feature-level aggregate reporting for:

RAMADAN:

- Ramadan dashboard opened.
- Ramadan calendar viewed.
- Sehri timetable opened.
- Iftar timetable opened.
- Ramadan planner used.
- Ramadan learning module opened.

DUA:

- Dua library opened.
- Dua audio played.
- Dua bookmarked.
- Dua sharing used.

SALAH:

- Prayer timetable opened.
- Qibla compass opened.
- Prayer reminders configured.

ISLAMIC LEARNING:

- Lesson opened.
- Lesson completed.
- Quiz started.
- Quiz completed.

Keep individual prayer records, fasting history and personal religious practices private.

PART 8: YOUTUBE ANALYTICS

Track:

- Video recommendation displayed.
- Video opened.
- Video playback started where observable.
- Video playback completed where observable.
- Timestamp link clicked.
- Video bookmarked.
- Video recommendation feedback.

Report:

- Most popular topics at aggregate level.
- Total video engagement.
- Video recommendation click-through rate.
- Video playback completion where available.
- Most useful educational content.
- External video referral activity.

Do not claim to know YouTube watch time or completion if the user leaves the app and watches in the external YouTube application.

Only collect playback metrics actually available through an authorised player integration.

PART 9: ADVERTISEMENT AND REVENUE TRACKING

Integrate Google AdMob.

Track:

- Ad request.
- Ad loaded.
- Ad impression.
- Ad click.
- Ad failed.
- Ad revenue.
- Ad format.
- Placement.
- eCPM.
- Estimated revenue.
- Ad frequency.

Create advertisement placements:

- Home dashboard.
- Educational articles.
- Video discovery.
- Other appropriate non-worship areas.

Do not show advertisements inside:

- Quran reading.
- Quran audio.
- Prayer.
- Adhkar.
- Sensitive AI conversations.
- Safety intervention screens.

Build advertisement reporting:

- Daily impressions.
- Monthly impressions.
- Clicks.
- CTR.
- eCPM.
- Revenue.
- Revenue by placement.
- Revenue by country.
- Revenue by platform.

Use appropriate consent and privacy controls.

Integrate Google UMP for advertising consent where required.

Never use sensitive religious or personal AI data for ad targeting.

PART 10: PREMIUM SUBSCRIPTION TRACKING

Implement subscription analytics.

Track:

- Subscription page opened.
- Subscription plan viewed.
- Trial started.
- Purchase initiated.
- Purchase successful.
- Purchase failed.
- Subscription renewed.
- Subscription cancelled.
- Subscription expired.
- Refund received.

Calculate:

- Total paying users.
- Active subscriptions.
- Monthly recurring revenue.
- Annual recurring revenue.
- Average revenue per paying user.
- Free-to-premium conversion.
- Renewal rate.
- Cancellation rate.
- Churn rate.
- Lifetime value where sufficient data exists.
- AI expenditure per subscription tier.

Validate all purchases server-side using the applicable Apple and Google purchase verification mechanisms.

Do not trust client-reported purchase success as the final financial record.

PART 11: TECHNICAL MONITORING

Implement Firebase Crashlytics.

Track:

- Fatal crashes.
- Non-fatal exceptions.
- Crash-free users.
- Crash-free sessions.
- Crash frequency.
- Affected app versions.
- Affected devices.
- Operating system compatibility.

Implement Firebase Performance Monitoring.

Measure:

- App startup.
- Screen rendering.
- API response time.
- Network latency.
- Database operation time.
- Quran loading time.
- Audio loading time.
- AI response latency.
- Image loading.
- Offline synchronisation.

Implement backend monitoring:

- API uptime.
- API response time.
- HTTP 4xx errors.
- HTTP 5xx errors.
- Database failures.
- Authentication failures.
- Cloud function errors.
- Failed background jobs.
- Notification failures.
- Queue processing delays.

Create critical issue alerts.

PART 12: SECURITY MONITORING

Implement:

- Firebase App Check where supported.
- Authentication security.
- Role-based access.
- API authentication.
- Rate limiting.
- Request validation.
- Database security rules.
- Row-level security where applicable.
- Audit logging.
- Suspicious activity detection.
- Failed login monitoring.
- Account deletion tracking.
- Data access monitoring.

Create a security dashboard.

Track:

- Failed authentication attempts.
- Suspicious API activity.
- Excessive AI requests.
- Invalid tokens.
- Unauthorised access attempts.
- Admin permission changes.
- Sensitive configuration changes.

Do not log passwords, access tokens, private conversation contents or other secrets.

PART 13: BACKEND DATA ARCHITECTURE

Create separate logical datasets.

DATASET 1: PRODUCT ANALYTICS

- analytics_events
- analytics_sessions
- analytics_funnels
- analytics_cohorts
- analytics_daily_metrics
- analytics_feature_usage

DATASET 2: BUSINESS ANALYTICS

- user_acquisition
- subscription_events
- payment_records
- ad_revenue
- marketing_campaigns
- revenue_daily_summary

DATASET 3: AI OPERATIONS

- ai_request_metrics
- ai_token_usage
- ai_provider_costs
- ai_latency_metrics
- ai_retrieval_metrics
- ai_quality_metrics
- ai_safety_metrics

DATASET 4: TECHNICAL MONITORING

- api_request_logs
- api_error_logs
- backend_health_metrics
- background_job_logs
- notification_delivery_logs
- security_audit_logs

DATASET 5: PRIVATE USER DATA

- private_user_profiles
- private_quran_progress
- private_prayer_logs
- private_fasting_logs
- private_ai_conversations
- private_user_notes

Enforce strict separation between private user data and analytics datasets.

Use pseudonymous identifiers for internal analytics where necessary.

Avoid direct user identifiers in exported analytics data.

Implement appropriate retention, deletion and access policies.

PART 14: ADMIN COMMAND CENTRE

Build a premium web-based admin dashboard.

Create the following pages.

PAGE 1: EXECUTIVE OVERVIEW

Display:

- Total registrations.
- Active users.
- New users.
- Returning users.
- Daily active users.
- Monthly active users.
- Total revenue.
- Premium subscriptions.
- AI expenditure.
- Crash-free sessions.
- Backend health.

PAGE 2: USER ANALYTICS

Display:

- Registrations.
- Login activity.
- Guest users.
- Retention.
- Churn.
- Cohorts.
- Acquisition.
- Country distribution.

PAGE 3: FEATURE ANALYTICS

Display:

- Quran usage.
- Prayer module usage.
- Ramadan engagement.
- Dua usage.
- Learning engagement.
- Video recommendations.
- AI Guide usage.

PAGE 4: AI ANALYTICS

Display:

- Questions processed.
- Answers generated.
- AI cost.
- Token usage.
- Response latency.
- Retrieval success.
- Citation verification.
- User feedback.
- Safety escalations.

PAGE 5: REVENUE ANALYTICS

Display:

- Ad revenue.
- Ad impressions.
- eCPM.
- Subscription revenue.
- Monthly recurring revenue.
- Renewals.
- Cancellations.
- Refunds.
- AI cost.
- Net contribution margin.

PAGE 6: TECHNICAL MONITORING

Display:

- Crashes.
- API latency.
- Backend uptime.
- Database health.
- Failed requests.
- App versions.
- Device compatibility.
- Error trends.

PAGE 7: SECURITY AND AUDIT

Display:

- Failed authentication.
- Suspicious activity.
- Admin activity.
- Permission changes.
- Security alerts.
- Audit records.

PAGE 8: REPORTS

Allow:

- Date filters.
- Country filters.
- Platform filters.
- App version filters.
- CSV export.
- PDF reporting.
- Scheduled reports.

All reports must use actual connected backend data.

Never show hardcoded sample figures in production dashboards.

PART 15: ANALYTICS AND ALERTS

Create configurable alerts for:

- Sudden increase in crashes.
- API uptime deterioration.
- Backend response time deterioration.
- Unusual AI spending.
- High AI error rate.
- Payment failures.
- Subscription cancellations.
- Notification delivery failures.
- Suspicious login activity.
- Database capacity warnings.

Support email or administrator notifications.

Allow configurable alert thresholds.

PART 16: PRIVACY AND COMPLIANCE

Privacy must be a core architectural requirement.

Implement:

- Privacy policy acceptance.
- Terms acceptance.
- Analytics consent.
- Advertising consent.
- Personalised advertising controls.
- Analytics opt-out.
- Account deletion.
- Data export.
- Data retention.
- Data minimisation.
- Encryption in transit.
- Encryption at rest.
- Restricted administrative access.

Respect applicable requirements under India's DPDP framework, GDPR, applicable US privacy laws, Apple App Store policies and Google Play policies.

Implement age-appropriate safeguards and assess parental consent requirements if children are included in the audience.

Do not use religious beliefs, religious questions, worship activity, relationship problems or health concerns for advertising profiling.

Use aggregate reporting and appropriate minimum group sizes to avoid identifying individual users.

Implement deletion propagation across connected systems where legally and technically required.

PART 17: BUSINESS INTELLIGENCE

Connect analytics data to BigQuery.

Create reporting views for:

- Daily registrations.
- Daily active users.
- Monthly active users.
- User retention.
- Acquisition channels.
- Feature adoption.
- Quran engagement.
- AI usage.
- AI cost.
- Ad revenue.
- Subscription revenue.
- Technical reliability.

Create a Looker Studio dashboard or an equivalent custom dashboard.

Build automated daily, weekly and monthly reporting.

Ensure that dashboard calculations are documented.

Avoid double-counting events and revenue.

Use server-verified financial transactions as the source of truth for revenue.

PART 18: QUALITY ASSURANCE

Test the complete tracking architecture.

Verify:

1. Every event is triggered correctly.
2. Events contain valid properties.
3. Duplicate events are controlled.
4. Events work on Android.
5. Events work on iOS.
6. Consent controls work.
7. Analytics opt-out works.
8. BigQuery exports work.
9. Dashboard numbers match backend records.
10. Subscription revenue is accurate.
11. Ad revenue is correctly attributed.
12. AI cost calculations are accurate.
13. Crash reporting works.
14. Performance monitoring works.
15. Security alerts work.
16. Data deletion works.
17. Private conversations are not leaked.
18. Production dashboards do not contain mock data.

Create an automated tracking validation suite.

PART 19: IMPLEMENTATION METHOD

Do not implement everything in one unstructured operation.

First inspect the repository.

Then produce:

1. Current architecture assessment.
2. Tracking implementation plan.
3. Event taxonomy.
4. Data schema.
5. Firebase configuration requirements.
6. Backend integration plan.
7. BigQuery schema.
8. Dashboard wireframes.
9. Privacy architecture.
10. Development phases.

Then implement in phases.

PHASE 1:
Firebase project configuration and central analytics service.

PHASE 2:
User acquisition, registration and engagement events.

PHASE 3:
Quran, Salah, Ramadan and Dua tracking.

PHASE 4:
AI analytics, token consumption and cost tracking.

PHASE 5:
AdMob and subscription analytics.

PHASE 6:
Crashlytics, Performance Monitoring and security monitoring.

PHASE 7:
BigQuery integration.

PHASE 8:
Admin analytics dashboard.

PHASE 9:
Automated reports and alerts.

PHASE 10:
Full tracking audit and production testing.

For each phase, implement, test and document the result before moving to the next phase.

PART 20: FINAL DELIVERABLES

Deliver:

- Central analytics service.
- Event taxonomy.
- Firebase integrations.
- Backend analytics service.
- BigQuery datasets.
- Data warehouse queries.
- Admin dashboard.
- Revenue dashboard.
- AI usage dashboard.
- Technical monitoring.
- Security monitoring.
- Consent management.
- Privacy controls.
- Alerting system.
- Automated reporting.
- QA documentation.
- Deployment documentation.

FINAL INSTRUCTION

Think like a senior engineer building an international production application with millions of potential users.

The final system must provide complete visibility into product performance, business performance, technical reliability, AI expenditure and monetisation.

Preserve user privacy, especially sensitive religious and personal information.

Do not use dummy data in production.

Do not mark a feature complete until its frontend, backend, event tracking, data validation and dashboard reporting have been tested.

Start by inspecting the existing application and creating the architecture and implementation plan. Then build the tracking system module by module.