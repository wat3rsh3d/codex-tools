---
name: skill-inventory-audit
description: Use when a Codex installation may have skill inventory drift, duplicate skill names, oversized metadata, cached plugin copies, or differences between direct skills, plugin caches, and model-visible prompt surfaces.
---

# Skill Inventory Audit

## Overview

Map local Codex skill surfaces without changing them. Treat direct installs, cached plugin versions, and the CLI prompt inventory as separate evidence; a cached copy is not proof that a skill is active.

## Run the audit

1. Resolve the selected Codex home. Use `$CODEX_HOME` when set; otherwise use the platform's normal `.codex` directory.
2. Run the bundled helper with an available Python 3 interpreter:

   ```text
   python scripts/audit_skill_inventory.py --codex-home <resolved-codex-home>
   ```

3. Add `--json` only when structured output will help another local check.
4. Add `--include-usage` only when the user explicitly asks for recent usage signals. This option counts explicit skill invocations without returning task content.

## Interpret the surfaces

| Surface | Meaning |
|---|---|
| Direct | Skill folders discovered below the selected Codex home's `skills` directory |
| Plugin cache | Versioned local cache copies grouped by marketplace, plugin, and version |
| CLI prompt | Skill names observed through `codex debug prompt-input`, when that command is available |
| Usage | Optional counts of explicit `$skill-name` invocations in local history records |

Use duplicate findings to identify review candidates, not deletion candidates. Compare descriptions and origins before recommending consolidation. Treat large metadata estimates as opportunities for concise discovery text, not proof of a problem.

## Report contract

Return, in order:

1. a one-sentence verdict;
2. counts for each inventory surface;
3. evidence-backed duplicate, malformed-metadata, and metadata-size findings;
4. current Codex integration notes; and
5. optional next actions ranked by value and reversibility.

Label unavailable surfaces directly. Do not infer activation, usage, or obsolescence from cache presence alone.

## Read-only boundary

The audit is advisory. Do not delete, move, disable, install, or rewrite skills. Do not alter plugin caches, Codex configuration, history, sessions, or project files. Do not make network requests. Ask for separate authorization before acting on any recommendation.

## Current Codex notes

- Desktop plugin injection and CLI prompt construction can expose different inventories.
- Multiple cached versions can be normal update residue and should remain grouped as cached evidence.
- If `codex debug prompt-input` is unavailable, preserve the filesystem findings and note that surface as unavailable.
