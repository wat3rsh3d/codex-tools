[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$Message) {
    $failures.Add($Message)
}

$goalPluginRoot = Join-Path $repositoryRoot 'plugins\goal-workflows'
$drawioPluginRoot = Join-Path $repositoryRoot 'plugins\drawio-skill'
$maintenancePluginRoot = Join-Path $repositoryRoot 'plugins\skill-maintenance'
$gpRoot = Join-Path $goalPluginRoot 'skills\gp'
$relayRoot = Join-Path $goalPluginRoot 'skills\gp-relay'
$drawioRoot = Join-Path $drawioPluginRoot 'skills\drawio-skill'
$inventoryRoot = Join-Path $maintenancePluginRoot 'skills\skill-inventory-audit'
$projectAuditRoot = Join-Path $maintenancePluginRoot 'skills\project-skill-audit'
$contractValidator = Join-Path $relayRoot 'scripts\validate-contract.ps1'
$featureAsset = Join-Path $repositoryRoot 'docs\assets\thread-nesting-concept.png'
$reviewerCases = Join-Path $repositoryRoot 'submission\goal-workflows\test-cases.md'
$marketplacePath = Join-Path $repositoryRoot '.agents\plugins\marketplace.json'

if (-not (Test-Path -LiteralPath $contractValidator -PathType Leaf)) {
    Add-Failure "Missing contract validator: $contractValidator"
} else {
    try {
        & $contractValidator -RelayRoot $relayRoot -GpRoot $gpRoot | Write-Output
    } catch {
        Add-Failure "Contract validation failed: $($_.Exception.Message)"
    }
}

$expectedFiles = @(
    '.agents\plugins\marketplace.json',
    'README.md',
    'FEATURE_REQUEST.md',
    'LICENSE',
    'PRIVACY.md',
    'SUPPORT.md',
    'TERMS.md',
    'THIRD_PARTY_NOTICES.md',
    'docs\gp.md',
    'docs\gp-relay.md',
    'docs\drawio-skill.md',
    'docs\skill-maintenance.md',
    'docs\assets\thread-nesting-concept.png',
    'plugins\goal-workflows\.codex-plugin\plugin.json',
    'plugins\goal-workflows\skills\gp\SKILL.md',
    'plugins\goal-workflows\skills\gp\agents\openai.yaml',
    'plugins\goal-workflows\skills\gp-relay\SKILL.md',
    'plugins\goal-workflows\skills\gp-relay\agents\openai.yaml',
    'plugins\goal-workflows\skills\gp-relay\references\protocol.md',
    'plugins\goal-workflows\skills\gp-relay\references\recovery.md',
    'plugins\goal-workflows\skills\gp-relay\scripts\validate-contract.ps1',
    'plugins\drawio-skill\.codex-plugin\plugin.json',
    'plugins\drawio-skill\LICENSE.txt',
    'plugins\drawio-skill\skills\drawio-skill\SKILL.md',
    'plugins\drawio-skill\skills\drawio-skill\agents\openai.yaml',
    'plugins\skill-maintenance\.codex-plugin\plugin.json',
    'plugins\skill-maintenance\LICENSE.txt',
    'plugins\skill-maintenance\skills\skill-inventory-audit\SKILL.md',
    'plugins\skill-maintenance\skills\skill-inventory-audit\agents\openai.yaml',
    'plugins\skill-maintenance\skills\skill-inventory-audit\scripts\audit_skill_inventory.py',
    'plugins\skill-maintenance\skills\project-skill-audit\SKILL.md',
    'plugins\skill-maintenance\skills\project-skill-audit\agents\openai.yaml',
    'tests\test_skill_inventory_audit.py',
    'tests\test_skill_contracts.py',
    'submission\goal-workflows\listing.md',
    'submission\goal-workflows\starter-prompts.md',
    'submission\goal-workflows\test-cases.md',
    'submission\goal-workflows\release-notes.md',
    'submission\goal-workflows\checklist.md',
    'submission\goal-workflows\logo.svg',
    'scripts\build-submission.ps1'
)

