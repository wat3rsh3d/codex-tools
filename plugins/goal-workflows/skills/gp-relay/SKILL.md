---
name: gp-relay
description: Use when, and only when, the user explicitly invokes $gp-relay, exact $gp-relay 0, or $gp-relay with a completion hint in a saved Codex project, or when resuming a gp-relay chain.
---

# Project Goal Relay

Move unfinished work into fresh visible Codex tasks without overlapping execution. Read `references/protocol.md`; load `references/recovery.md` only after an error, ambiguity, callback, duplicate control, or re-entry. The v3 prompt is self-contained, so do not load `../gp/SKILL.md`.

## Enter or resume

Resolve one exact saved project/root/environment and call `get_goal`:

- v3 segment: continue its chain;
- v1/v2 segment: preserve its chain metadata and migrate the next segment to v3;
- blocked/complete ordinary goal or no goal: seed a new v3 chain from live evidence;
- active ordinary goal: require a real stop/cancel/supersede operation before successor creation. If unavailable, checkpoint, report `GOAL_STOP_UNAVAILABLE`, and create nothing.

Only the successor creates the next segment goal. In a managed chain, frozen chain metadata overrides invocation syntax; modifiers initialize new chains only.

One handoff creates one successor, but the chain is recurring. After verified `START`, the successor becomes the active segment and may relay again. Repeat until the completion boundary is verified or a genuine hard boundary leaves no safe work.

Modes:

- bare `$gp-relay`: next evidence-backed major milestone;
- exact `$gp-relay 0`: no overall completion boundary;
- `$gp-relay <hint>`: exact hint plus frozen observable gates.

## Continuous work

At each slice boundary, look one slice ahead for hard decisions. Default reversible/advisory choices, record them, and continue. Ask hard authorization questions early, park only dependent work, and drain primary, independent, then validation/documentation queues. User silence is not a blocker; block only when no meaningful safe work remains.

Relay at the first safe boundary after explicit invocation, explicit compaction/context warning, or four completed material-work turns since `START`. Count only turns that changed or validated project state - not readiness, recovery, waiting, or user-only turns. Reset the count after every verified `START`; never invent token math.

## Handoff kernel

1. Finish or unwind the atomic operation; validate and checkpoint the exact delta.
2. Create and title one successor with the v3 envelope, minimal `READY_PHASE`, and deferred `POST_START` work.
3. Verify its exact persisted title and assistant-authored `READY`; a matching callback wakes verification but proves nothing.
4. Stop the predecessor according to its goal class.
5. Send and verify one matching `START`. The successor starts once; duplicate controls are no-ops.

Ambiguity never authorizes a replacement successor. Rename, readiness, stop, and start failures preserve the same handoff for recovery. Do not navigate or archive.

Red flags: broad rediscovery before relay, deep work before `START`, fixed read-count failure, notification text as readiness, guessed token usage, blocking on a reversible preference, or recreating after ambiguity. Any red flag requires `references/recovery.md`.
