# Tester checklist — BronchTracker

BronchTracker is a **parent diary**, not a medical device. If a child is in severe respiratory distress, call emergency services. This checklist is for functional QA, not clinical validation.

Live web (after Pages deploy): https://michaelady.github.io/BronchTracker/

## Before you start
- [ ] Open the app on **web** (Chrome) and, if available, an **Android** emulator/device.
- [ ] Confirm the **emergency / not a medical device** disclaimer is visible on the welcome screen and Home.
- [ ] Guest mode works **without** Firebase keys (placeholder `lib/firebase_options.dart`).

## Guest / local mode
- [ ] Choose **Load sample family** and continue as guest.
- [ ] Home shows **Alex** (or Sam via the child switcher), today’s check-in, recent episodes, and an improvement idea.
- [ ] **Check in** for today: toggle symptoms, set rescue puffs, enter peak flow; save and see green/yellow/red zone when personal best is set.
- [ ] **Log episode**: type, start time, duration, severity 1–5, nighttime, ER/urgent, steroid burst, trigger chips, notes.
- [ ] **Log** tab: calendar dots (teal check-in, coral episode); tap a day; filter types.
- [ ] **Insights**: Week / Month / Season / Year. Episode count, avg severity, nighttime rate, ER rate, days between, trend, weekly bars, trigger bars, suggestion cards.
- [ ] **Copy visit summary** puts text on the clipboard (home diary disclaimer included).
- [ ] **Kids**: add a second child; edit action-plan green/yellow/red; add controller + rescue meds; set reminder time; see home reminder after that time if no check-in.
- [ ] Reload demo family; then **delete one child**; then **delete all diary data**. App still runs; Home asks to add a child.
- [ ] Refresh the web page: guest data still there (until you delete or clear site data).

## Google sync (only if Firebase is configured)
- [ ] Sign in with Google on web and Android.
- [ ] Data appears after a reload / second browser.
- [ ] Sign out keeps a local copy.
- [ ] Delete all while signed in clears the cloud document as well as local.

## Privacy & safety copy
- [ ] `/privacy.html` loads on GitHub Pages (and `web/privacy.html` locally).
- [ ] In-app Privacy screen matches: no ads, no selling data, easy delete.
- [ ] Suggestions never diagnose or prescribe (wording stays “discuss with your clinician”).

## Android APK smoke (when SDK is installed)
- [ ] `flutter build apk --release` produces `build/app/outputs/flutter-apk/app-release.apk`.
- [ ] applicationId is `com.bronchtracker.app`.
- [ ] Guest mode works offline after first install (no Google required).

## Out of scope (do not fail MVP)
- Smart inhaler / BLE hardware
- Clinician portal / EHR
- Kid-facing gamification
- iOS App Store
- OS push notifications (reminder is an in-app stub)
