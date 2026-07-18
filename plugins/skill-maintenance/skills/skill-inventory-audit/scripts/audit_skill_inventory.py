#!/usr/bin/env python3
"""Report local Codex skill inventory surfaces without modifying them."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Callable, Iterable, Sequence


CliRunner = Callable[[], tuple[int, str, str]]
METADATA_WARNING_CHARACTERS = 512
MAX_USAGE_FILES = 200


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def _relative_path(path: Path, codex_home: Path) -> str:
    return path.relative_to(codex_home).as_posix()


def _parse_frontmatter(path: Path) -> tuple[dict[str, str] | None, str | None]:
    try:
        content = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as error:
        return None, f"unreadable metadata: {error.__class__.__name__}"

    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "missing YAML frontmatter"

    try:
        closing_index = next(
            index for index, line in enumerate(lines[1:], start=1) if line.strip() == "---"
        )
    except StopIteration:
        return None, "unterminated YAML frontmatter"

    metadata: dict[str, str] = {}
    for line in lines[1:closing_index]:
        if ":" not in line or line[:1].isspace():
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        if key in {"name", "description"}:
            metadata[key] = _unquote(value)

    if not metadata.get("name") or not metadata.get("description"):
        return None, "frontmatter requires name and description"
    return metadata, None


def _skill_entry(
    path: Path,
    codex_home: Path,
    surface: str,
    cache_identity: dict[str, str] | None = None,
) -> tuple[dict[str, object] | None, dict[str, str] | None]:
    metadata, error = _parse_frontmatter(path)
    relative_path = _relative_path(path, codex_home)
    if metadata is None:
        return None, {"path": relative_path, "surface": surface, "reason": error or "invalid"}

    metadata_characters = len(metadata["name"]) + len(metadata["description"])
    entry: dict[str, object] = {
        "name": metadata["name"],
        "description": metadata["description"],
        "path": relative_path,
        "surface": surface,
        "metadata_characters": metadata_characters,
        "estimated_tokens": (metadata_characters + 3) // 4,
    }
    if cache_identity:
        entry.update(cache_identity)
        entry["status"] = "cached"
    return entry, None


def _scan_direct(codex_home: Path) -> tuple[list[dict[str, object]], list[dict[str, str]]]:
    skills_root = codex_home / "skills"
    if not skills_root.is_dir():
        return [], []

    skills: list[dict[str, object]] = []
    malformed: list[dict[str, str]] = []
    for path in sorted(skills_root.rglob("SKILL.md")):
        entry, problem = _skill_entry(path, codex_home, "direct")
        if entry:
            skills.append(entry)
        if problem:
            malformed.append(problem)
    return skills, malformed


def _cache_identity(path: Path, cache_root: Path) -> dict[str, str]:
    relative_parts = path.relative_to(cache_root).parts
    skill_indexes = [index for index, part in enumerate(relative_parts) if part == "skills"]
    prefix = relative_parts[: skill_indexes[0]] if skill_indexes else relative_parts[:-1]

    marketplace = prefix[-3] if len(prefix) >= 3 else "unknown"
    plugin = prefix[-2] if len(prefix) >= 2 else (prefix[-1] if prefix else "unknown")
    version = prefix[-1] if prefix else "unknown"
    return {"marketplace": marketplace, "plugin": plugin, "version": version}


def _scan_plugin_cache(
    codex_home: Path,
) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, str]]]:
    cache_root = codex_home / "plugins" / "cache"
    if not cache_root.is_dir():
        return [], [], []

    skills: list[dict[str, object]] = []
    malformed: list[dict[str, str]] = []
    group_counts: Counter[tuple[str, str, str]] = Counter()

    for path in sorted(cache_root.rglob("SKILL.md")):
        identity = _cache_identity(path, cache_root)
        entry, problem = _skill_entry(path, codex_home, "plugin_cache", identity)
        if entry:
            skills.append(entry)
            group_counts[(identity["marketplace"], identity["plugin"], identity["version"])] += 1
        if problem:
            problem.update(identity)
            malformed.append(problem)

    groups = [
        {
            "marketplace": marketplace,
            "plugin": plugin,
            "version": version,
            "skill_count": count,
            "status": "cached",
        }
        for (marketplace, plugin, version), count in sorted(group_counts.items())
    ]
    return skills, groups, malformed


def _default_cli_runner() -> tuple[int, str, str]:
    codex_executable = shutil.which("codex")
    if not codex_executable:
        return 127, "", "codex executable unavailable"
    try:
        completed = subprocess.run(
            [codex_executable, "debug", "prompt-input"],
            capture_output=True,
            check=False,
            text=True,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError) as error:
        return 126, "", error.__class__.__name__
    return completed.returncode, completed.stdout, completed.stderr


def _parse_cli_skill_names(output: str) -> list[str]:
    fragments = [output]
    try:
        payload = json.loads(output)
    except (json.JSONDecodeError, TypeError):
        payload = None

    if payload is not None:
        fragments = []

        def collect_text(value: object) -> None:
            if isinstance(value, dict):
                for key, nested in value.items():
                    if key == "text" and isinstance(nested, str):
                        fragments.append(nested)
                    else:
                        collect_text(nested)
            elif isinstance(value, list):
                for nested in value:
                    collect_text(nested)

        collect_text(payload)

    names: set[str] = set()
    patterns = (
        re.compile(r"(?m)^\s*-\s+(?:\*\*)?([a-z0-9][a-z0-9:-]*)(?:\*\*)?\s*:"),
        re.compile(r"(?m)^\s*name:\s*[\"']?([a-z0-9][a-z0-9:-]*)[\"']?\s*$"),
    )
    for fragment in fragments:
        available_section = re.search(
            r"(?ms)^### Available skills\s*$\n(.*?)(?=^### |\Z)",
            fragment,
        )
        search_text = available_section.group(1) if available_section else fragment
        for pattern in patterns:
            names.update(match.group(1) for match in pattern.finditer(search_text))
    return sorted(names)


def _scan_cli_prompt(cli_runner: CliRunner | None) -> dict[str, object]:
    return_code, stdout, _stderr = (cli_runner or _default_cli_runner)()
    if return_code != 0:
        return {
            "available": False,
            "skills": [],
            "note": f"codex debug prompt-input unavailable (exit code {return_code})",
        }
    return {"available": True, "skills": _parse_cli_skill_names(stdout), "note": ""}


def _usage_files(codex_home: Path) -> list[Path]:
    candidates: set[Path] = set()
    history = codex_home / "history.jsonl"
    if history.is_file():
        candidates.add(history)
    for directory_name in ("sessions", "archived_sessions"):
        directory = codex_home / directory_name
        if directory.is_dir():
            candidates.update(directory.rglob("*.jsonl"))

    def modified_time(path: Path) -> float:
        try:
            return path.stat().st_mtime
        except OSError:
            return 0.0

    return sorted(candidates, key=modified_time, reverse=True)[:MAX_USAGE_FILES]


def scan_usage(codex_home: Path, skill_names: Iterable[str]) -> dict[str, int]:
    names = sorted(set(skill_names))
    patterns = {
        name: re.compile(
            rf"(?<![A-Za-z0-9_-])\$(?:[a-z0-9-]+:)?{re.escape(name)}(?![A-Za-z0-9_-])",
            re.IGNORECASE,
        )
        for name in names
    }
    counts: Counter[str] = Counter()
    for path in _usage_files(codex_home):
        try:
            with path.open("r", encoding="utf-8", errors="replace") as handle:
                for line in handle:
                    for name, pattern in patterns.items():
                        counts[name] += len(pattern.findall(line))
        except OSError:
            continue
    return {name: counts[name] for name in names if counts[name]}


def _duplicate_findings(entries: Sequence[dict[str, object]]) -> list[dict[str, object]]:
    by_name: dict[str, list[dict[str, object]]] = defaultdict(list)
    for entry in entries:
        by_name[str(entry["name"])].append(entry)

    findings: list[dict[str, object]] = []
    for name, occurrences in sorted(by_name.items()):
        if len(occurrences) < 2:
            continue
        findings.append(
            {
                "name": name,
                "count": len(occurrences),
                "surfaces": sorted({str(item["surface"]) for item in occurrences}),
                "paths": [str(item["path"]) for item in occurrences],
            }
        )
    return findings


def audit_codex_home(
    codex_home: str | Path,
    include_usage: bool = False,
    cli_runner: CliRunner | None = None,
) -> dict[str, object]:
    root = Path(codex_home).expanduser()
    if not root.is_dir():
        raise FileNotFoundError(f"Codex home is not a readable directory: {root}")
    root = root.resolve()

    direct_skills, direct_malformed = _scan_direct(root)
    cached_skills, cache_groups, cached_malformed = _scan_plugin_cache(root)
    cli_prompt = _scan_cli_prompt(cli_runner)
    all_entries = [*direct_skills, *cached_skills]
    all_names = {str(entry["name"]) for entry in all_entries}
    all_names.update(str(name) for name in cli_prompt["skills"])

    usage = {"included": False, "counts": {}}
    if include_usage:
        usage = {"included": True, "counts": scan_usage(root, all_names)}

    large_metadata = [
        {
            "name": entry["name"],
            "path": entry["path"],
            "surface": entry["surface"],
            "metadata_characters": entry["metadata_characters"],
            "estimated_tokens": entry["estimated_tokens"],
        }
        for entry in all_entries
        if int(entry["metadata_characters"]) >= METADATA_WARNING_CHARACTERS
    ]

    return {
        "schema_version": 1,
        "codex_home": str(root),
        "surfaces": {
            "direct": {"skills": direct_skills},
            "plugin_cache": {"groups": cache_groups, "skills": cached_skills},
            "cli_prompt": cli_prompt,
            "usage": usage,
        },
        "findings": {
            "duplicate_names": _duplicate_findings(all_entries),
            "large_metadata": large_metadata,
            "malformed": [*direct_malformed, *cached_malformed],
        },
        "notes": [
            "Cached plugin versions are inventory evidence, not proof of activation.",
            "CLI prompt inventory can differ from Desktop plugin injection.",
        ],
    }


def render_text(report: dict[str, object]) -> str:
    surfaces = report["surfaces"]
    findings = report["findings"]
    direct_count = len(surfaces["direct"]["skills"])
    cached_count = len(surfaces["plugin_cache"]["skills"])
    group_count = len(surfaces["plugin_cache"]["groups"])
    cli_prompt = surfaces["cli_prompt"]
    usage = surfaces["usage"]

    lines = [
        "Skill Inventory Audit",
        f"Codex home: {report['codex_home']}",
        "",
        "Surfaces",
        f"- Direct: {direct_count} skills",
        f"- Plugin cache: {cached_count} skills in {group_count} cached groups",
    ]
    if cli_prompt["available"]:
        lines.append(f"- CLI prompt: {len(cli_prompt['skills'])} skill names")
    else:
        lines.append(f"- CLI prompt: {cli_prompt['note']}")
    if usage["included"]:
        usage_total = sum(usage["counts"].values())
        lines.append(f"- Usage: {usage_total} explicit invocations across {len(usage['counts'])} skills")
    else:
        lines.append("- Usage: not scanned (use --include-usage to opt in)")

    lines.extend(["", "Findings"])
    duplicates = findings["duplicate_names"]
    if duplicates:
        for duplicate in duplicates:
            lines.append(
                f"- Duplicate name {duplicate['name']}: {duplicate['count']} copies across "
                + ", ".join(duplicate["surfaces"])
            )
    else:
        lines.append("- No duplicate names across direct and cached filesystem surfaces")

    large_metadata = findings["large_metadata"]
    if large_metadata:
        for entry in large_metadata:
            lines.append(
                f"- Large metadata {entry['name']}: about {entry['estimated_tokens']} tokens at {entry['path']}"
            )
    else:
        lines.append("- No metadata entries reached the review threshold")

    malformed = findings["malformed"]
    if malformed:
        for entry in malformed:
            lines.append(f"- Malformed metadata at {entry['path']}: {entry['reason']}")
    else:
        lines.append("- No malformed skill metadata found")

    if usage["included"] and usage["counts"]:
        lines.append("- Explicit usage counts: " + ", ".join(
            f"{name}={count}" for name, count in sorted(usage["counts"].items())
        ))

    lines.extend(["", "Current Codex notes"])
    lines.extend(f"- {note}" for note in report["notes"])
    return "\n".join(lines) + "\n"


def _default_codex_home() -> Path:
    configured = os.environ.get("CODEX_HOME")
    return Path(configured) if configured else Path.home() / ".codex"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit local Codex skill inventory surfaces without changing them."
    )
    parser.add_argument("--codex-home", type=Path, default=_default_codex_home())
    parser.add_argument("--json", action="store_true", dest="json_output")
    parser.add_argument("--include-usage", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    arguments = build_parser().parse_args(argv)
    try:
        report = audit_codex_home(
            arguments.codex_home,
            include_usage=arguments.include_usage,
        )
    except FileNotFoundError as error:
        print(str(error), file=sys.stderr)
        return 2

    if arguments.json_output:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(render_text(report), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
