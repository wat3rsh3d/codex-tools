# Skill Inventory Audit Precision Implementation Plan

> **Execution:** Follow this plan with the executing-plans workflow. Use test-driven development and fresh verification before completion.

**Goal:** Remove plugin-cache fixture noise and make CLI prompt evidence attributable to the Codex executable that produced it.

**Architecture:** Keep filesystem discovery, CLI probing, reporting, and rendering as separate functions. Recognize only canonical version-level `skills` roots in the cache. Extend CLI runner results with executable and version fields while accepting the existing three-value injected runner contract.

**Tech stack:** Python 3 standard library, `unittest`, PowerShell repository validation.

---

### Task 1: Specify cache filtering with failing tests

**Files:**
- Modify: `tests/test_skill_inventory_audit.py`

1. Add a test containing canonical, nested canonical, fixture, and example `SKILL.md` files.
2. Assert that only the canonical skills appear and the cache group count matches them.
3. Run `python -m unittest tests.test_skill_inventory_audit -v`.
4. Confirm the new test fails because the current recursive scan includes fixture/example entries.

### Task 2: Specify CLI provenance with failing tests

**Files:**
- Modify: `tests/test_skill_inventory_audit.py`

1. Add an injected runner result with executable and version provenance.
2. Assert the JSON surface contains both fields and the text report displays them.
3. Assert a legacy three-value runner produces empty provenance rather than failing.
4. Run the focused tests and confirm the provenance assertion fails for the current schema.

### Task 3: Implement the smallest passing behavior

**Files:**
- Modify: `plugins/skill-maintenance/skills/skill-inventory-audit/scripts/audit_skill_inventory.py`

1. Add canonical cache-path recognition anchored at marketplace/plugin/version/top-level-skills.
2. Scan only eligible paths while preserving nested skill support and grouping.
3. Add a structured CLI probe result and normalize legacy injected runner results.
4. Resolve the default executable once, run prompt and version probes independently, and include provenance in the CLI surface.
5. Bump `schema_version` to 2 and render provenance when present.
6. Run the focused test module and confirm all tests pass.

### Task 4: Update the skill contract and patch version

**Files:**
- Modify: `plugins/skill-maintenance/skills/skill-inventory-audit/SKILL.md`
- Modify: `docs/skill-maintenance.md`
- Modify: `plugins/skill-maintenance/.codex-plugin/plugin.json`
- Modify: `scripts/validate-repository.ps1`
- Modify: `tests/test_skill_contracts.py`

1. Document canonical cache discovery and CLI provenance.
2. Add contract assertions for both behaviors.
3. Bump the Skill Maintenance plugin from 1.0.0 to 1.0.1 and update repository validation.
4. Run both maintenance test modules.

### Task 5: Verify, publish, and install

1. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate-repository.ps1`.
2. Run `git diff --check` and inspect the complete diff.
3. Run a real JSON audit and confirm fixture names are absent and CLI provenance is present.
4. Commit, push, open a pull request, wait for required checks, and squash-merge.
5. Update the registered marketplace and replace the direct installed `skill-inventory-audit` with the merged source through a staged rollback-safe copy.
6. Verify source/install hashes and rerun the installed audit.
