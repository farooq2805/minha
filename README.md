# Minha

The Quran, one verse a day. Flutter app, Android first.

## Get the APK on your phone
Every push to `main` builds a release APK with GitHub Actions.
Open this repo's **Releases** page on your phone, download the newest `minha-N.apk`,
and allow "Install unknown apps" for your browser when Android asks.

## Build locally
```
flutter create --org app.minha --project-name minha --platforms android .
flutter pub get
flutter run            # phone connected with USB debugging on
flutter build apk      # build/app/outputs/flutter-apk/app-release.apk
```
After `flutter create`, add `<uses-permission android:name="android.permission.INTERNET"/>`
to `android/app/src/main/AndroidManifest.xml` (the workflow does this automatically).

## Test build data sources
- Quran text and translations: api.alquran.cloud (Tanzil text)
- Recitation: Mishary Alafasy, cdn.islamic.network
- Word by word: api.quran.com v4
- Prayer times: `adhan` package, computed on device (Mumbai for now)

Before Play Store release: switch to the licensed Quran Foundation API, add AdMob
(native feed card, rewarded Ask unlock), device location, and scholar review of all duas.

## Share icons
Put the official WhatsApp and Instagram icons from Meta's brand resources in
`assets/share/` (names in `assets/share/README.txt`). Until then plain tiles show.
