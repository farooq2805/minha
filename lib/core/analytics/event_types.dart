/// Standard event names and parameter definitions for Minha.
/// Enforces consistent naming, typed properties, and privacy preservation.

class AnalyticsEvents {
  // --- Acquisition & Auth ---
  static const String appFirstOpen = 'app_first_open';
  static const String appInstallAttributed = 'app_install_attributed';
  static const String onboardingStarted = 'onboarding_started';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String signupStarted = 'signup_started';
  static const String signupCompleted = 'signup_completed';
  static const String signupFailed = 'signup_failed';
  static const String loginStarted = 'login_started';
  static const String loginCompleted = 'login_completed';
  static const String loginFailed = 'login_failed';
  static const String googleLogin = 'google_login';
  static const String appleLogin = 'apple_login';
  static const String emailLogin = 'email_login';
  static const String phoneLogin = 'phone_login';
  static const String otpVerified = 'otp_verified';
  static const String guestSessionStarted = 'guest_session_started';
  static const String guestToRegisteredConversion = 'guest_to_registered_conversion';
  static const String accountDeleted = 'account_deleted';

  // --- Engagement & Navigation ---
  static const String sessionStart = 'session_start';
  static const String sessionEnd = 'session_end';
  static const String screenView = 'screen_view';
  static const String featureUsed = 'feature_used';
  static const String userEngagement = 'user_engagement';

  // --- Quran Module ---
  static const String quranReaderOpened = 'quran_reader_opened';
  static const String readingSessionStarted = 'reading_session_started';
  static const String readingSessionCompleted = 'reading_session_completed';
  static const String audioPlayerOpened = 'audio_player_opened';
  static const String audioPlaybackStarted = 'audio_playback_started';
  static const String audioPlaybackCompleted = 'audio_playback_completed';
  static const String bookmarkCreated = 'bookmark_created';
  static const String bookmarkRemoved = 'bookmark_removed';
  static const String readingTargetCreated = 'reading_target_created';
  static const String readingTargetCompleted = 'reading_target_completed';
  static const String khatamTrackerOpened = 'khatam_tracker_opened';
  static const String hifzModeOpened = 'hifz_mode_opened';

  // --- AI Islamic Guide (Minha Companion) ---
  static const String aiQuestionSubmitted = 'ai_question_submitted';
  static const String aiResponseGenerated = 'ai_response_generated';
  static const String aiResponseFailed = 'ai_response_failed';
  static const String aiCitationValidated = 'ai_citation_validated';
  static const String aiCitationValidationFailed = 'ai_citation_validation_failed';
  static const String aiInsufficientEvidence = 'ai_insufficient_evidence';
  static const String aiFeedbackSubmitted = 'ai_feedback_submitted';
  static const String aiCostRecorded = 'ai_cost_recorded';
  static const String aiBudgetAlert = 'ai_budget_alert';
  static const String aiRateLimited = 'ai_rate_limited';
  static const String aiScholarEscalated = 'ai_scholar_escalated';
  static const String aiSafetyIntervention = 'ai_safety_intervention';

  // --- Salah, Ramadan & Islamic Living ---
  static const String prayerTimetableOpened = 'prayer_timetable_opened';
  static const String prayerCompleted = 'prayer_completed';
  static const String prayerReminderConfigured = 'prayer_reminder_configured';
  static const String qiblaOpened = 'qibla_opened';
  static const String ramadanDashboardOpened = 'ramadan_dashboard_opened';
  static const String ramadanCalendarViewed = 'ramadan_calendar_viewed';
  static const String sehriTimetableOpened = 'sehri_timetable_opened';
  static const String iftarTimetableOpened = 'iftar_timetable_opened';
  static const String fastMarked = 'fast_marked';
  static const String duaLibraryOpened = 'dua_library_opened';
  static const String duaAudioPlayed = 'dua_audio_played';
  static const String duaBookmarked = 'dua_bookmarked';
  static const String duaShared = 'dua_shared';
  static const String zakatCalculatorOpened = 'zakat_calculator_opened';
  static const String zakatCalculated = 'zakat_calculated';

  // --- YouTube & Educational Media ---
  static const String videoRecommendationDisplayed = 'video_recommendation_displayed';
  static const String videoOpened = 'video_opened';
  static const String videoPlaybackStarted = 'video_playback_started';
  static const String videoPlaybackCompleted = 'video_playback_completed';
  static const String videoTimestampClicked = 'video_timestamp_clicked';
  static const String videoBookmarked = 'video_bookmarked';

  // --- Advertisements (AdMob) ---
  static const String adRequest = 'ad_request';
  static const String adLoaded = 'ad_loaded';
  static const String adImpression = 'ad_impression';
  static const String adClick = 'ad_click';
  static const String adFailed = 'ad_failed';
  static const String adRevenue = 'ad_revenue';

  // --- Subscriptions & In-App Purchases ---
  static const String subscriptionPaywallOpened = 'subscription_paywall_opened';
  static const String subscriptionPlanViewed = 'subscription_plan_viewed';
  static const String trialStarted = 'trial_started';
  static const String purchaseInitiated = 'purchase_initiated';
  static const String purchaseSuccess = 'purchase_success';
  static const String purchaseFailed = 'purchase_failed';
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String subscriptionExpired = 'subscription_expired';
  static const String refundReceived = 'refund_received';

  // --- Technical & Performance ---
  static const String appFatalCrash = 'app_fatal_crash';
  static const String appException = 'app_exception';
  static const String performanceTrace = 'performance_trace';
  static const String apiLatency = 'api_latency';
}

/// Standardized event structure compliant with BigQuery & Google Analytics 4.
class AnalyticsEvent {
  AnalyticsEvent({
    required this.eventName,
    required this.eventId,
    required this.eventTime,
    required this.appVersion,
    required this.platform,
    required this.environment,
    required this.sessionId,
    required this.anonymousInstallId,
    required this.properties,
  });

  final String eventName;
  final String eventId;
  final String eventTime;
  final String appVersion;
  final String platform;
  final String environment;
  final String sessionId;
  final String anonymousInstallId;
  final Map<String, dynamic> properties;

  Map<String, dynamic> toJson() => {
        'event_name': eventName,
        'event_id': eventId,
        'event_time': eventTime,
        'app_version': appVersion,
        'platform': platform,
        'environment': environment,
        'session_id': sessionId,
        'anonymous_install_id': anonymousInstallId,
        'properties': properties,
      };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        eventName: json['event_name'] as String,
        eventId: json['event_id'] as String,
        eventTime: json['event_time'] as String,
        appVersion: json['app_version'] as String? ?? '0.1.0',
        platform: json['platform'] as String? ?? 'android',
        environment: json['environment'] as String? ?? 'production',
        sessionId: json['session_id'] as String? ?? '',
        anonymousInstallId: json['anonymous_install_id'] as String? ?? '',
        properties: (json['properties'] as Map<String, dynamic>?) ?? {},
      );
}