foreach ($relativePath in $expectedFiles) {
    $absolutePath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        Add-Failure "Missing expected file: $relativePath"
    }
}

if ((Test-Path -LiteralPath $featureAsset -PathType Leaf) -and (Get-Item -LiteralPath $featureAsset).Length -eq 0) {
    Add-Failure 'Thread-nesting concept image is empty'
}

$readmePath = Join-Path $repositoryRoot 'README.md'
if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
    $readmeText = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
    foreach ($requiredReadmeText in @(
        'wat3rsh3d/codex-tools',
        'Codex Tools marketplace',
        'Goal Workflows plugin',
        'gp skill',
        'gp-relay skill',
        'Draw.io Diagrams plugin',
        'drawio-skill skill',
        'Skill Maintenance plugin',
        'Skill Inventory Audit skill',
        'Project Skill Audit skill',
        'Fresh working context without losing validated project state.',
        'Editable source remains available for future changes.',
        'Prefer reuse or improvement before creating redundant skills.',
        'Task C / segment 3',
        'it becomes the active segment and can relay again',
        'as many successor tasks as needed'
    )) {
        if ($readmeText -notmatch [regex]::Escape($requiredReadmeText)) {
            Add-Failure "README is missing: $requiredReadmeText"
        }
    }
    foreach ($rejectedReadmeText in @(
        '## OpenAI submission package',
        'platform.openai.com/plugins',
        'submission/goal-workflows'
    )) {
        if ($readmeText -match [regex]::Escape($rejectedReadmeText)) {
            Add-Failure "README contains submission-only text: $rejectedReadmeText"
        }
    }
    $pluginSectionContracts = @(
        @{
            Label = 'Goal Workflows'
            Start = '### Goal Workflows plugin'
            End = '### Draw.io Diagrams plugin'
            Benefits = @(
                'Fresh working context without losing validated project state.'
                'Long-running work can rotate through as many topic-named successor tasks as needed.'
                'Verified handoffs prevent overlapping project work and preserve evidence.'
            )
        },
        @{
            Label = 'Draw.io Diagrams'
            Start = '### Draw.io Diagrams plugin'
            End = '### Skill Maintenance plugin'
            Benefits = @(
                'Editable source remains available for future changes.'
                'Composition, structure, and rendered output are checked before delivery.'
                'One workflow supports reusable styles and common export formats.'
            )
        },
        @{
            Label = 'Skill Maintenance'
            Start = '### Skill Maintenance plugin'
            End = '## Goal Workflows in practice'
            Benefits = @(
                'Separate direct skills, cached plugin versions, and model-visible inventory.'
                'Prefer reuse or improvement before creating redundant skills.'
                'Read-only, explicit audits keep inspection controlled and reviewable.'
            )
        }
    )
    foreach ($contract in $pluginSectionContracts) {
        $sectionStart = $readmeText.IndexOf($contract.Start)
        $sectionEnd = if ($sectionStart -ge 0) { $readmeText.IndexOf($contract.End, $sectionStart + $contract.Start.Length) } else { -1 }
        if ($sectionStart -lt 0 -or $sectionEnd -lt 0) {
            Add-Failure "README section boundary is missing: $($contract.Label)"
            continue
        }
        $sectionText = $readmeText.Substring($sectionStart, $sectionEnd - $sectionStart)
        $benefitsHeading = $sectionText.IndexOf('**Benefits**')
        $skillsHeading = $sectionText.IndexOf('**Included skills**')
        if ($benefitsHeading -lt 0 -or $skillsHeading -lt 0 -or $benefitsHeading -gt $skillsHeading) {
            Add-Failure "README $($contract.Label) must present Benefits before Included skills"
            continue
        }
        $lastBenefitIndex = $benefitsHeading
        foreach ($benefit in $contract.Benefits) {
            $benefitIndex = $sectionText.IndexOf($benefit)
            if ($benefitIndex -lt 0) {
                Add-Failure "README $($contract.Label) benefit is missing: $benefit"
            } elseif ($benefitIndex -le $lastBenefitIndex -or $benefitIndex -ge $skillsHeading) {
                Add-Failure "README $($contract.Label) benefits are not in priority order"
            } else {
                $lastBenefitIndex = $benefitIndex
            }
        }
    }
}

