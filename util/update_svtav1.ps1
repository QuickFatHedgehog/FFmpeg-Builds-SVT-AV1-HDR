# Windows wrapper around util/update_svtav1.sh.
#
# Usage:
#   ./util/update_svtav1.ps1 [-Ref <branch|tag|commit>] [-DryRun]
#
# Requires bash (Git for Windows provides it).

param(
    [string]$Ref = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$bash = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\usr\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $bash) {
    $bash = (Get-Command bash.exe -ErrorAction SilentlyContinue).Source
}
if (-not $bash) {
    throw "bash not found. Install Git for Windows or run util/update_svtav1.sh from a bash shell."
}

$bashArgs = @((Join-Path $PSScriptRoot "update_svtav1.sh"))
if ($Ref) { $bashArgs += @("--ref", $Ref) }
if ($DryRun) { $bashArgs += "--dry-run" }

& $bash @bashArgs
exit $LASTEXITCODE
