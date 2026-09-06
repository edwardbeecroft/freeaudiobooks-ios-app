# Book completion Send button experiment

Use the `bookCompletionShareButtonVariantAB` Remote Config string:

| Arm | Value | Button |
| --- | --- | --- |
| Control | `original` | Send |
| Treatment 1 | `originalWithShareIcon` | Custom send icon followed by Send |
| Treatment 2 | `shareWithShareIcon` | SF `square.and.arrow.up` icon followed by Share |

The bundled default and unknown-value fallback are `original`. The two `original` variants use the existing `bookCompletionShareButtonTitleAB` setting; its bundled fallback is `Send`. Hold that title setting constant across arms. `shareWithShareIcon` explicitly uses `Share`.

The Send icon uses the bundled `send-book.png` at 18 × 18 points. The Share icon uses SF `square.and.arrow.up` with medium weight, rendered at a fixed 18-point height with its aspect ratio preserved. Both icons render at the display's native scale and tint to match the title. The icon and title are centered together with a 6-point gap. The button retains its existing font, border, dimensions, and share-sheet action. The popup captures the variant at initialization.

Configure a three-arm Firebase A/B experiment with an even traffic split targeting a release containing this enum. Use existing `enhancedBookCompletionShareViewed` for activation, `enhancedBookCompletionShareCompleted` for the primary goal, and `enhancedBookCompletionShareTapped` / `enhancedBookCompletionShareSkipped` as supporting measures. Keep review-layout and author-sharing settings constant across arms.

No new events or changes to the sharing flow are needed. The code defaults to control; launching or stopping the experiment is a separate Firebase configuration change. Returning the parameter to `original` takes effect for newly created popups after Remote Config activation.

The existing `BookReviewAuthorShareTests` layout fixture covers all three button variants in light and dark mode on the existing iPhone Air simulator and attaches screenshots. Run it with parallel testing disabled using `platform=iOS Simulator,name=iPhone Air,OS=latest`.
