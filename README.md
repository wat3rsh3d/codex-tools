# Codex Tools

A Codex marketplace with three independently installable plugins containing five skills.

## Install

```powershell
codex plugin marketplace add wat3rsh3d/codex-tools --ref main
```

Refresh the ChatGPT desktop app, open the Plugins Directory, select **Codex Tools by watershed**, and install the plugin that contains the skill you want.

## What's included

The repository is the marketplace. You install a plugin from it, then invoke one of that plugin's skills.

```text
Codex Tools marketplace
|-- Goal Workflows plugin
|   |-- gp skill
|   `-- gp-relay skill
|-- Draw.io Diagrams plugin
|   `-- drawio-skill skill
`-- Skill Maintenance plugin
    |-- Skill Inventory Audit skill
    `-- Project Skill Audit skill
```

### Goal Workflows plugin

Install Goal Workflows when you want to move project work into fresh Codex tasks without losing the evidence needed to continue.

**Benefits**

- Fresh working context without losing validated project state.
- Long-running work can rotate through as many topic-named successor tasks as needed.
- Verified handoffs prevent overlapping project work and preserve evidence.

**Included skills**

- **`gp` skill** — build one paste-ready goal prompt for a fresh task. Invoke `$gp`, `$gp 0`, or `$gp <hint>`.
- **`gp-relay` skill** — continue long-running work through a recurring chain of verified, topic-named successor tasks. Invoke `$gp-relay`, `$gp-relay 0`, or `$gp-relay <hint>`.

See [Goal Workflows in practice](#goal-workflows-in-practice), [the full `gp` contract](docs/gp.md), and [the full recurring relay protocol](docs/gp-relay.md).

### Draw.io Diagrams plugin

Install Draw.io Diagrams when you want Codex to plan, generate, validate, and export an editable diagram.

**Benefits**

- Editable source remains available for future changes.
- Composition, structure, and rendered output are checked before delivery.
- One workflow supports reusable styles and common export formats.

**Included skills**

- **`drawio-skill` skill** — create architecture, UML, ER, network, process, or code-structure diagrams and export PNG, SVG, PDF, or JPG. Ask Codex for a draw.io diagram.

See [Draw.io skill details and provenance](docs/drawio-skill.md).

### Skill Maintenance plugin

Install Skill Maintenance when you want explicit, read-only audits of your Codex skills or recurring project workflows. It is one plugin containing two separate skills.

**Benefits**

- Separate direct skills, cached plugin versions, and model-visible inventory.
- Prefer reuse or improvement before creating redundant skills.
- Read-only, explicit audits keep inspection controlled and reviewable.

**Included skills**

- **Skill Inventory Audit skill (`skill-inventory-audit`)** — map direct skills, versioned plugin-cache copies, and the CLI model-visible prompt inventory. Invoke `$skill-inventory-audit`.
- **Project Skill Audit skill (`project-skill-audit`)** — identify recurring project workflows that should reuse, improve, or become skills. Invoke `$project-skill-audit`.

Neither skill makes network requests or changes files. Usage inspection and raw-session inspection remain separately approval-gated. See [Skill Maintenance details](docs/skill-maintenance.md).

## Goal Workflows in practice

Goal Workflows establishes a fresh task with a deliberately selected working set from governing documents, checkpoints, live project state, validation results, decisions, and blockers.

### `gp`: prepare a fresh-task prompt

`gp` inspects the current project and returns one paste-ready Markdown prompt. It does not create the task or perform project work.

| Command | Completion boundary |
|---|---|
| `$gp` | The next evidence-backed major milestone |
| `$gp 0` | Open-ended continuation with no overall completion boundary |
| `$gp <hint>` | The exact requested outcome, expressed as observable completion gates |

You create a fresh task and paste the result.

### `gp-relay`: run a recurring task chain

`gp-relay` automates verified handoffs between visible, topic-named Codex tasks:

```text
Task A / segment 1
  -> verified handoff -> Task B / segment 2
  -> verified handoff -> Task C / segment 3
  -> ...
```

Each handoff creates exactly one successor. After that successor verifies the goal and receives `START`, it becomes the active segment and can relay again. The cycle continues through as many successor tasks as needed until the chain's completion boundary is verified or a genuine hard boundary leaves no safe work.

For every handoff, the active task:

1. finishes or safely unwinds its current operation;
2. validates and checkpoints the exact delta;
3. creates one successor with a topic-aware title;
4. verifies the successor's exact goal and `READY` signal;
5. stops its own segment; and
6. sends one verified `START` signal.

The READY/START handshake prevents predecessor and successor tasks from doing project work simultaneously. Ambiguous results retain the same successor for recovery instead of creating duplicates.

| Command | Chain boundary |
|---|---|
| `$gp-relay` | The next evidence-backed major milestone |
| `$gp-relay 0` | Open-ended continuation through as many successor tasks as needed |
| `$gp-relay <hint>` | The exact requested outcome, frozen as observable completion gates |

### Relationship to compaction

Compaction summarizes older turns so one task can continue. Goal Workflows instead starts a fresh task with a deliberately selected working set. Codex continues managing its own context while these skills establish explicit project boundaries, topic-aware task names, and auditable continuation state.

## Current Codex interaction notes

- `gp-relay` runs only after explicit invocation in a saved Codex project.
- It responds to host context warnings and bounded material-work turns; current Codex versions do not expose an exact live token meter to the skill.
- Successors are created in the background and remain visible in the sidebar without being auto-opened.
- Titles come from the active project milestone. True nested topic placement is the subject of the included [OpenAI feature request](FEATURE_REQUEST.md).
- An exact handoff may update an existing project checkpoint.

## Proposed Codex improvement: nested tasks

The included [feature request](FEATURE_REQUEST.md) proposes collapsible topic groups, parent/child lineage, reversible task reorganization, and creation APIs that could place relay successors under the right project topic automatically.

![Concept of project tasks nested by topic](docs/assets/thread-nesting-concept.png)

This is an illustrative concept, not a current Codex screenshot.

## Validate or contribute

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-repository.ps1
```

Validation covers plugin manifests, marketplace wiring, recurring relay contracts, synthetic audit tests, draw.io provenance, required assets, and common private-data or secret patterns.

## Privacy, provenance, and licensing

This standalone repository contains no project checkpoints, transcripts, credentials, local user paths, private repository names, or user data. Installing it does not change any other GitHub repository's visibility. Runtime behavior is documented in [PRIVACY.md](PRIVACY.md).

Original Goal Workflows and repository materials use the [MIT License](LICENSE). Draw.io and Skill Maintenance retain their adapted-source attribution in the plugin license files and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
