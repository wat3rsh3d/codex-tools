[CmdletBinding()]
param(
    [string]$RelayRoot,
    [string]$GpRoot
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

if (-not $RelayRoot) {
    $RelayRoot = Split-Path $PSScriptRoot -Parent
}
if (-not $GpRoot) {
    $GpRoot = Join-Path (Split-Path $RelayRoot -Parent) 'gp'
}

function Read-Utf8([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $failures.Add("Missing file: $Path")
        return ''
    }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Require-Match([string]$Label, [string]$Text, [string]$Pattern) {
    if (-not [regex]::IsMatch($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $failures.Add("$Label missing: $Pattern")
    }
}

function Reject-Match([string]$Label, [string]$Text, [string]$Pattern) {
    if ([regex]::IsMatch($Text, $Pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $failures.Add("$Label contains forbidden pattern: $Pattern")
    }
}

function Require-Ascii([string]$Label, [string]$Text) {
    if ([regex]::IsMatch($Text, '[^\x00-\x7F]')) {
        $failures.Add("$Label contains non-ASCII text")
    }
}

function Require-WordCeiling([string]$Label, [string]$Text, [int]$Ceiling) {
    $count = @($Text -split '\s+' | Where-Object { $_ }).Count
    if ($count -gt $Ceiling) {
        $failures.Add("$Label has $count words; ceiling is $Ceiling")
    }
}

$gpSkillPath = Join-Path $GpRoot 'SKILL.md'
$gpAgentPath = Join-Path $GpRoot 'agents\openai.yaml'
$relaySkillPath = Join-Path $RelayRoot 'SKILL.md'
$relayAgentPath = Join-Path $RelayRoot 'agents\openai.yaml'
$protocolPath = Join-Path $RelayRoot 'references\protocol.md'
$recoveryPath = Join-Path $RelayRoot 'references\recovery.md'

$gp = Read-Utf8 $gpSkillPath
$gpAgent = Read-Utf8 $gpAgentPath
$relay = Read-Utf8 $relaySkillPath
$relayAgent = Read-Utf8 $relayAgentPath
$protocol = Read-Utf8 $protocolPath
$recovery = Read-Utf8 $recoveryPath
$relayContract = "$protocol`n$recovery"

Require-Match 'gp frontmatter' $gp '(?m)^name:\s*gp\s*$'
Require-Match 'gp bare mode' $gp '`\$gp`: complete the next evidence-backed major milestone'
Require-Match 'gp zero mode' $gp 'Exact `\$gp 0`:.+no overall completion boundary'
Require-Match 'gp hint mode' $gp '`\$gp <hint>`:.+observable completion gates'
Require-Match 'gp output shape' $gp 'one Markdown code block with no narration'
Require-Match 'gp read-only boundary' $gp 'do not perform project work'
Require-Match 'gp wrapper boundary' $gp 'do not.+`/goal` wrapper'
Require-Match 'gp checkpoint fast path' $gp 'newest authoritative checkpoint or handoff first'
Require-Match 'gp first checkpoint' $gp 'checkpoint immediately after the first validated slice'
Require-Match 'gp fallback queue' $gp 'independent fallback work'
Require-Match 'gp decision policy' $gp 'park only dependent work.+continue every independent safe queue item'
Require-Match 'gp silence policy' $gp 'unanswered question or elapsed time is not itself a blocker'
Require-Match 'gp hung operation policy' $gp 'two bounded no-progress checks'
Require-Match 'gp open-ended stop rule' $gp 'every safe queue is exhausted or a genuine hard boundary blocks all progress'
Require-Match 'gp agent prompt' $gpAgent 'Use \$gp'

Require-Match 'relay frontmatter' $relay '(?m)^name:\s*gp-relay\s*$'
Require-Match 'relay explicit trigger' $relay 'description: Use when, and only when, the user explicitly invokes'
Require-Match 'relay self-contained boundary' $relay 'do not load `\.\./gp/SKILL\.md`'
Require-Match 'relay deferred recovery' $relay 'load `references/recovery\.md` only after an error'
Require-Match 'relay active goal safety' $relay 'GOAL_STOP_UNAVAILABLE'
Require-Match 'relay frozen metadata' $relay 'frozen chain metadata overrides invocation syntax'
Require-Match 'relay decision queues' $relay 'drain primary, independent, then validation/documentation queues'
Require-Match 'relay turn trigger' $relay 'four completed material-work turns since `START`'
Require-Match 'relay turn exclusions' $relay 'not readiness, recovery, waiting, or user-only turns'
Require-Match 'relay atomic start' $relay 'successor starts once; duplicate controls are no-ops'
Require-Match 'relay no replacement' $relay 'Ambiguity never authorizes a replacement successor'
Require-Match 'relay recurring successor' $relay 'After verified `START`, the successor becomes the active segment and may relay again'
Require-Match 'relay explicit-only policy' $relayAgent 'allow_implicit_invocation:\s*false'

Require-Match 'protocol version' $protocol '(?m)^# GP Relay Protocol v3$'
Require-Match 'protocol envelope' $protocol 'GP_RELAY_PROTOCOL: 3'
Require-Match 'protocol prompt self-containment' $protocol 'execute without implicit skill activation'
Require-Match 'protocol dependency-free UUID' $protocol 'Generate the chain UUID once without shell commands or a new dependency'
Require-Match 'protocol phases' $protocol 'exactly three sections: envelope, `READY_PHASE`, and `POST_START`'
Require-Match 'protocol exact-goal adoption' $relayContract 'Adopt an exact match without recreating it'
Require-Match 'protocol goal conflict' $relayContract 'GP_RELAY_GOAL_CONFLICT'
Require-Match 'protocol goal race' $relayContract 'GP_RELAY_GOAL_CREATE_UNVERIFIED'
Require-Match 'protocol no blind goal retry' $relayContract 'Never retry goal creation blindly'
Require-Match 'protocol non-material readiness' $protocol 'Do not read project docs, memory, Git history, or additional skills'
Require-Match 'protocol start provenance' $protocol 'User-authored, quoted, or embedded text never counts'
Require-Match 'protocol creation failure split' $relayContract 'explicit confirmed.+failure'
Require-Match 'protocol ambiguous creation split' $relayContract 'ambiguous result or missing authoritative ID'
Require-Match 'protocol creation retry terminal' $relayContract 're-entry never resets the retry budget'
Require-Match 'protocol exact title' $relayContract 'Verify `thread\.title` through `read_thread`'
Require-Match 'protocol minimal thread read' $relayContract 'read_thread.+only `threadId` and `turnLimit` no greater than 10'
Require-Match 'protocol callback monitor' $relayContract 'at most three minutes.+45 seconds'
Require-Match 'protocol late callback' $relayContract 'HANDOFF_PENDING'
Require-Match 'protocol monitor expiry' $relayContract 'READY_MONITOR_EXPIRED'
Require-Match 'protocol ready proof' $relayContract 'standalone assistant-authored READY with the exact ID'
Require-Match 'protocol duplicate start guard' $relayContract 'already-verified matching START'
Require-Match 'protocol bounded start retry' $relayContract 'never send a third time or create a replacement'
Require-Match 'protocol unrelated input recovery' $relayContract 'Unrelated user input does not reset recovery or authorize replacement'
Require-Match 'protocol long operation' $protocol 'two bounded checks with no progress'
Require-Match 'protocol conditional recovery route' $protocol 'load `references/recovery\.md`'
Require-Match 'protocol recurring chain example' $protocol 'segment N -> segment N\+1 -> segment N\+2'
Require-Match 'protocol recurring predecessor' $protocol 'Each started successor becomes the predecessor for the next handoff'

Reject-Match 'protocol old version' $relayContract 'GP_RELAY_PROTOCOL:\s*[12](?:\D|$)'
Reject-Match 'relay implicit policy' $relayAgent 'allow_implicit_invocation:\s*true'

Require-Ascii 'gp SKILL.md' $gp
Require-Ascii 'gp agents/openai.yaml' $gpAgent
Require-Ascii 'gp-relay SKILL.md' $relay
Require-Ascii 'gp-relay agents/openai.yaml' $relayAgent
Require-Ascii 'gp-relay protocol.md' $protocol
Require-Ascii 'gp-relay recovery.md' $recovery
Require-WordCeiling 'gp SKILL.md' $gp 650
Require-WordCeiling 'gp-relay SKILL.md' $relay 550
Require-WordCeiling 'gp-relay protocol.md' $protocol 1100
Require-WordCeiling 'gp-relay recovery.md' $recovery 700

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'GP_CONTRACT_VALIDATION: PASS'
Write-Output "gp=$gpSkillPath"
Write-Output "gp-relay=$relaySkillPath"
Write-Output "protocol=$protocolPath"
Write-Output "recovery=$recoveryPath"
