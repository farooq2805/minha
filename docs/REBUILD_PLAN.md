# Minha rebuild plan

## 1. Product
A scroll-native Quran app: full-screen verses matched to how the user feels, word-by-word meaning,
premium share cards, a full reader, an AI Islamic Guide, prayer times with a namaz tracker,
Quran progress, and a Ramadan mode. Global, starting with India and Pakistan (English, Hindi, Urdu),
then Indonesia, Malaysia, Bangladesh, Turkey, the Gulf and the diaspora.

Positioning against Muslim Pro, Quran.com, Al Quran (Tafsir & by Word), Quran Majeed: we do not
compete on "read the full Quran". We win on: a verse for how I feel, short-form scroll, beautiful
sharing to WhatsApp Status and Instagram, a warm AI companion that cites sources, a habit loop
(streaks, rings), and no ads on worship screens.

Working name **Minha** (منحة, "gift"). Store title: "Minha: Daily Quran Verses".

## 2. Screens (scope for v1)
1. **Sign in**: Google, Facebook, continue as guest. Name shown everywhere after sign-in.
2. **Onboarding**: name (prefilled from the account), mood, language, translation, location permission
   for prayer times, notification permission, analytics and ads consent.
3. **Today feed**: vertical full-screen verses, recitation, Save, Share, Meaning, Ask. A sponsored
   native card after every 8th verse (AdMob, halal-filtered, skippable).
4. **Meaning sheet**: word-by-word, transliteration, short tafsir excerpt with source.
5. **Share**: 4 card styles, "Shared by {name}" toggle, 9:16 for Status/Story, 4:5 for Instagram Post,
   deep link back to the verse. Targets: WhatsApp Status, WhatsApp, Instagram Story, Instagram Post
   (official icons from Meta brand resources), plus Copy text and More.
6. **Quran**: surah list, search, reader with recitation and verse highlight, bookmarks,
   continue-reading, khatam plan.
7. **AI Guide (Ask)**: a conversation, not a lookup. It asks gentle follow-up questions, answers with
   cited verses and authentic hadith, ends with a short written **report** (what was discussed,
   verses, a dua, one practical step), and schedules a **follow-up** reminder (FCM) a few days later.
   3 free conversations a day; a rewarded ad unlocks one more; Plus is unlimited.
8. **Salah**: today's 5 prayer times from device location, method and madhab settings, per-prayer
   minute adjustments to match the local mosque, a daily tracker (prayed on time / late / qada),
   streaks, adhan notifications, Qibla.
9. **Journey**: activity rings (Read, Listen, Reflect), streaks, Quran progress by page and juz from
   what was actually read, namaz history.
10. **Ramadan**: suhoor and iftar times with live countdown, iftar screen at Maghrib with duas,
    fasting tracker (with qada), khatam plan, last 10 nights, zakat calculator, Eid countdown.
    One sponsored "Iftar partner" slot.
11. **Settings and privacy**: account, language, translation, prayer settings, notifications,
    analytics and ads consent, export my data, delete my account.
12. **Admin dashboard**: NOT in the consumer app. A separate web app (Phase 8).

## 3. Architecture
- Flutter (stable), Dart 3, feature-first folders: `lib/features/<feature>/{data,domain,ui}`,
  `lib/core/{theme,router,analytics,services}`.
- State: Riverpod. Routing: go_router. Models: freezed + json_serializable.
- Backend: Firebase on the **Spark (free) plan**:
  Auth (Google, Facebook, anonymous guest with later linking), Cloud Firestore (profile, saved
  verses, reading progress, prayer and fasting logs, AI conversations in a private collection),
  Firebase AI Logic with the Gemini Developer API **free tier** (no key in the app; use App Check),
  Analytics, Crashlytics, Performance, Remote Config, Cloud Messaging, App Check.
- Anything needing Cloud Functions or BigQuery export requires Blaze: propose it to the owner first.
- Quran data: test builds use api.alquran.cloud and api.quran.com; production uses the licensed
  Quran Foundation API. Cache verses for offline reading.
