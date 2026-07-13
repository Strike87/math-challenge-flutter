#Requires -Version 5.1
[CmdletBinding()]
param(
    [string[]]$FocusedTests = @(),

    [switch]$AllowPub,

    [switch]$SkipFull,

    [switch]$SkipVisual,

    [switch]$SkipAnalyze
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoPath = Split-Path -Parent $PSScriptRoot
Set-Location $RepoPath

function Run-Step {
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][scriptblock]$Command
    )

    Write-Host ''
    Write-Host "==> $Label" -ForegroundColor Cyan
    & $Command

    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

foreach ($test in $FocusedTests) {
    $flutterArgs = @('test', $test, '--reporter', 'compact')
    if (-not $AllowPub) {
        $flutterArgs += '--no-pub'
    }

    Run-Step "Focused test: $test" {
        & flutter @flutterArgs
    }
}

if (-not $SkipFull) {
    $flutterArgs = @('test', '--reporter', 'compact', '--exclude-tags', 'golden')
    if (-not $AllowPub) {
        $flutterArgs += '--no-pub'
    }

    Run-Step 'Full non-golden suite' {
        & flutter @flutterArgs
    }
}

if (-not $SkipVisual) {
    $flutterArgs = @(
        'test',
        'test\visual_parity_test.dart',
        '--reporter',
        'compact'
    )
    if (-not $AllowPub) {
        $flutterArgs += '--no-pub'
    }

    Run-Step 'Visual parity suite' {
        & flutter @flutterArgs
    }
}

if (-not $SkipAnalyze) {
    $flutterArgs = @('analyze')
    if (-not $AllowPub) {
        $flutterArgs += '--no-pub'
    }

    Run-Step 'Flutter analyze' {
        & flutter @flutterArgs
    }
}

Run-Step 'Git whitespace check' {
    & git diff --check
}

Write-Host ''
Write-Host 'Validation completed successfully.' -ForegroundColor Green
& git status --short
