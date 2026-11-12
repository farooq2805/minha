# Minha: instructions for Claude Code

Minha is a global, premium Quran app: "the Quran, one verse a day". Flutter, Android first, iOS later.
Owner: Farooq Syed (GitHub farooq2805). He is a marketer, not a developer: explain decisions in plain
language, do the technical work yourself, and never ask him to edit code.

**Status: full rebuild.** The current `lib/` works but is not up to the bar. Read
`docs/REBUILD_PLAN.md` before writing code. It holds the product scope, architecture, design system,
religious-content rules, known bugs and the phase plan. `docs/ANALYTICS_SPEC.md` is the owner's
analytics and BI requirement, delivered in the phases the plan sets out.

## Non-negotiables
- **Quality bar: premium, Apple-grade.** No default Material look, no placeholder screens shipped as done.
- **No payment without asking.** Firebase stays on the free Spark plan. Any step that needs billing
  (Blaze, BigQuery export, paid APIs) is proposed to the owner first, never enabled silently.
- **Religion:** the AI Guide never issues fatwas or rulings. It answers with cited Quran verses and
  authentic hadith, and refers rulings to a qualified scholar. Every dua shows its source. A scholar
  reviews all religious content before the Play Store release.
- **Ads never appear** on Quran text, reader, recitation, prayer, duas/adhkar, AI conversations,
  the iftar screen or kids mode.
- **Privacy:** never send AI prompts, answers, transcripts, prayer or fasting logs, or any personal
  religious data to Analytics, ads or attribution SDKs. Aggregate counters only.
- **No secrets in the repo or the app binary.** Signing keystore and API secrets live in GitHub
  Actions secrets. No user-supplied API keys in Settings.
- **Done means tested:** a feature is done only when it builds in CI, passes its tests, and the
  emulator walkthrough screenshots show it working.

## Commands
```
flutter create --org app.minha --project-name minha --platforms android .   # generates android/ (gitignored)
python3 scripts/patch_android.py      # INTERNET + location permissions, app label, launcher icons
flutter pub get
flutter analyze
flutter test
flutter run                            # phone with USB debugging
flutter build apk --release
```
CI (`.github/workflows/build-apk.yml`) on every push to any branch: analyze, `flutter test`, build APK and the
emulator walkthrough. Only `main` also publishes (below). Release signing uses the `KEYSTORE_BASE64`,
`KEYSTORE_PASSWORD` and optional `KEY_ALIAS` (default `upload`) secrets; without them the APK is debug-signed.
On `main`:
analyze, build APK, publish a GitHub Release and the `apk` branch (`minha-latest.apk`),
then install it on an Android emulator and run `scripts/smoke.sh`. That script taps through the app by
on-screen labels and pushes screenshots plus logcat to the `ci-shots` branch.
**Read those screenshots after every change.** Keep `smoke.sh` in sync when you rename labels.

## Links
- Design canvas (all screens, logo, colours): https://claude.ai/artifact/Mq7H4hMpgi4s86JeNPPsTh
- Research hub (market, ASO, growth, Ramadan, ads, sharing): https://claude.ai/artifact/XWDuhx5rpN2ryV87URvNx8
- Latest emulator preview and spec audit: https://claude.ai/artifact/14i2U7CUG8kh7ykYWp6prE

## Code layout (Phase 0)
- `lib/core/theme/`: design system. Import `package:minha/core/theme/theme.dart` only. Fonts are bundled
  in `assets/fonts` (never `google_fonts`): `ui()` Inter Tight, `serif()` Newsreader, `arabic()` Amiri Quran
  for Quran text only, `naskh()` Noto Naskh Arabic for duas and other Arabic.
- `lib/core/router/`: go_router. Every location is in `routes.dart`; navigate with `context.push(Routes.x)`.
- `lib/core/providers.dart`: Riverpod providers. Screens move from `Store.instance` to `ref.watch` as each
  feature is rebuilt.
- `lib/features/<feature>/{data,domain,ui}`.