- Prayer times: `adhan` package, computed on device, displayed in the location's time zone.
- Signing: one release keystore stored as GitHub secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`).
  Register its SHA-1 and SHA-256 in Firebase for Google Sign-In.
- `google-services.json` is injected in CI from a secret, not committed.

## 4. Design system
Apple-grade, calm, premium. Reference: the design canvas (link in CLAUDE.md).
- Colours: Emerald `#00875A` (primary; button gradient `#00A86B` to `#00804F`), Deep `#00573A`,
  Glow `#2BE08F`, Lamp gold `#E7C48A`, Night `#04201A`, Ink `#1C1C1E`, Grey `#6C6C70`,
  Grouped background `#F2F2F7`, Hairline `#D1D1D6`.
- Type: Inter Tight (UI), Newsreader (translations, wordmark "minha" lowercase),
  Amiri Quran (Quran text only), Noto Naskh Arabic (duas and other Arabic).
  Bundle fonts as assets; do not fetch at runtime.
- Large titles 34/700, grouped white cards with 14 radius, translucent blurred tab bar,
  dark mesh gradient (emerald, blue, gold) behind the feed and iftar screen.
- Logo: two pointed arches forming an "m" (a mihrab) with a gold eight-point star inside.
- Accessibility: 44pt touch targets, semantic labels, contrast AA, text scaling, RTL for Arabic.

## 5. Religious content rules
- Iftar dua shown first (the one most recited in India):
  اَللّٰهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلٰى رِزْقِكَ أَفْطَرْتُ
  "Allāhumma innī laka ṣumtu wa bika āmantu wa 'alayka tawakkaltu wa 'alā rizqika afṭartu".
  Note: its core "Allāhumma laka ṣumtu wa 'alā rizqika afṭartu" is in Sunan Abi Dawud 2358.
- Also: "Dhahaba aẓ-ẓama'u…" (Sunan Abi Dawud 2357); Laylat al-Qadr "Allāhumma innaka 'afuwwun…"
  (Jami' at-Tirmidhi 3513). Show Arabic, transliteration, English, Hindi and Urdu meaning, and source.
- AI Guide: system prompt enforces warm companion tone, no rulings or fatwas, cite every verse
  (surah:ayah) and hadith (collection and number), say "I'm not sure" rather than invent,
  escalate to a scholar for rulings, and show crisis resources for self-harm or abuse.
  Validate every cited verse key against the Quran data before showing it.

## 6. Known bugs in the current build (from the emulator run)
1. Ask needs a user-pasted Gemini key and calls a retired model; it falls back to canned text.
2. Admin dashboard is reachable from Settings by every user.
3. Bismillah shows twice at the top of surahs (verse 1 prefix not stripped).
4. Quran progress shows 0 after reading; the old manual juz grid is still on Journey.
5. Prayer times display in the device time zone, not the location's.
6. Text clipped: the greeting chip on the feed, the "left today" label on Ask.

## 7. Phases (each ends with CI green, tests passing, emulator screenshots reviewed)
- **Phase 0:** new project structure, theme and design system, bundled fonts, router, Riverpod,
  CI with signing secrets, smoke test updated. Port the good parts of the current code.
- **Phase 1:** Firebase project (owner accepts Firebase terms once), Auth (Google, guest, then
  Facebook after the Meta developer app exists), Firestore profile, central analytics service
  writing to Firebase Analytics (ANALYTICS_SPEC parts 1 to 3), Crashlytics, Performance.
- **Phase 2:** Feed, Meaning, Share, Quran reader, progress (spec part 5).
- **Phase 3:** Salah (times, tracker, adhan, Qibla), Journey, Ramadan (spec part 7).
- **Phase 4:** AI Guide on Firebase AI Logic with report, follow-ups and safety (spec part 6).
- **Phase 5:** Consent (UMP), AdMob placements, Plus subscription via Play Billing (spec parts 9,
  10, 16).
- **Phase 6 onwards (needs Blaze, owner approval):** BigQuery export, Cloud Functions for purchase
  validation and AI cost ledger, web admin dashboard, alerts (spec parts 11 to 17).
- Before release: privacy policy and terms hosted, Play Console listing, 14-day closed test with
  12+ testers, scholar review of religious content.
