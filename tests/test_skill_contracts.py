from __future__ import annotations

import re
import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
PLUGIN_ROOT = REPOSITORY_ROOT / "plugins" / "skill-maintenance"
INVENTORY_ROOT = PLUGIN_ROOT / "skills" / "skill-inventory-audit"
PROJECT_AUDIT_ROOT = PLUGIN_ROOT / "skills" / "project-skill-audit"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def frontmatter_description(skill_text: str) -> str:
    match = re.search(r"(?m)^description:\s*(.+)$", skill_text)
    if not match:
        raise AssertionError("SKILL.md is missing a description")
    return match.group(1).strip().strip('"\'')


class SkillMaintenanceContractTests(unittest.TestCase):
    def test_inventory_skill_is_explicit_and_advisory(self) -> None:
        skill_text = read_text(INVENTORY_ROOT / "SKILL.md")
        metadata_text = read_text(INVENTORY_ROOT / "agents" / "openai.yaml")

        self.assertTrue(frontmatter_description(skill_text).startswith("Use when"))
        self.assertIn("audit_skill_inventory.py", skill_text)
        self.assertIn("--include-usage", skill_text)
        self.assertIn("top-level `skills` directory", skill_text)
        self.assertIn("resolved Codex executable and version", skill_text)
        self.assertIn("Do not delete, move, disable, install, or rewrite skills", skill_text)
        self.assertRegex(metadata_text, r"(?m)^\s*allow_implicit_invocation:\s*false\s*$")

    def test_project_audit_covers_scoped_project_evidence(self) -> None:
        skill_text = read_text(PROJECT_AUDIT_ROOT / "SKILL.md")

        self.assertTrue(frontmatter_description(skill_text).startswith("Use when"))
        for required_text in (
            "exact project root",
            "AGENTS.md",
            "README",
            ".agents/skills",
            ".codex/skills",
            "skills/",
            "$CODEX_HOME/memories/MEMORY.md",
        ):
            self.assertIn(required_text, skill_text)

    def test_project_audit_bounds_memory_and_raw_session_access(self) -> None:
        skill_text = read_text(PROJECT_AUDIT_ROOT / "SKILL.md")
        normalized = skill_text.lower()

        self.assertRegex(normalized, r"one to three .*?(?:memory|rollout).*?references")
        self.assertIn("raw session", normalized)
        self.assertRegex(normalized, r"explicit (?:user )?approval.{0,100}raw session|raw session.{0,100}explicit (?:user )?approval")

    def test_project_audit_prefers_existing_skills(self) -> None:
        skill_text = read_text(PROJECT_AUDIT_ROOT / "SKILL.md")
        decision_section = skill_text.split("## Decision policy", 1)[1]

        reuse_index = decision_section.find("Reuse")
        improve_index = decision_section.find("Improve")
        create_index = decision_section.find("Create")
        self.assertGreaterEqual(reuse_index, 0)
        self.assertGreater(improve_index, reuse_index)
        self.assertGreater(create_index, improve_index)

    def test_project_audit_has_evidence_labels_and_output_fields(self) -> None:
        skill_text = read_text(PROJECT_AUDIT_ROOT / "SKILL.md")

        for label in ("verified", "inferred", "unavailable"):
            self.assertIn(label, skill_text)
        for field in ("Recommendation", "Evidence", "Benefit", "Scope", "Validation"):
            self.assertIn(field, skill_text)

    def test_project_audit_is_explicit_only(self) -> None:
        metadata_text = read_text(PROJECT_AUDIT_ROOT / "agents" / "openai.yaml")
        self.assertRegex(metadata_text, r"(?m)^\s*allow_implicit_invocation:\s*false\s*$")

    def test_both_audits_forbid_network_requests(self) -> None:
        for skill_root in (INVENTORY_ROOT, PROJECT_AUDIT_ROOT):
            self.assertIn("Do not make network requests", read_text(skill_root / "SKILL.md"))


if __name__ == "__main__":
    unittest.main()
