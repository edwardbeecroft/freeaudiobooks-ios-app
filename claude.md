# Claude Configuration

## Rules
- Use fixed font sizes throughout the app, using existing `Fonts` tokens where available. Do not use Dynamic Type scaling (`UIFontMetrics`, `scaledFont(for:)`, or `adjustsFontForContentSizeCategory = true`).
- You may automatically edit files without asking for approval.
- Do **NOT** commit, stage, or push any code. I will handle all git commits myself.
- When testing for a successful compile, always build the .xcworkspace (we use CocoaPods) with existing iPhone Air simulator. Never select, create, or boot another simulator. Use `platform=iOS Simulator,name=iPhone Air,OS=latest` and disable parallel testing.
