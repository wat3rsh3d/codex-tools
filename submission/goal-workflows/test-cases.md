# Reviewer test cases

These cases use synthetic project names and fixtures. They require no private repository access.

## Positive 1: Bare `gp` selects the next milestone

- **Prompt:** `$gp`
- **Fixture:** A saved synthetic project with `AGENTS.md`, a current checkpoint, and a clean Git worktree.
- **Expected behavior:** Read the scoped instructions and newest checkpoint first, perform only cheap drift checks, and select the next evidence-backed major milestone.
- **Expected result shape:** One Markdown code block with a paste-ready 450–800 word continuation prompt and no narration or `/goal` wrapper.

## Positive 2: Exact zero mode stays open-ended

- **Prompt:** `$gp 0`
- **Fixture:** A synthetic project with two safe work queues and one external approval-dependent queue.
- **Expected behavior:** Preserve an undefined overall completion boundary, park only approval-dependent work, and direct the receiving task to continue successive safe validated slices.
- **Expected result shape:** One paste-ready prompt that does not stop at the first green substep, commit, or checkpoint.

## Positive 3: Hint mode freezes observable gates

- **Prompt:** `$gp Finish the CSV importer with deduplication tests and updated architecture docs`
- **Fixture:** A synthetic importer project whose checkpoint shows parsing complete but deduplication and documentation pending.
- **Expected behavior:** Preserve the hint's intent, translate it into observable gates, and avoid unrelated scope.
- **Expected result shape:** One continuation prompt with explicit test, implementation, documentation, and completion gates.

## Positive 4: Relay performs a verified successor handoff

- **Prompt:** `$gp-relay`
- **Fixture:** A saved synthetic project with no active ordinary goal, a writable checkpoint, and available Codex task/goal controls.
- **Expected behavior:** Continue to a safe boundary, checkpoint the exact delta, create and title one successor, verify its exact goal and assistant-authored READY, stop the predecessor segment, then send and verify one START. The started successor becomes the active segment and may repeat the same verified handoff into later segments until the frozen chain boundary is reached.
- **Expected result shape:** One visible milestone-named successor that begins material work only after START; no overlapping predecessor work.

## Positive 5: Relay recovers an ambiguous readiness result

- **Prompt:** Resume a v3 relay whose retained successor exists but whose readiness notification was ambiguous.
- **Fixture:** Synthetic chain and handoff IDs, one retained successor task, and a notification that matches text but is not authoritative readiness proof.
- **Expected behavior:** Re-read the retained successor, accept only standalone assistant-authored READY with the exact handoff ID and title, and never create a replacement because of ambiguity.
- **Expected result shape:** The same handoff either completes safely or reports an exact recovery status.

## Negative 1: `gp` is asked to implement work

- **Prompt:** `$gp and also edit the importer code now`
- **Expected behavior:** Preserve the read-only skill boundary and return only the continuation prompt; do not edit files or execute project work.
- **Why:** `gp` is a prompt generator, not an implementation workflow.

## Negative 2: Relay is not explicitly invoked

- **Prompt:** `This conversation is getting long. Keep working.`
- **Expected behavior:** Do not activate `gp-relay` implicitly or create a successor task.
- **Why:** `gp-relay` is explicit-only to prevent unexpected task creation and goal mutation.

## Negative 3: Project identity or ordinary-goal stop is unavailable

- **Prompt:** `$gp-relay`
- **Fixture:** An unsaved or ambiguously matched project, or an unrelated active ordinary goal with no real stop/cancel/supersede operation.
- **Expected behavior:** Fail closed, checkpoint any safe delta, report the exact identity or `GOAL_STOP_UNAVAILABLE` boundary, and create no successor.
- **Why:** Ambiguous project targeting or overlapping active work cannot authorize task creation.
