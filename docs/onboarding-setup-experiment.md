# Onboarding setup-screen experiment

Use Firebase A/B Testing with the new `onboardingVariantv3AB` Remote Config parameter.
The bundled default remains `fullFlowAuthFirst`; deploying the code alone does not enable either treatment.

| Arm | Parameter value | Placement |
| --- | --- | --- |
| Control | `fullFlowAuthFirst` | No setup screen |
| Early | `setupBeforePersonalizedPicks` | After reviews, before personalized picks |
| Late | `setupBeforePaywall` | Before the paywall, after authentication when authentication is needed |

## Release setup

Leave the live `onboardingVariantv2` parameter unchanged for already-released app versions. This build reads `onboardingVariantv3AB` and defaults to `fullFlowAuthFirst` until the new parameter is configured.

- Target new onboarding journeys on an app version/build containing these enum values. Older builds do not support the new treatment values and must not enter the experiment.
- Allocate the eligible experiment population equally across the three arms. Keep other onboarding/paywall settings identical across arms, including `shouldRequestSKReviewInOnboardingAB`.
- Assignment is saved before onboarding starts and reused on resume. Existing persisted journeys retain their original variant and should be excluded from fresh-enrolment comparisons. For local QA, reset onboarding state before testing a forced `OnboardingVariant.current` value so a saved assignment does not take precedence.
- Launch the experiment separately in Firebase after release validation. No live Remote Config changes are made by this implementation.
- Returning Remote Config to `fullFlowAuthFirst` ends new treatment assignments; already-persisted treatment journeys keep their assignment until onboarding state is reset.

Set `shouldRequestSKReviewInOnboardingAB` to `false` to disable the native review request while retaining the credibility/reviews screen in all three experiment arms. This flag controls only the native prompt; it does not remove the reviews screen. Full-length legacy variants retain the reviews screen too; abbreviated variants keep their existing shortened flows.

`allowSKReviewOnFirstLaunch` defaults to `true` in both apps. It allows native review requests on the first app launch, subject to the other review checks. Set it to `false` to block first-launch requests while keeping the reviews screen visible. During onboarding, `shouldRequestSKReviewInOnboardingAB` must also be `true`. Keep both settings identical across experiment arms.

## Title copy

The shared setup-screen headline uses the `onbSettingEverythingUpTitle` Remote Config string. Its bundled default is `We’re setting everything||up for you`. The existing `RCValues.string(forKey:)` helper converts `||` to a newline. Use this parameter for a future title-copy experiment; keep it identical across both placements while testing placement alone.

## Measurement

Compare subscription conversion per assigned onboarding start, using `newOnboardingCompleted` with `did_subscribe` and the existing subscription/paywall events. Compare onboarding completion and paywall reach as supporting measures. Use the resolved `variant` on onboarding start/completion to attribute the actual journey; do not treat loader exposure as assignment, since earlier drop-off differs by placement.

The new `onbSettingEverythingUpScreenViewed` and `onbSettingEverythingUpCompleted` events both include `variant`. The latter records automatic advancement after the final hold. Compare these events to investigate setup-screen drop-off. A forward revisit can create another exposure; deduplicate by user/journey when calculating conversion. Back navigation skips the loader. Resume follows the existing pass-through-step rules and does not force an interrupted loader to replay.

The loader is cosmetic. It does not create accounts, generate recommendations, change library data or alter the personalized-picks animation. Both treatments use the same nine seconds of active viewing time. Background time is excluded. The late loader is omitted when the paywall is removed for an existing subscriber.

## Validation

Run `FreeAudiobooksTests` with the focused `SettingEverythingUpScheduleTests` and `SettingEverythingUpFlowTests` suites on `platform=iOS Simulator,name=iPhone Air,OS=latest`, with parallel testing disabled to avoid simulator clones. The UI fixture attaches images for both placements in light/dark mode and an accessibility text size. Verify Reduce Motion on the same existing iPhone Air and check that automatic progression still works.

## FreeAudiobooks port

The six source commits are `35d57e8`, `1e863c1`, `9b8093b`, `351f86e`, `37756e5`, and `bdf8f0c`. Listening questions, orange brand colours, the existing auth-before-paywall default, and the legacy variants are preserved. Setup copy uses listening terminology. The first-launch review control is named `allowSKReviewOnFirstLaunch`. The native onboarding prompt remains controlled by `shouldRequestSKReviewInOnboardingAB`. The commented testing sign-out line now sits after Superwall and the other launch services are configured.

The reauthentication port verifies identity before account cleanup. Despite the final source commit’s title, it still deletes Firestore before Firebase Auth after verification; no server-side deletion or atomic cleanup was introduced.

FreeAudiobooks uses `fullFlowAuthFirst` as both the bundled default and control (FreeBooks uses `fullFlow`). Both treatments are derived from that control. The legacy `fullFlow` value retains its paywall-before-authentication order.
