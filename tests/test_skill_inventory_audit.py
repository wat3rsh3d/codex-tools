from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = (
    REPOSITORY_ROOT
    / "plugins"
    / "skill-maintenance"
    / "skills"
    / "skill-inventory-audit"
    / "scripts"
    / "audit_skill_inventory.py"
)


def load_inventory_module():
    spec = importlib.util.spec_from_file_location("audit_skill_inventory", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load inventory module from {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


MODULE = load_inventory_module()


class SkillInventoryAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.codex_home = Path(self.temporary_directory.name) / ".codex"
        self.codex_home.mkdir()

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write_skill(
        self,
        relative_path: str,
        name: str,
        description: str,
    ) -> Path:
        skill_path = self.codex_home / relative_path
        skill_path.parent.mkdir(parents=True, exist_ok=True)
        skill_path.write_text(
            f'---\nname: {name}\ndescription: "{description}"\n---\n\n# {name}\n',
            encoding="utf-8",
        )
        return skill_path

    @staticmethod
    def unavailable_cli() -> tuple[int, str, str]:
        return 1, "", "debug prompt input is unavailable"

    def test_separates_direct_and_cached_skills(self) -> None:
        self.write_skill("skills/personal/SKILL.md", "personal", "Direct skill")
        self.write_skill(
            "plugins/cache/example-market/toolkit/1.0.0/skills/personal/SKILL.md",
            "personal",
            "Cached copy",
        )

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        self.assertEqual(
            ["personal"],
            [item["name"] for item in report["surfaces"]["direct"]["skills"]],
        )
        cache_group = report["surfaces"]["plugin_cache"]["groups"][0]
        self.assertEqual("example-market", cache_group["marketplace"])
        self.assertEqual("toolkit", cache_group["plugin"])
        self.assertEqual("1.0.0", cache_group["version"])
        self.assertEqual("personal", report["findings"]["duplicate_names"][0]["name"])

    def test_groups_cached_versions_without_claiming_they_are_active(self) -> None:
        for version in ("1.0.0", "2.0.0"):
            self.write_skill(
                f"plugins/cache/example-market/toolkit/{version}/skills/shared/SKILL.md",
                "shared",
                f"Cached version {version}",
            )

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        groups = report["surfaces"]["plugin_cache"]["groups"]
        self.assertEqual(["1.0.0", "2.0.0"], [group["version"] for group in groups])
        self.assertTrue(all(group["status"] == "cached" for group in groups))
        duplicate = report["findings"]["duplicate_names"][0]
        self.assertEqual("shared", duplicate["name"])
        self.assertEqual(2, duplicate["count"])

    def test_excludes_noncanonical_cached_skill_trees(self) -> None:
        self.write_skill(
            "plugins/cache/example-market/toolkit/1.0.0/skills/real/SKILL.md",
            "real",
            "Canonical cached skill",
        )
        self.write_skill(
            "plugins/cache/example-market/toolkit/1.0.0/skills/categories/nested/SKILL.md",
            "nested",
            "Nested canonical cached skill",
        )
        self.write_skill(
            "plugins/cache/example-market/toolkit/1.0.0/fixtures/example/skills/fixture/SKILL.md",
            "fixture",
            "Test fixture",
        )
        self.write_skill(
            "plugins/cache/example-market/toolkit/1.0.0/examples/demo/skills/example/SKILL.md",
            "example",
            "Documentation example",
        )

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        cached_surface = report["surfaces"]["plugin_cache"]
        self.assertEqual(
            ["nested", "real"],
            sorted(item["name"] for item in cached_surface["skills"]),
        )
        self.assertEqual(2, cached_surface["groups"][0]["skill_count"])

    def test_isolates_malformed_frontmatter(self) -> None:
        self.write_skill("skills/valid/SKILL.md", "valid", "Valid metadata")
        malformed_path = self.codex_home / "skills" / "broken" / "SKILL.md"
        malformed_path.parent.mkdir(parents=True)
        malformed_path.write_text("# Missing frontmatter\n", encoding="utf-8")

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        self.assertEqual(
            ["valid"],
            [item["name"] for item in report["surfaces"]["direct"]["skills"]],
        )
        malformed = report["findings"]["malformed"]
        self.assertEqual(1, len(malformed))
        self.assertEqual("skills/broken/SKILL.md", malformed[0]["path"])

    def test_reports_cli_prompt_as_an_independent_surface(self) -> None:
        self.write_skill("skills/direct/SKILL.md", "direct", "Direct skill")

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=lambda: (
                0,
                "<skills>\n- direct: installed\n- model-only: injected\n</skills>\n",
                "",
            ),
        )

        cli_surface = report["surfaces"]["cli_prompt"]
        self.assertTrue(cli_surface["available"])
        self.assertEqual(["direct", "model-only"], cli_surface["skills"])
        self.assertEqual("", cli_surface["note"])
        self.assertEqual("", cli_surface["executable"])
        self.assertEqual("", cli_surface["version"])

    def test_reports_cli_executable_and_version_provenance(self) -> None:
        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=lambda: (
                0,
                "<skills>\n- direct: installed\n</skills>\n",
                "",
                "C:/Tools/codex.exe",
                "codex-cli 0.145.0",
            ),
        )

        cli_surface = report["surfaces"]["cli_prompt"]
        self.assertEqual("C:/Tools/codex.exe", cli_surface["executable"])
        self.assertEqual("codex-cli 0.145.0", cli_surface["version"])

        rendered = MODULE.render_text(report)
        self.assertIn(
            "CLI prompt: 1 skill names (codex-cli 0.145.0 at C:/Tools/codex.exe)",
            rendered,
        )

    def test_default_cli_probe_tolerates_empty_version_output(self) -> None:
        with (
            mock.patch.object(
                MODULE.shutil,
                "which",
                return_value="C:/Tools/codex.exe",
            ),
            mock.patch.object(
                MODULE,
                "_run_cli_command",
                side_effect=[
                    (0, "", ""),
                    (0, "<skills>\n- direct: installed\n</skills>\n", ""),
                ],
            ),
        ):
            result = MODULE._default_cli_runner()

        self.assertEqual(0, result[0])
        self.assertEqual("", result[4])

    def test_parses_json_wrapped_cli_prompt_text(self) -> None:
        prompt_payload = json.dumps(
            [
                {
                    "type": "message",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "### Available skills\n"
                                "- imagegen: Generate images. (file: /skills/imagegen/SKILL.md)\n"
                                "- skill-creator: Create skills. (file: /skills/skill-creator/SKILL.md)\n"
                            ),
                        }
                    ],
                }
            ]
        )

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=lambda: (0, prompt_payload, ""),
        )

        self.assertEqual(
            ["imagegen", "skill-creator"],
            report["surfaces"]["cli_prompt"]["skills"],
        )

    def test_preserves_other_surfaces_when_cli_prompt_is_unavailable(self) -> None:
        self.write_skill("skills/direct/SKILL.md", "direct", "Direct skill")

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        self.assertEqual(1, len(report["surfaces"]["direct"]["skills"]))
        self.assertFalse(report["surfaces"]["cli_prompt"]["available"])
        self.assertIn("unavailable", report["surfaces"]["cli_prompt"]["note"])

    def test_usage_scan_is_opt_in(self) -> None:
        self.write_skill("skills/alpha/SKILL.md", "alpha", "Direct skill")

        with mock.patch.object(MODULE, "scan_usage") as scan_usage:
            report = MODULE.audit_codex_home(
                self.codex_home,
                include_usage=False,
                cli_runner=self.unavailable_cli,
            )

        scan_usage.assert_not_called()
        self.assertEqual(
            {"included": False, "counts": {}},
            report["surfaces"]["usage"],
        )

    def test_usage_report_counts_invocations_without_retaining_content(self) -> None:
        self.write_skill("skills/alpha/SKILL.md", "alpha", "Direct skill")
        history = self.codex_home / "history.jsonl"
        history.write_text(
            '{"text":"private fixture phrase $alpha"}\n'
            '{"text":"invoke $alpha again"}\n',
            encoding="utf-8",
        )

        report = MODULE.audit_codex_home(
            self.codex_home,
            include_usage=True,
            cli_runner=self.unavailable_cli,
        )
        rendered = MODULE.render_text(report)

        self.assertEqual(
            {"included": True, "counts": {"alpha": 2}},
            report["surfaces"]["usage"],
        )
        self.assertNotIn("private fixture phrase", json.dumps(report))
        self.assertNotIn("private fixture phrase", rendered)

    def test_large_metadata_and_report_are_json_serializable(self) -> None:
        self.write_skill("skills/verbose/SKILL.md", "verbose", "x" * 600)

        report = MODULE.audit_codex_home(
            self.codex_home,
            cli_runner=self.unavailable_cli,
        )

        self.assertEqual("verbose", report["findings"]["large_metadata"][0]["name"])
        self.assertGreater(
            report["findings"]["large_metadata"][0]["estimated_tokens"],
            100,
        )
        self.assertIn('"schema_version": 2', json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    unittest.main()
