# Codex Tools

Five focused Codex skills, packaged as three independently installable plugins.

## Install

```powershell
codex plugin marketplace add wat3rsh3d/codex-tools --ref main
```

Refresh the ChatGPT desktop app, open the Plugins Directory, select **Codex Tools by watershed**, and install the plugin you want.

## Choose a tool

| Plugin | Skill | Use it for | Invoke |
|---|---|---|---|
| Goal Workflows | `gp` | Build a paste-ready goal prompt for a fresh task | `$gp` |
| Goal Workflows | `gp-relay` | Continue long-running work across a recurring chain of fresh tasks | `$gp-relay` |
| Draw.io Diagrams | `drawio-skill` | Create and export polished, editable draw.io diagrams | Ask Codex for a draw.io diagram |
| Skill Maintenance | `skill-inventory-audit` | Map installed skill surfaces and find metadata or duplication problems | `$skill-inventory-audit` |
| Skill Maintenance | `project-skill-audit` | Find recurring project workflows that should reuse or become skills | `$project-skill-audit` |

## Goal Workflows

Goal Workflows rotates active project context into a fresh Codex task while preserving the evidence needed to continue. It uses governing documents, checkpoints, live project state, validation results, decisions, and blockers instead of carrying an entire conversation forward.

### `gp`: prepare a fresh-task prompt

`gp` inspects the current project and returns one paste-ready Markdown prompt. It does not create the task or perform project work.

| Command | Completion boundary |
|---|---|
| `$gp` | The next evidence-backed major milestone |
| `$gp 0` | Open-ended continuation with no overall completion boundary |
| `$gp <hint>` | The exact requested outcome, expressed as observable completion gates |

You create a fresh task and paste the result. See [the full `gp` contract](docs/gp.md).

### `gp-relay`: run a recurring task chain

`gp-relay` automates verified handoffs between visible, topic-named Codex tasks. It is not limited to creating one new task for the whole run:

```text
Task A / segment 1
  -> verified handoff -> Task B / segment 2
  -> verified handoff -> Task C / segment 3
  -> ...
```

Each individual handoff creates exactly one successor. After that successor verifies the goal and receives `START`, it becomes the active segment and can relay again. The cycle repeats until the chain's completion boundary is verified or a genuine hard boundary leaves no safe work.

For every handoff, the active task:

1. finishes or safely unwinds its current operation;
2. validates and checkpoints the exact delta;
3. creates one successor with a topic-aware title;
4. verifies the successor's exact goal and `READY` signal;
5. stops its own segment; and
6. sends one verified `START` signal.

The READY/START handshake prevents predecessor and successor tasks from doing project work at the same time. Ambiguous results retain the same successor for recovery instead of creating duplicates.

| Command | Chain boundary |
|---|---|
| `$gp-relay` | The next evidence-backed major milestone |
| `$gp-relay 0` | Open-ended continuation through as many successor tasks as needed |
| `$gp-relay <hint>` | The exact requested outcome, frozen as observable completion gates |

See [the full recurring relay protocol](docs/gp-relay.md).

### Relationship to compaction

Compaction summarizes older turns so one task can continue. Goal Workflows instead starts a fresh task with a deliberately selected working set. The approaches can coexist: Codex still manages its own context, while these skills establish explicit project boundaries, topic-aware task names, and auditable continuation state.

Current Codex interaction notes:

- `gp-relay` runs only after explicit invocation in a saved Codex project.
- It responds to host context warnings and bounded material-work turns; current Codex versions do not expose an exact live token meter to the skill.
- Successors are created in the background and remain visible in the sidebar without being auto-opened.
- Titles come from the active project milestone. True nested topic placement is the subject of the included [OpenAI feature request](FEATURE_REQUEST.md).
- An exact handoff may update an existing project checkpoint.

## Skill Maintenance

These explicit, read-only audits help keep a growing skill installation understandable.

- `skill-inventory-audit` separates direct skills, versioned plugin-cache copies, and the CLI model-visible prompt inventory. Usage inspection is off unless `--include-usage` is requested.
- `project-skill-audit` compares recurring project work with available skills and ranks reuse before improvement before new-skill creation. Raw session inspection requires separate approval.

Neither skill makes network requests or changes files. See [Skill Maintenance details](docs/skill-maintenance.md).

## Draw.io Diagrams

`drawio-skill` plans diagram composition, generates valid draw.io XML, checks the rendered result, and exports PNG, SVG, PDF, or JPG through the native desktop CLI. It supports architecture, UML, ER, network, process, and code-structure diagrams.

This package is a maintained derivative of [`wat3rsh3d/drawio-skill`](https://github.com/wat3rsh3d/drawio-skill), originally by [`Agents365-ai`](https://github.com/Agents365-ai/drawio-skill). See [provenance](docs/drawio-skill.md) and [third-party notices](THIRD_PARTY_NOTICES.md).

## OpenAI submission package

Goal Workflows is packaged for OpenAI's plugin submission portal:

- runtime: [`plugins/goal-workflows/skills`](plugins/goal-workflows/skills/)
- plugin manifest: [`plugins/goal-workflows/.codex-plugin/plugin.json`](plugins/goal-workflows/.codex-plugin/plugin.json)
- listing and reviewer materials: [`submission/goal-workflows`](submission/goal-workflows/)
- public policies: [privacy](PRIVACY.md), [terms](TERMS.md), and [support](SUPPORT.md)

Build the two validated upload archives:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-submission.ps1
```

The archives and their SHA-256 hashes are written to `dist/`. They are also attached to the [Goal Workflows v1.0.0 release](https://github.com/wat3rsh3d/codex-tools/releases/tag/goal-workflows-v1.0.0).

Publisher verification, listing availability, and policy attestations are completed in OpenAI's submission portal.

## Proposed Codex improvement: nested tasks

The included [feature request](FEATURE_REQUEST.md) proposes collapsible topic groups, parent/child lineage, reversible task reorganization, and creation APIs that could place relay successors under the right project topic automatically.

![Concept of project tasks nested by topic](docs/assets/thread-nesting-concept.png)

This is an illustrative concept, not a current Codex screenshot.

## Validate or contribute

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-repository.ps1
```

Validation covers plugin manifests, marketplace wiring, recurring relay contracts, synthetic audit tests, submission materials, draw.io provenance, required assets, and common private-data or secret patterns.

## Privacy and licensing

This standalone repository contains no project checkpoints, transcripts, credentials, local user paths, private repository names, or user data. Installing it does not change any other GitHub repository's visibility. Runtime behavior is documented in [PRIVACY.md](PRIVACY.md).

Original Goal Workflows and repository materials use the [MIT License](LICENSE). Vendored or adapted components retain their MIT attribution in the plugin license files and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
