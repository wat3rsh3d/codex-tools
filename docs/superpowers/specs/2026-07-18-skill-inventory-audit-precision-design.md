# Skill Inventory Audit Precision Design

## Purpose

Make the inventory report easier to trust by excluding non-installable fixture and example skills from plugin-cache results and by identifying the Codex CLI executable that produced the prompt inventory.

## Current problem

The cache scanner accepts every `SKILL.md` below `plugins/cache`. That includes test fixtures and example plugin trees, so cache counts and duplicate-name findings can describe files that are not actual cached plugin skills.

The CLI surface also reports only availability and skill names. When multiple Codex builds are installed, the report cannot explain which executable produced that evidence.

## Approved behavior

### Canonical plugin-cache skills

A cached skill is eligible only when its path has this shape:

```text
plugins/cache/<marketplace>/<plugin>/<version>/skills/<skill path>/SKILL.md
```

The scanner may recurse beneath that version's top-level `skills` directory so legitimate nested skill organization remains supported. It ignores `SKILL.md` files elsewhere in the cached plugin tree, including fixtures, examples, tests, and documentation.

### CLI provenance

The default CLI probe resolves `codex` from the current process PATH, records the resolved executable path, and obtains its version with `codex --version`. The report keeps prompt availability, skill names, and provenance separate so a failed version probe does not discard a successful prompt probe.

Injected CLI runners remain supported for deterministic tests. They may supply explicit provenance; older three-value runners remain accepted as unknown provenance for compatibility.

## Report and compatibility

- Bump the report schema from version 1 to version 2 because the CLI surface gains structured provenance.
- Add `executable` and `version` to the CLI prompt surface.
- Show both fields in the human-readable CLI line when available.
- Preserve the read-only, local-only, explicit-usage boundary.
- Do not select a different executable, inspect Codex configuration, or infer activation from cache presence.

## Validation

Regression tests prove that canonical and nested skills remain visible, fixture/example skills are excluded, CLI provenance is serialized and rendered, and older injected runners still work. The repository validator, contract tests, and a real local audit provide release evidence.
