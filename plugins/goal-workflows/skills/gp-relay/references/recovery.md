# GP Relay v3 Recovery

Load this reference only after an error, ambiguity, missing verification, callback, duplicate control, title mismatch, timeout, unrelated input during transfer, or handoff re-entry. Retain the same chain, handoff ID, and successor. Title alone never proves identity, and ambiguous success never authorizes replacement.

## Goal establishment

- An active successor goal matches only when its v3 header, chain, segment, mode, hint, gates, active milestone, and objective match the envelope. Adopt an exact match without recreating it.
- On an unrelated active goal, emit `GP_RELAY_GOAL_CONFLICT <handoff-id>`, notify the predecessor if possible, and wait without READY.
- After `create_goal` errors or returns ambiguously, re-read once. Adopt an exact match; report goal conflict for an unrelated active goal; or emit `GP_RELAY_GOAL_CREATE_UNVERIFIED <handoff-id>`, notify, and wait. Never retry goal creation blindly.

## Successor identity

- After an explicit confirmed `create_thread` failure, scan recent prompts for the exact handoff, predecessor, and project IDs. Adopt one exact candidate, report `CREATION_UNRESOLVED` on multiple, or retry once with the identical prompt and handoff when none exist. After that retry, adopt one exact scanned candidate or report `CREATION_UNRESOLVED`; re-entry never resets the retry budget.
- After an ambiguous result or missing authoritative ID, scan those identifiers and adopt exactly one. With zero or multiple candidates, report `CREATION_UNRESOLVED` and never recreate.
- Verify `thread.title` through `read_thread`; retry rename once on the retained ID, then report `RENAME_UNVERIFIED`.

## Readiness and callback

- Every critical `read_thread` call uses only `threadId` and `turnLimit` no greater than 10; omit output-expansion options. Poll at most three minutes, with waits no longer than 45 seconds. With a valid callback route, end as `HANDOFF_PENDING`; a late notification resumes this retained handoff. Without one, report `READY_MONITOR_EXPIRED`.
- If host metadata exposes sender thread ID, a callback must name the retained successor. Otherwise it is wake-only. Always re-read that successor; notification text is never READY evidence.
- Accept only standalone assistant-authored READY with the exact ID, exact title, and no failure marker. Goal-conflict or goal-create-unverified ends polling with that status and never authorizes stop or START.

## Idempotent stop and start

- Before stopping, check for an already-verified matching START. If present, the handoff is committed; do nothing else.
- Otherwise complete an active matching managed segment once; treat that segment already complete as stopped; leave blocked/complete source or no-goal state unchanged; or use the prevalidated stop operation for an active ordinary source. Re-read goal state when available. Without a verified intended transition, send no START.
- Send START once, inspect, retry once only if absent or ambiguous, then inspect again. Accept only the standalone exact control delivered by this predecessor operation. If absent, report `START_UNVERIFIED`; never send a third time or create a replacement.
- Duplicate READY, READY_NOTIFY, and START controls are no-ops. After verified START, only the successor may resume project work.

## Interruption and terminal boundaries

Unrelated user input does not reset recovery or authorize replacement. Address compatible input, then resume the retained handoff. Only explicit cancel or replacement ends it, after recording exact state.

Unresolved project identity, unsafe checkpoint, destructive authority gap, unavailable credentials/private data, or governing conflict fails closed with the exact resume boundary.
