# How `gp` works

`gp` is a read-only continuation-prompt generator. It inspects the smallest useful set of current project evidence and returns one paste-ready prompt for a fresh Codex task. It does not execute project work, create a task, save a handoff file, or wrap the result in a `/goal` command.

## Modes

| Invocation | Completion boundary |
|---|---|
| `$gp` | The next evidence-backed major milestone |
| Exact `$gp 0` | No overall completion boundary; continue successive safe slices |
| `$gp <hint>` | The user's hint, translated into observable completion gates |

The zero mode is intentionally different from “do the next thing.” It tells the receiving task to continue after each green substep until no safe queue remains or a genuine hard boundary blocks all progress.

## Evidence workflow

1. Resolve the exact project root.
2. Read scoped repository instructions and the newest authoritative checkpoint or handoff first.
3. Reuse stable facts from that checkpoint and follow only the references needed for the next slice or a conflict.
4. Group cheap drift checks such as status, branch or detached state, and current revision.
5. Classify every relevant fact as current, historical, conflicting, or unresolved.
6. Select a primary slice, independent fallback work, and validation/documentation maintenance.
7. Return one continuation prompt with an explicit decision policy and stop conditions.

When no checkpoint exists, `gp` reads only enough governing material to select the first slice and requires the receiving task to create a checkpoint immediately after that slice validates.

## Output contract

The generated prompt is ordered so a fresh task can act without reconstructing the conversation:

1. objective, exact project root, and selected mode;
2. authority and read order;
3. verified resume state, unresolved facts, and prohibited assumptions;
4. primary, fallback, and maintenance work queues;
5. decision policy;
6. inspect/test/implement/validate/checkpoint loop; and
7. completion gates or safe-stop conditions.

The intended size is 450–800 words. It should exceed 1,200 words only when essential state cannot be referenced from the project.

## Decision policy

The receiving task may choose conservative, documented defaults for advisory or reversible local decisions. It must ask before destructive, external, credentialed, security/privacy-sensitive, irreversible, or scope-expanding actions. A pending question parks only dependent work; it does not stop independent safe work.

This separation prevents a long-running task from treating every preference as a gate while still preserving real approval boundaries.

## Benefits

- **Controlled context reset:** begins with current project truth instead of an accumulated conversation transcript.
- **Low operating overhead:** produces one prompt and makes no project changes.
- **Portable handoff:** the prompt can be reviewed, edited, or used in any new task attached to the same project.
- **Evidence-backed scope:** current checkpoints and live drift checks outrank stale chat history.
- **Resilient execution:** independent safe work remains available when one decision is blocked.
- **Honest boundaries:** unresolved facts stay unresolved rather than being reconstructed from memory.

## Current Codex integration notes

- The task must be able to read the project evidence needed to ground the prompt.
- The user manually creates or selects the fresh task and pastes the result.
- A weak or stale checkpoint reduces how compact the continuation can be; `gp` compensates with targeted live checks.
- Current Codex versions do not expose exact input-token utilization to the skill; `gp` instead grounds the next task from current project evidence.
- `gp` does not preserve every conversational nuance. It intentionally carries forward execution-relevant state.
- It does not authorize external writes or destructive work in the receiving task.

The installable source is in [`plugins/goal-workflows/skills/gp`](../plugins/goal-workflows/skills/gp/).
