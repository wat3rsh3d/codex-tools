# Privacy

## Scope

Codex Tools is a package of instruction files and local helper scripts. It does not operate an independent server, user account system, analytics service, advertising service, or data store.

## Project access

Skills act only when invoked in Codex and may inspect information that the user has placed in the active task or project scope.

- `gp` performs read-only inspection to produce a continuation prompt.
- `gp-relay` may read project evidence, update an existing checkpoint, and create, title, read, or message Codex tasks and goals as part of a verified handoff.
- `drawio-skill` may read user-provided diagram requirements or project structure and write requested diagram artifacts to the selected local output path.
- `skill-inventory-audit` reads local skill metadata, plugin-cache metadata, relevant Codex configuration, and the CLI prompt inventory. It does not modify those sources. Local history and session records are not read unless the user explicitly requests `--include-usage`; that mode returns aggregate explicit-invocation counts without task content.
- `project-skill-audit` reads scoped project instructions, governing docs, checkpoints, validation commands, local skill directories, and the current task's available skill catalog. It may use the memory index and one to three targeted references when relevant. Raw session inspection requires separate explicit user approval.

The package itself does not transmit project data to a developer-controlled service. Use of Codex and any model processing remains governed by the user's OpenAI account, workspace settings, and applicable OpenAI terms and privacy controls.

## Data retention

This package does not independently retain user data. Files, tasks, goals, prompts, checkpoints, generated diagrams, skill metadata, memory references, history, and raw session records remain in the storage locations selected by the user or provided by Codex.

## External resources

The draw.io skill can optionally use the native draw.io application, Graphviz, diagrams.net browser URLs, and public icon resources when the requested workflow calls for them. Its instructions identify those paths before use.

## Contact

For questions or reports, use the repository's [support process](SUPPORT.md).
