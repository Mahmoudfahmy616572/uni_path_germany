# uni_path_germany — Session Summary

## Paymob Payment Integration
- API key + HMAC + Integration ID (5736696) + Iframe ID (1054329)
- Flow: Edge Function → WebView iframe → webhook + fallback `activatePremium()`

## Google Play Preparation
- `google-services.json`: package_name updated to `com.unipath.app`
- `build.gradle.kts`: Fixed Properties import + storeFile null safety
- Application ID: `com.unipath.app`

## 5 New User Services
1. **Deadline Calendar** (`/deadline-calendar`): `table_calendar` + deadline list from saved applications
2. **University Comparison** (`/compare`): Side-by-side DataTable with checkbox selection in search
3. **Document Templates** (`/document-templates`): 3 template cards (CV, Motivation Letter, Recommendation)
4. **Enhanced Application Dashboard**: `PipelineMetricsHub` with status bar + 3 metrics
5. **Scholarship Finder**: Deferred (needs backend table)

## German Language Certificate
- **Onboarding step 6** → new `GermanCertStepWidget` (type: TestDaF/Goethe/DSH/Telc/ÖSD + CEFR level A1-C2)
- **Profile DB columns**: `has_german_cert`, `german_cert_type`, `german_cert_level`
- **Document upload** → 6th doc type `has_german_cert_doc` in `SmartDocumentHubScreen`
- **AI prompts**: guidance for reviewing German certs, status in student context
- **MissingDocTemplates**: `_germanCert()` template, included in suggestions when `has_german_cert == true`
- **MatchScoreCalculator**: completeness now includes `has_german_cert_doc` (redistributed: transcripts 2, bachelor 2, SOP 2, CV 2, german cert 2 = 10)
- **Register flow**: params `hasGermanCert`, `germanCertType`, `germanCertLevel` passed through all layers
- Total onboarding steps: 12 (was 11)

## Biometric Auth Fix
- Replaced nested `FutureBuilder` with state variables (`_biometricAvailable`, `_biometricEnabled`, `_biometricLoading`)
- `onChanged` extracted to `_onBiometricToggle()`, captures `scaffold`/`loc` before async gap
- `AuthResult` class: `authenticate()` returns `success` + `errorMessage`
- `AndroidManifest.xml`: `USE_BIOMETRIC` permission
- `MainActivity.kt`: `FlutterFragmentActivity` (required by local_auth)
- `biometricOnly: false` (allows PIN/pattern fallback)
- `StickyAuth: true` kept

## Search UX Improvements
- Tuition default: `_maxTuition = 0` (instead of 20000), filter only when `> 0`
- Loading suppression: `_fetchFilteredData()` skips `UniversitySearchLoading()` when results exist
- Debounce: 300ms → 800ms

## Onboarding Redirect Fix
- `LocalStorageService.markOnboardingComplete()` + `isOnboardingComplete()` (Hive offline box)
- Called in `OnboardingCubit.saveOnboardingData()`, `RegisterCubit.registerUser()`, and `signInWithOAuth()`
- `SplashScreen._navigateAfterDelay()`: if onboarding done + no session → `/login`; if not done + no session → `/onboarding`

## Email Tracking OAuth Fix
- **Problem**: Clicking "Connect Email" opened in-app WebView → showed black screen + "Your assistant is blocked" (Google blocks OAuth in embedded WebViews)
- **Root cause 1**: Google OAuth policy requires system browser (Chrome), not embedded WebView
- **Root cause 2**: Redirect URI `http://localhost/email_callback` not interceptable on real devices
- **Fix**: Replaced `WebViewScreen` with `url_launcher` (opens system browser) + `app_links` deep link listener
- **Redirect URI**: Changed from `http://localhost/email_callback` → `com.unipath.app://email_callback`
- **AndroidManifest**: Added intent filter for `com.unipath.app` scheme with `email_callback` host
- **Flow**: User clicks Connect → `launchUrl()` opens system browser → OAuth completes → browser redirects to `com.unipath.app://email_callback?code=...` → Android opens app → `app_links` stream fires → `_handleDeepLink()` extracts code → `_exchangeCode()` calls Edge Function `email-sync`
- **App state**: `_connecting` bool disables buttons during OAuth; `_connecting` progress indicator shown
- **Lifecycle**: `_deepLinkSub` subscribed in `initState`, cancelled in `dispose`; `getInitialLink()` for cold starts

## Cleanup
- `webview_screen.dart` deleted (orphaned — only `email_tracking_screen.dart` used it, replaced by `url_launcher`)

## State
- `flutter analyze`: 0 errors, 0 warnings, only info-level lint
- Debug APK builds successfully
- Release AAB blocked: user needs to generate `upload-keystore.jks` and fill `android/key.properties`

## Lint Conventions
- Always use `const` constructors where possible
- Use `.withValues(alpha:)` instead of deprecated `.withOpacity()`
- No unnecessary imports or unused variables
- Guard `BuildContext` usage across async gaps

## Relevant Files — Email Tracking
- `lib/presentation/profile/widgets/email_tracking_screen.dart`: Complete rewrite — `launchUrl()` + `app_links` stream + deep link handling
- `lib/core/services/email_tracking/email_connection_service.dart`: `oAuthRedirectUri` → `com.unipath.app://email_callback`
- `android/app/src/main/AndroidManifest.xml`: Added `com.unipath.app` scheme intent filter with `email_callback` host
- `pubspec.yaml`: Added `app_links: ^6.4.1`
