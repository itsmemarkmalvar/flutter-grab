# PLAN: PiP Edge Tuck & Multi-Drag Selection

## Scope
Implement freeform 2D dragging for the HUD, video-call-style edge tucking (minimizing to a side tab for 100% screen visibility), and Multi-Drag batch selection for bundling multiple widgets into a single AI prompt.

## Tasks
1. [ ] Extend `AiPromptFormatter` with `formatMultiple(List<GrabResult>)` — **Verify**: Formats markdown block with numbered widgets.
2. [ ] Extend `GrabController` with batch queue management (`multiSelectedCandidates`, `addToBatch`, `removeFromBatch`, `clearBatch`) — **Verify**: Controller manages batch and outputs combined context on copy.
3. [ ] Upgrade `GrabHud` to support freeform 2D dragging with `GestureDetector` — **Verify**: HUD follows drag gestures across the screen.
4. [ ] Implement PiP edge-tuck mode in `GrabHud` — **Verify**: Flicking or tapping tuck button minimizes HUD to a slim side pill; tapping pill restores full HUD.
5. [ ] Add Multi-Grab batch tray to `GrabHud` — **Verify**: Dev can queue multiple widgets and copy all at once.
6. [ ] Write unit & widget tests covering edge tuck, freeform drag, and multi-selection — **Verify**: `flutter test` passes 100%.

## Constraints
- **Do NOT publish to pub.dev or npm** until the user explicitly tests and approves.
