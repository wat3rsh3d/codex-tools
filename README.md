# Codex Tools

Five Codex skills in three independently installable plugins for preserving project momentum, keeping skill libraries coherent, and turning complex systems into editable diagrams.

## Install

```powershell
codex plugin marketplace add wat3rsh3d/codex-tools --ref main
```

Refresh the ChatGPT desktop app, open the Plugins Directory, select **Codex Tools by watershed**, and install the plugin you want.

## What's included

### Goal Workflows

Move project work into fresh, focused Codex tasks without losing the decisions, evidence, or completion boundaries that make it trustworthy.

| Skill | Benefit |
|---|---|
| `gp` | Turn current project truth into a compact, paste-ready prompt for a fresh task. |
| `gp-relay` | Keep long-running work moving through a recurring chain of focused, topic-named tasks with verified handoffs. |

#### Modifiers

Both skills use the same modifier model, so the desired completion boundary is predictable whether the handoff is manual or automated.

| Modifier | Description | Examples |
|---|---|---|
| No modifier | Target the next evidence-backed major milestone. | `$gp` · `$gp-relay` |
| `0` | Continue through successive safe slices with no overall completion boundary. | `$gp 0` · `$gp-relay 0` |
| `<hint>` | Freeze a specific requested outcome as observable completion gates. | `$gp finish the import flow` · `$gp-relay ship the API migration` |

#### How `gp` works

`gp` inspects the smallest useful set of governing documents, checkpoints, live project state, decisions, validation evidence, and blockers. It returns one paste-ready Markdown prompt that lets a fresh task begin from current project truth instead of reconstructing an accumulated conversation.

The prompt establishes the exact root, authority order, verified resume state, safe work queues, decision policy, and completion gates. You review it, create a fresh task, and paste it. [`gp` contract and evidence workflow →](docs/gp.md)

#### How `gp-relay` works

`gp-relay` automates verified handoffs between visible, topic-named Codex tasks while preventing predecessor and successor tasks from doing project work at the same time.

```text
Task A / segment 1
  -> verified handoff -> Task B / segment 2
  -> verified handoff -> Task C / segment 3
  -> ...
```

Each handoff creates exactly one successor. After that successor verifies the project and frozen goal, receives `START`, and begins work, it becomes the active segment and can relay again. The cycle continues through as many successor tasks as needed until the chain's completion boundary is verified or a genuine hard boundary leaves no safe work.

At every handoff, the active task finishes or safely unwinds its current operation, validates and checkpoints the exact delta, creates one successor, verifies its `READY` signal, stops its own segment, and sends one verified `START`. Ambiguous results retain the same successor for recovery instead of creating duplicates. [`gp-relay` recurring protocol and recovery model →](docs/gp-relay.md)

#### Why this is different from compaction

Compaction summarizes older turns so one task can continue. Goal Workflows starts a fresh task with a deliberately selected working set, explicit project boundaries, topic-aware naming, and auditable continuation state. Codex still manages its own context; these skills make the transition between focused tasks intentional.

### Skill Maintenance

Keep a growing Codex setup understandable and reusable before duplicated skills, cached versions, and repeated project work become invisible maintenance debt.

| Skill | Benefit |
|---|---|
| `skill-inventory-audit` | See direct skills, cached plugin copies, and model-visible inventory as separate surfaces before maintenance decisions are made. |
| `project-skill-audit` | Turn repeated project friction into evidence-backed recommendations to reuse, improve, or create a skill. |

#### How `skill-inventory-audit` works

Invoke `$skill-inventory-audit` to produce a read-only map of direct skill folders, versioned plugin-cache copies, and the skills exposed through the current CLI prompt surface. Its local Python helper also flags duplicate names, malformed frontmatter, and unusually large discovery metadata, with deterministic JSON available for comparisons.

Optional usage inspection reports aggregate explicit invocation counts without retaining task content. Findings remain review signals: the audit does not delete, move, disable, install, or rewrite skills.

#### How `project-skill-audit` works

