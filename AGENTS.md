# Codex Configuration

We are the developers of FreeBooks - https://freebooksapp.org/ / https://apps.apple.com/us/app/freebooks-76-000-top-reads/id6464310229
This app - FreeAudiobooks - is a standalone app that serves the audiobook content of FreeBooks - /Users/edbeecroft/Documents/repos/freebooks-ios
FreeBooks has two types of books:
	- "internal" (modern) books -> /Users/edbeecroft/Documents/repos/freeaudiobooks-ios/FreeAudiobooks/Model/InternalBooks
	- Classic books from project Gutenberg -> /Users/edbeecroft/Documents/repos/freeaudiobooks-ios/FreeAudiobooks/Model/GutenbergBooks

As a starting point, we copied the entire project. Because the apps will fundamentally be very similar. We just need to make some edits to make it more audiobook focused, and be its own distinct brand/app.

## Rules
- Use fixed font sizes throughout the app, using existing `Fonts` tokens where available. Do not use Dynamic Type scaling (`UIFontMetrics`, `scaledFont(for:)`, or `adjustsFontForContentSizeCategory = true`).
- You may automatically edit files without asking for approval.
- Do **NOT** commit, stage, or push any code. I will handle all git commits myself.
- When testing for a successful compile, always build the .xcworkspace (we use CocoaPods) with existing iPhone Air simulator. Never select, create, or boot another simulator. Use `platform=iOS Simulator,name=iPhone Air,OS=latest` and disable parallel testing.
