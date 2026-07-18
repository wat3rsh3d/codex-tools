---
name: project-skill-audit
description: Use when a project repeats workflows, carries project-local Codex instructions or skills, or needs evidence-backed decisions about reusing, improving, or creating skills without duplicating existing capability.
---

# Project Skill Audit

## Overview

Compare recurring project work with the skills already available, then recommend the smallest reusable improvement. Ground every conclusion in current project evidence and keep inspection read-only.

## Evidence pass

1. Resolve and report the exact project root. Do not assume a saved workspace, repository name, or parent directory is the active root.
2. Read the scoped `AGENTS.md`, `README` files, governing docs, current checkpoints, and validation commands that explain repeated work.
3. Inventory project-local skill roots when present: `.agents/skills`, `.codex/skills`, and `skills/`. Also inspect the skill catalog exposed to the current task before proposing new capability.
4. Identify workflows that recur across checkpoints, review feedback, recovery steps, or repeated commands. Distinguish a reusable pattern from a one-time project decision.
5. Label each material fact as `verified`, `inferred`, or `unavailable`. Cite the file or command that supports verified facts.

## Memory boundary

Use `$CODEX_HOME/memories/MEMORY.md` only when it exists and the project evidence indicates historical recurrence matters. Follow one to three targeted memory or rollout references per audit pass. Stop when they answer the recurrence question; do not broadly scan the memory tree.

Require explicit user approval before reading raw session records. Approval to inspect project files or the memory index is not approval to inspect raw sessions. Never hardcode a user home path.

## Decision policy

Rank recommendations in this order:

1. **Reuse** an existing skill when its current contract already covers the workflow.
2. **Improve** an existing skill when a precise, portable addition closes the evidenced gap.
3. **Create** a new skill only when the workflow recurs, transfers beyond one project, has a distinct trigger, and is not already covered.

Do not recommend a skill for mechanical checks better enforced by a deterministic validator. Do not modify skills, project files, memories, sessions, or Codex configuration during the audit. Do not make network requests.

## Output contract

Lead with a brief verdict, then use this table:

| Recommendation | Evidence | Benefit | Scope | Validation |
|---|---|---|---|---|
| Reuse, improve, or create | Verified sources plus any labeled inference | Concrete reduction in repeated work or context | Exact skill and bounded change | Synthetic test or observable check |

After the table, list evidence that remained unavailable and any current Codex integration notes that affect interpretation. Separate recommendations from implementation authorization.

## Common mistakes

- Treating a long instruction file as proof that a new skill is needed.
- Searching raw sessions before scoped docs and indexed memory.
- Inventing usage frequency when historical evidence is unavailable.
- Recommending a duplicate because project-local and installed skill roots were not compared.
