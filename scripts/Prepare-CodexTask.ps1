#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Audit', 'Refactor', 'Feature', 'Docs')]
    [string]$Type,

    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9][a-z0-9._-]*$')]
    [string]$Name,

    [string]$BaseBranch = 'main',

    [switch]$Push
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoPath = Split-Path -Parent $PSScriptRoot
Set-Location $RepoPath

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed."
    }
}

$status = (& git status --porcelain) -join "`n"
if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw "Working tree is not clean. Commit or stash current work first.`n$status"
}

Invoke-Git -Arguments @('switch', $BaseBranch)
Invoke-Git -Arguments @('pull', '--ff-only', 'origin', $BaseBranch)

$prefix = switch ($Type) {
    'Audit'    { 'audit' }
    'Refactor' { 'refactor' }
    'Feature'  { 'feature' }
    'Docs'     { 'docs' }
}

$branch = "$prefix/$Name"
$existing = (& git branch --list $branch) -join ''

if ([string]::IsNullOrWhiteSpace($existing)) {
    Invoke-Git -Arguments @('switch', '-c', $branch)
}
else {
    Invoke-Git -Arguments @('switch', $branch)
}

if ($Push) {
    Invoke-Git -Arguments @('push', '-u', 'origin', $branch)
}

Write-Host ''
Write-Host "Prepared branch: $branch" -ForegroundColor Green
Write-Host 'Open docs/workflow_prompts.md and use the matching prompt.' -ForegroundColor Cyan