Invoke `$project-skill-audit` when setup, recovery, validation, review, or handoff work keeps recurring inside a project. It compares scoped project evidence with the skills available to the current task, then recommends the smallest durable response in this order:

1. reuse a skill whose contract already fits;
2. improve an existing skill with a precise, portable addition; or
3. create a new skill only for a distinct, recurring workflow.

Each recommendation includes its evidence, expected benefit, exact scope, and a synthetic validation path. Both maintenance skills are explicit, read-only, and local; usage and raw-session inspection remain separately approval-gated. [Skill Maintenance behavior, privacy boundaries, and provenance →](docs/skill-maintenance.md)

### Draw.io Diagrams

Create diagrams that communicate clearly on delivery and remain useful as editable design artifacts afterward.

| Skill | Benefit |
|---|---|
| `drawio-skill` | Turn complex systems and processes into polished, validated diagrams that remain fully editable. |

#### How `drawio-skill` works

Ask Codex for a draw.io diagram to plan the composition, generate editable `.drawio` XML, validate its structure and rendered layout, and export the result as PNG, SVG, PDF, or JPG.

The skill supports architecture, UML, ER, sequence, network, process, and code-structure diagrams; reusable visual presets; Graphviz-backed autolayout for dense graphs; official shape and AI-brand icon lookup; and a browser fallback when the desktop CLI is unavailable. [Draw.io capabilities, integrity, and provenance →](docs/drawio-skill.md)

## Current Codex interaction notes

- `gp-relay` runs only after explicit invocation in a saved Codex project.
- It responds to host context warnings and bounded material-work turns; current Codex versions do not expose an exact live token meter to the skill.
- Successors are created in the background and remain visible in the sidebar without being auto-opened.
- Titles come from the active project milestone. True nested topic placement is the subject of the enhancement request below.
- An exact handoff may update an existing project checkpoint.
- Skill Maintenance audits remain explicit and read-only; broader local inspection requires separate approval where documented.

## Codex enhancement request: nested tasks

![Concept of project tasks nested by topic](docs/assets/thread-nesting-concept.png)

*Illustrative concept: a saved project contains topic groups such as UI and CI/CD, with related tasks nested beneath them.*

Nested, reorganizable tasks would turn the Codex sidebar into a durable map of project work. Users could understand a complex project at a glance, return to the right workstream faster, and follow continuation chains without decoding an ever-growing flat list.

- **Faster re-entry:** related tasks stay grouped under the topic they serve.
- **Trustworthy continuation:** predecessor and successor relationships remain visible across every relay.
- **Organization that survives growth:** tasks can be moved as the project evolves without losing their transcript, project identity, or lineage.

### How it would work

Saved projects would gain collapsible topic groups that can contain tasks and optional subgroups. Every task could retain an independent predecessor/successor lineage, so moving it to a better topic would reorganize the sidebar without rewriting history.

Users could create, rename, reorder, and move topics with mouse, touch, or keyboard controls. Task-creation tools could request both topic placement and predecessor lineage, then read the persisted state back for verification. Automated placement would remain visible, reversible, and permission-aware.

With those host capabilities, `gp-relay` could place each topic-named successor directly under the workstream it belongs to while preserving the exact chain that created it. [Read the complete feature request, proposed host capabilities, and acceptance criteria →](FEATURE_REQUEST.md)

## Validate or contribute

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-repository.ps1
```

Validation covers plugin manifests, marketplace wiring, recurring relay contracts, synthetic audit tests, draw.io provenance, required assets, the README information contract, and common private-data or secret patterns.

## Privacy, provenance, and licensing

This standalone repository contains no project checkpoints, transcripts, credentials, local user paths, private repository names, or user data. Installing it does not change any other GitHub repository's visibility. Runtime behavior is documented in [PRIVACY.md](PRIVACY.md).

Original Goal Workflows and repository materials use the [MIT License](LICENSE). Draw.io and Skill Maintenance retain their adapted-source attribution in the plugin license files and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
