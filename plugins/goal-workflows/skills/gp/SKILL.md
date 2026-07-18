---
name: gp
description: Use when the user invokes $gp, exact $gp 0, or $gp with a hint, or requests a paste-ready project continuation, restart, or handoff prompt.
---

# Goal Prompt

Return one paste-ready continuation prompt. Inspect evidence read-only; do not perform project work, save a handoff, or add a `/goal` wrapper.

## Mode

- `$gp`: complete the next evidence-backed major milestone.
- Exact `$gp 0`: continue through successive safe slices with no overall completion boundary.
- `$gp <hint>`: preserve the hint's intent and translate it into observable completion gates.

## Ground cheaply

1. Resolve the exact project root. If unclear, ask one targeted question and stop.
2. Read scoped `AGENTS.md` and the newest authoritative checkpoint or handoff first.
3. If current, reuse its stable facts and follow only links needed for the next slice or a conflict; do not rediscover history.
4. Group drift checks: status, branch or detached state, and `HEAD`. Inspect history, remotes, PRs, or CI only if the next work depends on them. After a read failure, try one minimal alternate path before marking cheap evidence unresolved.
5. Without a checkpoint, read only enough governing material to select a slice; require a checkpoint immediately after the first validated slice.
6. Classify facts as current, historical, conflicting, or unresolved; invent nothing.

Authority: current user instruction, governing docs, scoped `AGENTS.md`, live state, then historical handoffs.

## Prompt contract

Return one Markdown code block with no narration. Target 450-800 words; exceed 1,200 only when essential state cannot be referenced.

Structure the prompt in this order:

1. objective, exact project root, and mode;
2. short authority/read order;
3. verified resume state, unresolved facts, and prohibited assumptions;
4. work queues: primary slice, independent fallback work, then validation/documentation maintenance;
5. decision policy;
6. slice loop: inspect, test first where applicable, implement, validate, sync governing docs/checkpoint, inspect final state, select the next slice;
7. completion gates or safe-stop conditions.

Decision policy:

- For advisory or reversible local choices, select a conservative documented default and continue.
- For destructive, external, credential, security/privacy, irreversible, or scope-expanding choices, ask one concise question early, park only dependent work, and continue every independent safe queue item.
- An unanswered question or elapsed time is not itself a blocker. Stop only when no safe work remains, then checkpoint the exact resume boundary.
- Continue long operations only with observable progress. After two bounded no-progress checks, record state, stop safely if authorized, then continue a safe queue item or checkpoint the blocker.

Scan one slice ahead for hard decisions. Never repeat a question or turn a preference into an approval gate.

For `$gp`, stop after milestone gates pass. For hint mode, stop after translated gates pass. For `$gp 0`, never stop at a green substep, commit, checkpoint, or unanswered nonblocking preference; continue until every safe queue is exhausted or a genuine hard boundary blocks all progress. Preserve unrelated changes and make no unauthorized external writes.
