param(
    [string]$PoBRoot
)

$ErrorActionPreference = "Stop"

$rootCandidates = @()
if ($PoBRoot) { $rootCandidates += $PoBRoot }
if ($env:POB2_PATH) { $rootCandidates += $env:POB2_PATH }
$ScriptRoot = $PSScriptRoot
if (Test-Path (Join-Path $ScriptRoot "payload")) {
    $PackageRoot = $ScriptRoot
} else {
    $PackageRoot = Split-Path (Split-Path $ScriptRoot -Parent) -Parent
}
$rootCandidates += $PackageRoot
$rootCandidates += (Split-Path $PackageRoot -Parent)

$root = $null
foreach ($candidate in $rootCandidates) {
    if ($candidate -and (Test-Path (Join-Path $candidate "Launch.lua"))) {
        $root = (Resolve-Path $candidate).Path
        break
    }
}
if (-not $root) { throw "PoB2 root not found" }

Write-Host "PoB2 root: $root"

$runtimeMarker = Join-Path $root ".pob2jp-runtime.json"
if (Test-Path $runtimeMarker) {
    try {
        $runtimeState = Get-Content -LiteralPath $runtimeMarker -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($name in @($runtimeState.added)) {
            if (-not $name) { continue }
            $addedPath = Join-Path $root $name
            if (Test-Path $addedPath) {
                Remove-Item -LiteralPath $addedPath -Force
                Write-Host "Removed added runtime file: $name"
            }
        }
    } catch {
        Write-Host "Warning: failed to read runtime marker: $runtimeMarker"
    }
    Remove-Item -LiteralPath $runtimeMarker -Force
}

$jpModule = Join-Path $root "Modules\PoeJP"
if (Test-Path $jpModule) {
    Remove-Item -LiteralPath $jpModule -Recurse -Force
    Write-Host "Removed Modules\PoeJP"
}

$jpTranslate = Join-Path $root "Data\Translate\ja-JP"
if (Test-Path $jpTranslate) {
    Remove-Item -LiteralPath $jpTranslate -Recurse -Force
    Write-Host "Removed Data\Translate\ja-JP"
}

$fontDir = Join-Path $root "SimpleGraphic\Fonts"
foreach ($fontName in @("JpUI.ttf", "JpUI-Bold.ttf")) {
    $fontPath = Join-Path $fontDir $fontName
    if (Test-Path $fontPath) {
        Remove-Item -LiteralPath $fontPath -Force
        Write-Host "Removed font file: $fontName"
    }
}

$backups = @(Get-ChildItem -LiteralPath $root -Filter "*.pob2jp.bak" -Recurse -Force | Sort-Object FullName -Descending)
if ($backups.Count -eq 0) {
    Write-Host "No PoB2-JP backups found"
    exit 0
}

foreach ($backup in $backups) {
    $target = $backup.FullName.Substring(0, $backup.FullName.Length - ".pob2jp.bak".Length)
    Copy-Item -LiteralPath $backup.FullName -Destination $target -Force
    Remove-Item -LiteralPath $backup.FullName -Force
    Write-Host "Restored $target"
}
Write-Host "PoB2-JP reset complete"
