[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$pluginRoot = Join-Path $repositoryRoot 'plugins\goal-workflows'
$skillsRoot = Join-Path $pluginRoot 'skills'
$distRoot = Join-Path $repositoryRoot 'dist'
$expectedDistRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'dist'))

& (Join-Path $PSScriptRoot 'validate-repository.ps1')

if ([IO.Path]::GetFullPath($distRoot) -ne $expectedDistRoot) {
    throw "Unexpected dist path: $distRoot"
}

if (Test-Path -LiteralPath $distRoot) {
    Remove-Item -LiteralPath $distRoot -Recurse -Force
}

$pluginStageParent = Join-Path $distRoot '.staging\plugin'
$skillsStageRoot = Join-Path $distRoot '.staging\skills'
New-Item -ItemType Directory -Force -Path $pluginStageParent, $skillsStageRoot | Out-Null

$stagedPluginRoot = Join-Path $pluginStageParent 'goal-workflows'
Copy-Item -LiteralPath $pluginRoot -Destination $stagedPluginRoot -Recurse
Copy-Item -LiteralPath (Join-Path $skillsRoot 'gp') -Destination (Join-Path $skillsStageRoot 'gp') -Recurse
Copy-Item -LiteralPath (Join-Path $skillsRoot 'gp-relay') -Destination (Join-Path $skillsStageRoot 'gp-relay') -Recurse

$pluginArchive = Join-Path $distRoot 'goal-workflows-plugin.zip'
$skillsArchive = Join-Path $distRoot 'goal-workflows-skills.zip'
Compress-Archive -LiteralPath $stagedPluginRoot -DestinationPath $pluginArchive -CompressionLevel Optimal
Compress-Archive -Path (Join-Path $skillsStageRoot '*') -DestinationPath $skillsArchive -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ZipEntries([string]$Path) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        return @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    } finally {
        $archive.Dispose()
    }
}

$pluginEntries = Get-ZipEntries $pluginArchive
$skillsEntries = Get-ZipEntries $skillsArchive

if (-not ($pluginEntries -contains 'goal-workflows/.codex-plugin/plugin.json')) {
    throw 'Plugin archive is missing goal-workflows/.codex-plugin/plugin.json'
}
if (-not ($pluginEntries -contains 'goal-workflows/skills/gp/SKILL.md')) {
    throw 'Plugin archive is missing the gp skill'
}
if (-not ($pluginEntries -contains 'goal-workflows/skills/gp-relay/SKILL.md')) {
    throw 'Plugin archive is missing the gp-relay skill'
}
if (-not ($skillsEntries -contains 'gp/SKILL.md')) {
    throw 'Skills archive is missing gp/SKILL.md'
}
if (-not ($skillsEntries -contains 'gp-relay/SKILL.md')) {
    throw 'Skills archive is missing gp-relay/SKILL.md'
}

$stagingRoot = Join-Path $distRoot '.staging'
if ([IO.Path]::GetFullPath($stagingRoot).StartsWith($expectedDistRoot, [StringComparison]::OrdinalIgnoreCase)) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
} else {
    throw "Refusing to remove unexpected staging path: $stagingRoot"
}

Write-Output 'SUBMISSION_BUILD: PASS'
Get-FileHash -Algorithm SHA256 $skillsArchive, $pluginArchive |
    Select-Object Algorithm, Hash, Path