function Validate-PluginManifest([string]$PluginRoot, [string]$ExpectedName, [string]$ExpectedSkillsPath) {
    $manifestPath = Join-Path $PluginRoot '.codex-plugin\plugin.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return
    }
    try {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($manifest.name -ne $ExpectedName) {
            Add-Failure "$ExpectedName manifest has unexpected name: $($manifest.name)"
        }
        if ($manifest.skills -ne $ExpectedSkillsPath) {
            Add-Failure "$ExpectedName manifest has unexpected skills path: $($manifest.skills)"
        }
        if (-not $manifest.interface.displayName -or -not $manifest.interface.shortDescription -or -not $manifest.interface.longDescription) {
            Add-Failure "$ExpectedName manifest is missing interface listing metadata"
        }
    } catch {
        Add-Failure "$ExpectedName manifest is invalid JSON: $($_.Exception.Message)"
    }
}

Validate-PluginManifest $goalPluginRoot 'goal-workflows' './skills/'
Validate-PluginManifest $drawioPluginRoot 'drawio-skill' './skills/'
Validate-PluginManifest $maintenancePluginRoot 'skill-maintenance' './skills/'

$maintenanceManifestPath = Join-Path $maintenancePluginRoot '.codex-plugin\plugin.json'
if (Test-Path -LiteralPath $maintenanceManifestPath -PathType Leaf) {
    try {
        $maintenanceManifest = Get-Content -LiteralPath $maintenanceManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($maintenanceManifest.version -ne '1.0.0') {
            Add-Failure "Skill Maintenance manifest has unexpected version: $($maintenanceManifest.version)"
        }
        if ($maintenanceManifest.author.name -ne 'watershed' -or $maintenanceManifest.interface.developerName -ne 'watershed') {
            Add-Failure 'Skill Maintenance manifest must identify watershed as the author and developer'
        }
    } catch {
        Add-Failure "Skill Maintenance manifest metadata check failed: $($_.Exception.Message)"
    }
}

function Validate-ExplicitOnlyPolicy([string]$SkillRoot, [string]$SkillName) {
    $metadataPath = Join-Path $SkillRoot 'agents\openai.yaml'
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        return
    }
    $metadataText = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8
    if ($metadataText -notmatch '(?m)^\s*allow_implicit_invocation:\s*false\s*$') {
        Add-Failure "$SkillName must disable implicit invocation"
    }
}

Validate-ExplicitOnlyPolicy $inventoryRoot 'skill-inventory-audit'
Validate-ExplicitOnlyPolicy $projectAuditRoot 'project-skill-audit'

if (Test-Path -LiteralPath $marketplacePath -PathType Leaf) {
    try {
        $marketplace = Get-Content -LiteralPath $marketplacePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($marketplace.name -ne 'wat3rsh3d-codex-tools') {
            Add-Failure "Unexpected marketplace name: $($marketplace.name)"
        }
        $pluginNames = @($marketplace.plugins | ForEach-Object { $_.name })
        foreach ($requiredName in @('goal-workflows', 'drawio-skill', 'skill-maintenance')) {
            if ($requiredName -notin $pluginNames) {
                Add-Failure "Marketplace is missing plugin: $requiredName"
            }
        }
    } catch {
        Add-Failure "Marketplace manifest is invalid JSON: $($_.Exception.Message)"
    }
}

$privacyPath = Join-Path $repositoryRoot 'PRIVACY.md'
if (Test-Path -LiteralPath $privacyPath -PathType Leaf) {
    $privacyText = Get-Content -LiteralPath $privacyPath -Raw -Encoding UTF8
    foreach ($requiredPrivacyTerm in @('skill-inventory-audit', 'project-skill-audit', '--include-usage', 'raw session')) {
        if ($privacyText -notmatch [regex]::Escape($requiredPrivacyTerm)) {
            Add-Failure "Privacy documentation is missing: $requiredPrivacyTerm"
        }
    }
}

