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

## Other Features
- Privacy Policy + Terms of Service screens
- Biometric auth with auto-login
- Smart notification permission (post-onboarding/login)
- App rating prompt (after 3 positive actions, 7-day cooldown)
- Pull-to-refresh Email tracking

## State
- `flutter analyze`: 0 errors, 0 warnings, only info-level lint
- Debug APK builds successfully
- Release AAB blocked: user needs to generate `upload-keystore.jks` and fill `android/key.properties`

## Lint Conventions
- Always use `const` constructors where possible
- Use `.withValues(alpha:)` instead of deprecated `.withOpacity()`
- No unnecessary imports or unused variables
- Guard `BuildContext` usage across async gaps
