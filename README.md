# BronchTracker

Parent-facing diary for kids’ **recurring breathing problems** — bronchitis flares, asthma exacerbations, wheeze, and cough bouts. Built with Flutter for **web + Android**.

**Not a medical device. Not emergency care. Not a diagnosis or prescription tool.**  
If a child has severe breathing distress (cannot speak, blue lips/nails, ribs pulling in, or you are worried), call emergency services (**911** in the US) immediately.

Live web (GitHub Pages): [https://michaelady.github.io/BronchTracker/](https://michaelady.github.io/BronchTracker/)  
Privacy: [https://michaelady.github.io/BronchTracker/privacy.html](https://michaelady.github.io/BronchTracker/privacy.html)

## Why this exists

Families already have strong clinical apps. BronchTracker’s MVP matches their table-stakes (multi-child log, symptoms, rescue puffs, peak-flow zones, meds, a written action plan, visit summary) **without smart hardware**, and adds **stats plus educational “propose improvements” cards**.

| Capability | Children’s Health Asthma Buddy | Asthma+me (NHS / pediatric) | Asthma Tracker / Asthmahub-style | **BronchTracker MVP** |
|---|---|---|---|---|
| Parent + multi-child | Accounts / family | Family multi-child | Usually one diary | **Yes — multiple kids under a parent** |
| Symptom + med tracking | Yes | Yes | Yes | **Yes (controller + rescue list)** |
| Reminders | Yes | Yes | Often | **In-app local reminder stub** (not a medical alarm) |
| Asthma action plan | Yes | Care plan share | Zones | **Green / yellow / red notes the parent enters** |
| ACT / scores | ACT | Charts / PDF | Peak-flow diary | **Episode stats + optional PEF zones** (no ACT questionnaire in MVP) |
| Education | Yes | Yes | Varies | **Improvement suggestion cards** (non-diagnostic) |
| Connected peak flow / inhaler | — | Yes (devices) | Sometimes | **Out of scope** — manual PEF only |
| Multi-device sync | Yes | Yes | Varies | **Google Sign-In + Firestore when configured** |
| Guest / demo | Varies | Varies | Varies | **Yes — full guest mode + tester seed data** |
| Clinician portal / EHR | Some | Share / reports | Export | **Visit-summary copy** only |
| Ads / data sale | — | — | — | **None** |

## Guest mode vs Google sync

- **Guest / local:** everything runs on-device (or in the browser). Testers do not need Firebase.
- **Google Sign-In:** enabled only when `lib/firebase_options.dart` is replaced with real FlutterFire values. Diary is stored at `users/{uid}` in Cloud Firestore.

## Run locally

Requirements: Flutter stable (3.47+ / Dart 3.13+).

```bash
flutter pub get
flutter test
flutter run -d chrome
# or
flutter run -d android
```

Web production build (same flags as GitHub Pages):

```bash
flutter build web --release --base-href /BronchTracker/
```

Then serve `build/web` (for example `python3 -m http.server -d build/web 8080`).

## Android APK

`applicationId` is **`com.bronchtracker.app`**.

```bash
flutter build apk --release
# artifact: build/app/outputs/flutter-apk/app-release.apk
```

Debug install:

```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Release currently uses the debug signing config so `flutter run --release` works. For Play distribution, add a real keystore (`android/key.properties`) and point `signingConfig` at it.

If the Android SDK is not installed, install [Android Studio](https://developer.android.com/studio) or `cmdline-tools`, accept licenses (`flutter doctor --android-licenses`), then rebuild.

## Firebase setup (optional)

Guest mode works with the placeholder options checked into `lib/firebase_options.dart` (`REPLACE_…` keys). Google Sign-In stays hidden until config is real.

1. Create a Firebase project (Spark is enough for a family diary).
2. Add **Web** and **Android** apps. Android package name: `com.bronchtracker.app`.
3. Enable **Google** in Authentication → Sign-in method.
4. Create Firestore in production mode; start with a locked-down rule such as:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

5. From this repo:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project YOUR_PROJECT_ID --platforms=web,android --yes
```

That overwrites `lib/firebase_options.dart`. Commit it **only** if you are comfortable shipping client API keys (normal for Firebase web apps; still restrict HTTP referrers / Android app SHA-1 in Google Cloud).

6. **Web Google Sign-In:** authorized domains must include `localhost` and `michaelady.github.io`. Optionally set the OAuth client meta tag in `web/index.html`.
7. **Android Google Sign-In:** add your debug and release SHA-1 fingerprints to the Firebase Android app.

Do not commit a production `google-services.json` with extra secrets you do not intend to be public; FlutterFire’s Dart options are enough for this app.

## Screens

1. **Home** — today, check-in, quick episode, latest suggestion.
2. **Log** — month calendar + episode list + filters.
3. **Insights** — frequency, severity, nighttime/ER rates, triggers, trend, improvement cards, visit summary copy.
4. **Kids / Settings** — children, meds, action plan, reminder, privacy, delete.

## Data & privacy

Kids’ health data is treated as sensitive:

- No ads, no sale of data.
- Easy delete (one child or everything).
- Guest data never leaves the device unless you sign in with a configured Firebase project.

See `web/privacy.html` and the in-app Privacy screen.

## CI / GitHub Pages

`.github/workflows/deploy-web.yml` runs `flutter analyze`, `flutter test`, and `flutter build web --base-href /BronchTracker/` on PRs. Pushes to `main` publish `build/web` to the **gh-pages** branch.

One-time repo setting: Settings → Pages → Deploy from branch **gh-pages** / root. After the first successful `main` deploy the site is https://michaelady.github.io/BronchTracker/

## Tester

See [docs/tester-checklist.md](docs/tester-checklist.md). Use **Load sample family** on the welcome screen (Alex & Sam).

## Out of scope (MVP)

Smart inhaler / BLE hardware, clinician portal, EHR, kid gamification, iOS App Store.
