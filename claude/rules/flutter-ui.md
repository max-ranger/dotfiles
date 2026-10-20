---
paths:
  - "**/lib/**/*.dart"
---
# Flutter mobile UI

Adapted from expo/skills (MIT), rewritten for Flutter. Motion lives in `emil-design-eng`, visual audits in `impeccable`.

- Touch targets at least 44pt on iOS and 48dp on Android. Grow the hit area, not the visual.
- Insets come from `Scaffold`/`AppBar`, else `SafeArea`. Never hardcode a status bar or home indicator height.
- The focused field and its submit button stay above the keyboard (`MediaQuery.viewInsetsOf`, scrollable forms).
- Use the platform header (`SliverAppBar.large`, `CupertinoSliverNavigationBar`). A hand-built header loses back-swipe and large-title behaviour.
- Prefer bottom sheets with a drag handle over centred dialogs. Alerts only for irreversible actions; otherwise act and offer undo in a SnackBar.
- Each platform gets its own idiom (`.adaptive` widgets): no FAB on iOS, no trailing chevrons on Android, one icon family per platform, no emoji as icons.
- Use the platform tab bar with a fixed set of tabs. Re-tapping the active tab pops to its root, and switching tabs doesn't slide.
- Widgets take colours from the theme's `ColorScheme`, never raw hex. Brand colours ship as light and dark pairs.
- Never clamp `textScaler` app-wide. Rows get a minimum height, not a fixed one, so large text still fits.
- Loading is not empty. A refresh keeps the old data visible and offers retry, and a failed save keeps the user's draft.
- Haptics fire in the same frame as the visual change (`selectionClick` for steps, `lightImpact` for commits) and are never the only feedback.
- Grouped lists over a card per row. Spacing grows from row to group to section.
- A screen is done only after trying long text, empty results, the largest text size, the open keyboard, back navigation and a failed save.
