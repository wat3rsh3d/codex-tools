# Draw.io skill provenance

The `drawio-skill` plugin is a maintained derivative of the installable skill tree from [`wat3rsh3d/drawio-skill`](https://github.com/wat3rsh3d/drawio-skill). The public-fork baseline is commit `765a95b14b9cbada518723b01c847cb2123772ba`.

The upstream project is [`Agents365-ai/drawio-skill`](https://github.com/Agents365-ai/drawio-skill), authored by Agents365-ai and distributed under the MIT License. The packaged `SKILL.md` retains that author, license, and version 1.14.0 lineage. Compared with the public-fork baseline, it uses current-valid Codex frontmatter and includes later composition, validation, export, and Windows-runtime refinements from the installed skill.

## What it provides

- editable `.drawio` XML generation;
- PNG, SVG, PDF, and JPG export through draw.io desktop;
- composition planning and visual QA rules;
- architecture, UML, ER, sequence, flowchart, and ML diagram presets;
- Graphviz-backed autolayout for dense diagrams;
- code-import graph extraction for Python, JavaScript/TypeScript, Go, and Rust;
- structural validation, official shape lookup, AI-brand icons, and reusable visual presets; and
- a browser fallback when the native CLI is unavailable.

## Package integrity

The repository validator pins the vendored `SKILL.md` SHA-256:

```text
305CCB67F949E3DA2A6FF0E2DC7ADFF591C3FE6E5657E6EC18559492FE1FEAE4
```

Updating the packaged derivative requires updating its lineage note, integrity value, and third-party notice together.