$noticePath = Join-Path $repositoryRoot 'THIRD_PARTY_NOTICES.md'
if (Test-Path -LiteralPath $noticePath -PathType Leaf) {
    $noticeText = Get-Content -LiteralPath $noticePath -Raw -Encoding UTF8
    foreach ($requiredNotice in @(
        'steipete/agent-scripts',
        '49f5dfdc0e3020550c64ea5feb5ede16ad52d2c3',
        'Dimillian/Skills',
        '05ba982bfeb0d77d3c97d4542b0ee15034d05f84'
    )) {
        if ($noticeText -notmatch [regex]::Escape($requiredNotice)) {
            Add-Failure "Third-party notice is missing: $requiredNotice"
        }
    }
}

if (Test-Path -LiteralPath $reviewerCases -PathType Leaf) {
    $caseText = Get-Content -LiteralPath $reviewerCases -Raw -Encoding UTF8
    $positiveCount = [regex]::Matches($caseText, '(?m)^## Positive [1-5]:').Count
    $negativeCount = [regex]::Matches($caseText, '(?m)^## Negative [1-3]:').Count
    if ($positiveCount -ne 5) {
        Add-Failure "Reviewer cases contain $positiveCount positive cases; expected 5"
    }
    if ($negativeCount -ne 3) {
        Add-Failure "Reviewer cases contain $negativeCount negative cases; expected 3"
    }
}

$drawioSkillPath = Join-Path $drawioRoot 'SKILL.md'
if (Test-Path -LiteralPath $drawioSkillPath -PathType Leaf) {
    $expectedDrawioHash = '305CCB67F949E3DA2A6FF0E2DC7ADFF591C3FE6E5657E6EC18559492FE1FEAE4'
    $actualDrawioHash = (Get-FileHash -LiteralPath $drawioSkillPath -Algorithm SHA256).Hash
    if ($actualDrawioHash -ne $expectedDrawioHash) {
        Add-Failure "Vendored drawio SKILL.md hash changed: $actualDrawioHash"
    }
}

$textFiles = Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.FullName -notmatch '[\\/]dist[\\/]' -and
        $_.Extension -in @('.md', '.yaml', '.yml', '.json', '.ps1', '.py', '.txt', '.svg')
    }

$forbiddenPatterns = @(
    '(?i)[A-Z]:\\Users\\[^\\\s]+\\',
    ('(?i)wat3rsh3d[\\/]codex-' + 'skills'),
    ('(?i)rep' + 'tar09'),
    ('(?i)tim' + '\.owen09'),
    ('(?i)migrate publishing ' + 'identity'),
    '(?i)(?:gho|ghp|github_pat)_[A-Za-z0-9_]{12,}',
    '(?i)sk-[A-Za-z0-9_-]{12,}',
    '(?i)BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY'
)

foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($pattern in $forbiddenPatterns) {
        if ([regex]::IsMatch($content, $pattern)) {
            Add-Failure "Potential private data in $($file.FullName): $pattern"
        }
    }
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    Add-Failure 'Python 3 is required to run the Skill Maintenance synthetic tests'
} else {
    $unittestRunner = 'import sys, unittest; suite = unittest.defaultTestLoader.loadTestsFromName(sys.argv[1]); result = unittest.TextTestRunner(stream=sys.stdout, verbosity=2).run(suite); raise SystemExit(0 if result.wasSuccessful() else 1)'
    foreach ($testModule in @('tests.test_skill_inventory_audit', 'tests.test_skill_contracts')) {
        $testOutput = & $pythonCommand.Source -c $unittestRunner $testModule 2>&1
        $testExitCode = $LASTEXITCODE
        $testOutput | Write-Output
        if ($testExitCode -ne 0) {
            Add-Failure "Python test module failed: $testModule"
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "ERROR: $_" }
    exit 1
}

Write-Output 'REPOSITORY_VALIDATION: PASS'
Write-Output "root=$repositoryRoot"
