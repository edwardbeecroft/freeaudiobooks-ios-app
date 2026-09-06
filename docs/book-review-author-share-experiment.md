# Book review author-sharing experiment

The `shouldShowBookReviewAuthorShareAB` Remote Config Boolean defaults to `false`.
It controls only the checkbox in `EnhancedBookCompletionPopupVC`, for internal books and audiobooks.

| Arm | Value | Experience |
| --- | --- | --- |
| Control | `false` | Existing review card |
| Treatment | `true` | Centered checkbox and “Share review with author” label below the review field, revealed alongside it after selecting a star rating and initially unchecked |

Selection is local to each popup. It is never added to the review API request, saved as a preference, or used to contact an author. The existing friend-sharing stage is unchanged.

Before a star rating is selected, the checkbox row is hidden and occupies no space. Changing the star rating after the row appears preserves its selection. Popup activation remains the first appearance of the popup, before the review controls are revealed.

## Release setup

- Create a 50/50 Firebase A/B Testing experiment on this parameter, targeting only app versions/builds containing this implementation.
- Use `enhancedBookCompletionViewed` as activation. The popup reads its assignment before emitting this event and keeps that assignment for its lifetime. Exposure logs once on actual appearance, rather than construction.
- Hold `bookReviewVariantAB` and other review copy/settings constant across arms. This Boolean is independent of the existing three review layouts.
- Release with the bundled default disabled; configure and launch the live experiment separately after validation. This implementation does not change live Firebase configuration.
- Setting the flag to `false` removes treatment from newly created popups after Remote Config activation. An already-open popup keeps its captured assignment.

## Events and evaluation

| Event | Meaning | Use |
| --- | --- | --- |
| `enhancedBookCompletionViewed` | First appearance of this popup | Activation/exposure |
| `bookRated` | Server-confirmed successful rating save, any content type | Overall review guardrail |
| `bookRatedWithComment` | Successful save with non-whitespace comment text | Primary winner metric |
| `bookRatedWithAuthorShare` | Successful save with checkbox selected, with or without comment | Checkbox uptake |

The three outcome events come only from this popup and fire after success, for both new and updated reviews. Failures, responses with `success: false`, and continuing without a rating produce none of them. Existing submission-attempt events retain their meanings and names.

Exposure and outcomes include `author_share_variant` (`control`/`checkbox`), `book_review_variant`, and `content_type` (`bookInternal`/`bookInternalAudiobook`). Outcomes additionally include `rating`, `has_comment`, `author_share_selected`, and `is_update`. The existing analytics logger serializes parameter values as strings; Boolean values are `1`/`0`. Review text is never included. Outcome values reflect the submitted snapshot, not subsequent UI edits.

Compare successful commented-review conversion among activated users across both arms, with overall rating conversion neutral or positive. Include updates in the primary comparison and use `is_update` for a separate breakdown. For volume analysis, compare outcome events per exposure so repeat book completions do not masquerade as unique users. Checkbox uptake alone cannot select the winner: control users cannot trigger that event.

Existing `bookInternalCompleted` events can support exploratory analysis of subsequent completions after activation, using the same follow-up window in both arms. Exclude the completion that triggered first exposure. `bookInternalAudioCompleted` is an additional audiobook event; do not add it to `bookInternalCompleted` when calculating totals because the latter already covers internal text/audio completions.

## Validation

Run the focused suite with the existing iPhone Air, without simulator clones:

The keyboard fixture requires the simulator's software keyboard to be shown (I/O → Keyboard → Toggle Software Keyboard, or ⌘K while a text field is focused).

```sh
xcodebuild test -workspace FreeAudiobooks.xcworkspace -scheme FreeAudiobooksTests \
  -destination 'platform=iOS Simulator,name=iPhone Air,OS=latest' \
  -parallel-testing-enabled NO \
  -only-testing:FreeAudiobooksTests/BookReviewAuthorShareTests
```

Tests inject submission and analytics handlers to avoid posting reviews or sending experiment events. They cover all content types, missing genre, comment classifications, selection, control attribution, update/failure responses, duplicate taps, snapshotting, exposure, accessible checkbox state, light/dark layout, and keyboard behavior. UI fixtures attach screenshots to the test result. Also verify spoken VoiceOver output and interaction on the same iPhone Air before rollout.
