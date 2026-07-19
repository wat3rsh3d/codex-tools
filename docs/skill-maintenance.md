# Skill Maintenance

Skill Maintenance packages two explicit, read-only audits for understanding Codex skill installations and deciding where reusable workflow guidance belongs. It does not replace installed skills or modify their behavior.

## `skill-inventory-audit`

Use `$skill-inventory-audit` when a Codex installation has accumulated direct skills, plugin updates, duplicate names, or discovery metadata that deserves review.

The bundled standard-library Python helper reports four distinct surfaces:

| Surface | Evidence provided |
|---|---|
| Direct skills | `SKILL.md` files below the selected Codex home's `skills` directory |
| Plugin cache | Canonical skills below each cached version's top-level `skills` directory, grouped by marketplace, plugin, and version |
| CLI prompt | Skill names returned by `codex debug prompt-input`, plus the resolved executable and version when available |
| Usage | Optional counts of explicit `$skill-name` invocations |

Run the human-readable audit with:

```text
python scripts/audit_skill_inventory.py --codex-home <resolved-codex-home>
```

Add `--json` for structured local output. The current report uses schema version 2. Usage inspection is off by default and requires `--include-usage`; it returns aggregate invocation counts rather than task content.

The report identifies duplicate names, malformed frontmatter, and unusually large discovery metadata. These are review signals. The audit never deletes, moves, disables, installs, or rewrites a skill.

### Benefits

- Separates installed skill folders from versioned cache residue.
- Excludes fixture, example, test, and documentation skill trees that are not part of a cached plugin's canonical skill root.
- Attributes CLI prompt evidence to the exact Codex executable and version selected by the current PATH.
- Shows how much discovery metadata each skill contributes without loading complete skill bodies.
- Preserves useful filesystem findings when the CLI prompt surface is unavailable.
- Produces deterministic JSON suitable for local validation or before-and-after comparisons.
- Keeps cleanup and consolidation decisions human-reviewed.

## `project-skill-audit`

Use `$project-skill-audit` when a project repeats setup, recovery, validation, review, or handoff work and you want to know whether an existing skill should be reused, improved, or supplemented.

The audit resolves the exact project root, reads scoped `AGENTS.md`, README files, governing docs, checkpoints, validation commands, and project-local skill directories, then compares that evidence with the skills exposed to the current task. It ranks recommendations in this order:

1. reuse an existing skill whose contract already fits;
2. improve an existing skill with a precise portable addition; or
3. create a new skill only for a recurring, transferable workflow with a distinct trigger.

Recommendations include the evidence, expected benefit, exact scope, and a synthetic validation path. Facts are labeled as verified, inferred, or unavailable.

### Benefits

- Reduces duplicate skills and overlapping instructions.
- Converts repeated project friction into narrowly scoped reusable guidance.
- Keeps one-time architectural decisions in project docs instead of global skill catalogs.
- Uses indexed memory selectively when historical recurrence matters.
- Makes the basis for each recommendation auditable before implementation.

## Privacy and read boundaries

Both skills act locally and make no network requests. They do not change installed skills, plugin caches, Codex configuration, project files, memories, history, or sessions.

`project-skill-audit` may read `$CODEX_HOME/memories/MEMORY.md` when relevant and follows no more than one to three targeted references per audit pass. Raw session records require separate explicit user approval.

## Current Codex integration notes

- Desktop plugin injection, direct skill discovery, cached plugin versions, and CLI prompt construction can expose related but different views.
- `codex debug prompt-input` currently returns a JSON prompt representation; the inventory helper extracts the Available Skills section from its text fields.
- The inventory helper records the Codex executable and version selected by the current process PATH; it does not select or activate a different installation.
- A cached plugin version is recorded as cached evidence, not labeled active or obsolete.
- The current CLI prompt can contain fewer skills than the active Desktop task; both counts remain separate in the report.
- Both skills disable implicit invocation so their broader local inspection begins only after an explicit request.

## Provenance

`skill-inventory-audit` adapts the local inventory and metadata-budget ideas from Peter Steinberger's [`skill-cleaner`](https://github.com/steipete/agent-scripts/tree/49f5dfdc0e3020550c64ea5feb5ede16ad52d2c3/skills/skill-cleaner) into a Windows-compatible, report-only Python tool with separated Codex surfaces and opt-in usage signals.

`project-skill-audit` adapts Thomas Ricouard's [`project-skill-audit`](https://github.com/Dimillian/Skills/tree/05ba982bfeb0d77d3c97d4542b0ee15034d05f84/project-skill-audit) into a portable, explicit-only workflow with bounded memory lookup and a raw-session approval gate.

Both sources are MIT licensed. Copyright and pinned-source details are preserved in the repository's [third-party notices](../THIRD_PARTY_NOTICES.md) and the plugin's [license](../plugins/skill-maintenance/LICENSE.txt).
