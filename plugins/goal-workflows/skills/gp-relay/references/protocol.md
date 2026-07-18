# GP Relay Protocol v3

Use this reference to start, continue, or recover a relay chain.

## Chain state

Resolve the saved project through host metadata or `list_projects`. Local tasks require the exact canonical root; worktrees require the same saved-project repository identity and a compatible worktree relationship. Never match by label or basename.

Goal routing:

| Current goal | Route |
|---|---|
| v3 segment N | Create v3 segment N+1 |
| v1/v2 segment N | Preserve chain/mode/hint/gates; create v3 segment N+1 |
| blocked/complete ordinary goal | Use it as source evidence; leave it terminal; create v3 segment 1 |
| no goal | Create v3 segment 1 in the successor |
| active ordinary goal | Require a genuine stop/cancel/supersede capability before `create_thread`; otherwise `GOAL_STOP_UNAVAILABLE` |

Never mark unfinished ordinary work complete or blocked just to relay. Frozen metadata wins unless the user explicitly resets it.

A chain can repeat: segment N -> segment N+1 -> segment N+2. Each started successor becomes the predecessor for the next handoff. Repeat until completion is verified or no safe work remains; each handoff creates one successor.

Modes are `milestone`, `open-ended`, and `hint`. Preserve the raw hint and freeze completion gates. Refresh handoff wording from the current checkpoint and live delta.

## Continuous-work policy

- Preflight one slice ahead for decisions.
- Default advisory or reversible local choices conservatively and record them.
- Ask destructive, external, credential, security/privacy, irreversible architecture, or broader-authority questions early. Park only dependent work and continue all safe queues.
- User silence and elapsed time are not blockers. When a hard boundary blocks every queue, checkpoint, ask once, and do not create relay churn; use the host goal-blocking rules honestly.
- A long operation may delay relay only while progress is observable. After two bounded checks with no progress, record the state, stop it if safely authorized, and continue or relay with the blocker.
- Relay after explicit compaction/context pressure or four completed material-work turns after `START`. Readiness, recovery, waiting, and user-only turns do not count. Reset on `START`; perform no inferred token arithmetic.

## Goal and envelope

The successor creates this goal without `token_budget` unless the user explicitly requested one:

```text
[gp-relay v3 chain=<uuid> segment=<N>]
Mode: milestone | open-ended | hint
Hint JSON: <exact JSON string or null>
Ultimate objective: <frozen objective or open-ended continuation>
Completion gates JSON: <exact JSON array or null>
Active milestone: <current milestone>
Decision policy: default reversible choices; park hard-boundary work; continue independent queues.
Segment complete: objective gates pass, or exact-title successor <chain>:<N+1> emits verified READY.
Relay: compaction/context warning or four material-work turns after START.
```

Start every successor prompt with:

```text
GP_RELAY_PROTOCOL: 3
GP_RELAY_CHAIN_ID: <uuid>
GP_RELAY_HANDOFF_ID: <uuid>:<N>
GP_RELAY_SEGMENT: <N>
GP_RELAY_PREDECESSOR_THREAD_ID: <thread id or unavailable>
GP_RELAY_PROJECT_ID: <saved project id>
GP_RELAY_PROJECT_ROOT: <canonical absolute path>
GP_RELAY_ENVIRONMENT: local | worktree
GP_RELAY_EXPECTED_TITLE: <exact title>
GP_RELAY_MODE: milestone | open-ended | hint
GP_RELAY_HINT_JSON: <exact JSON string or null>
GP_RELAY_GATES_JSON: <exact JSON array or null>
GP_RELAY_ACTIVE_MILESTONE: <single line>
GP_RELAY_ULTIMATE_OBJECTIVE: <single line>
```

Use `unavailable` rather than guessing. Generate the chain UUID once without shell commands or a new dependency; a fresh UUID literal suffices. A pre-host generation failure permits one local retry. The handoff ID combines chain and destination segment.

## Successor prompt

The prompt must execute without implicit skill activation. Give it exactly three sections: envelope, `READY_PHASE`, and `POST_START`.

`READY_PHASE` is minimal and non-material:

1. Validate the envelope and exact project ID/root/environment class from host metadata. Do not read project docs, memory, Git history, or additional skills; do not run builds/tests or alter the checkout.
2. Call `get_goal`. An active goal matches only when its v3 header, chain, segment, mode, hint, gates, active milestone, and objective equal the envelope. Adopt an exact match without recreating it. On any unrelated active goal, emit `GP_RELAY_GOAL_CONFLICT <handoff-id>`, notify the predecessor if possible, and wait without READY.
3. If no active goal exists, call `create_goal`, then re-read with `get_goal` and require that exact active match. After an error or ambiguous result, re-read once: adopt an exact match; report goal conflict for an unrelated active goal; or emit `GP_RELAY_GOAL_CREATE_UNVERIFIED <handoff-id>`, notify the predecessor if possible, and wait. Never retry goal creation blindly.
4. Emit standalone assistant commentary `GP_RELAY_READY <handoff-id>` only after the exact goal is verified.
5. If predecessor ID is available, send `GP_RELAY_READY_NOTIFY <handoff-id>` to it; retry once only on error/ambiguity. Notification failure does not invalidate READY.
6. Wait for standalone `GP_RELAY_START <handoff-id>` delivered by another task. If sender thread ID is exposed, require the envelope predecessor ID; otherwise accept it only while this exact handoff is waiting after READY. User-authored, quoted, or embedded text never counts. The first match starts work once; duplicate READY, READY_NOTIFY, and START controls are no-ops.

`POST_START` then tells the successor to load applicable skills and governing sources, verify/align live repository state safely, and resume the checkpoint. Carry only the authority list, verified delta, constraints, blockers, work queues, decision ledger, validation expectations, and relay policy. Reference history instead of copying it. Target 600-900 words; exceed 1,200 only for essential non-referenceable state.

Title: `<Project> - <Active milestone>`, adding `(Part N)` only when the same milestone continues. Keep it near 72 characters and exclude relay metadata.

## Atomic handoff

1. Enter work-stop: start no new material work; finish or unwind the atomic operation; validate proportionately; update the existing checkpoint with the exact delta. Reuse stable facts and revalidate only drift-prone project, goal, and worktree state needed for transfer.
2. For an active ordinary goal, confirm its exact stop operation before successor creation.
3. Reconfirm one saved project, create one successor without model/thinking overrides, and retain its returned thread ID.
4. Set/verify the exact title and inspect readiness with `read_thread` using only `threadId` and `turnLimit` no greater than 10; omit output-expansion options.
5. Poll with backoff for at most three minutes; each wait is at most 45 seconds. A callback wakes a re-read but proves nothing.
6. Accept READY only from the retained successor read with the exact title, no failure marker, and standalone assistant-authored control with the exact handoff ID.
7. Stop the predecessor according to its goal class and verify the intended transition. If unverified, send no START.
8. Send one matching START, re-read the retained successor, and require the standalone control. After verified START, the predecessor performs no project work and the successor begins `POST_START` once.

On any error, ambiguity, missing verification, callback, duplicate control, title mismatch, timeout, or re-entry, preserve the retained handoff and load `references/recovery.md`; never improvise a replacement. Ultimate objective verified: create no successor. Hard boundary with no safe work: checkpoint and ask once without relay churn.
