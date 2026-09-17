# PLAN: Smart Adaptive HUD Positioning (Option D)

## Scope
Resolve HUD occlusion when inspecting bottom navigation bars, floating action buttons, and bottom sheets by automatically positioning `GrabHud` away from the target widget, with manual flip controls and gesture support.

## Tasks
1. [ ] Convert `GrabHud` to `StatefulWidget` and implement adaptive top/bottom coordinate calculation based on `candidate.bounds` vs `screenHeight` — **Verify**: When a widget in the lower 50% is selected, HUD top is set, bottom is null.
2. [ ] Integrate `AnimatedPositioned` with safe area padding (`MediaQuery.paddingOf(context)`) — **Verify**: HUD smoothly animates into place and stays clear of notches / home indicators.
3. [ ] Add manual flip button (↕) and vertical swipe gesture to HUD header — **Verify**: Clicking flip button or vertical swipe moves HUD to the opposite side.
4. [ ] Write widget tests for top/bottom placement and manual flip interaction — **Verify**: `flutter test` passes 100%.

## Risks & Considerations
- Safe area heights differ between devices (Dynamic Island vs home button vs Android navigation bar). Using `MediaQuery.paddingOf(context)` prevents any clipping.
- Resetting manual override on candidate change ensures each newly selected widget gets optimal positioning automatically.
