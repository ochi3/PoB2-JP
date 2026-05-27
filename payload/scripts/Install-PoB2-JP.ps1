param(
    [string]$PoBRoot,
    [string]$PayloadName = "payload",
    [switch]$NoRuntime,
    [switch]$NoHooks
)

$ErrorActionPreference = "Stop"

$PackageRoot = $PSScriptRoot
if (Test-Path (Join-Path $PackageRoot $PayloadName)) {
    $Payload = Join-Path $PackageRoot $PayloadName
} else {
    $ScriptPayload = Split-Path $PackageRoot -Parent
    $PackageRoot = Split-Path $ScriptPayload -Parent
    $RequestedPayload = Join-Path $PackageRoot $PayloadName
    if (Test-Path $RequestedPayload) {
        $Payload = $RequestedPayload
    } else {
        $Payload = $ScriptPayload
    }
}
$BackupSuffix = ".pob2jp.bak"
$OfficialSimpleGraphicMinSize = 2100000
$LaunchMarker = "-- pob2jp: load translator"
$MainMarker = "-- pob2jp: unicode detect"
$CommonMarker = "-- pob2jp: utf8 keep"

$RuntimeDlls = @(
    "SimpleGraphicExtend.dll",
    "abseil_dll.dll",
    "brotlicommon.dll",
    "brotlidec.dll",
    "bz2.dll",
    "fmt.dll",
    "glfw3.dll",
    "libGLESv2.dll",
    "libcurl.dll",
    "lua51.dll",
    "re2.dll",
    "zlib1.dll",
    "zstd.dll",
    "freetype.dll",
    "harfbuzz.dll",
    "fribidi-0.dll",
    "libwebp.dll",
    "libpng16.dll",
    "libquickjs.dll",
    "libsharpyuv.dll",
    "loadall.dll",
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll",
    "msvcp140_codecvt_ids.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

$FontTargets = @(
    "Liberation Sans.tgf",
    "Liberation Sans Bold.tgf",
    "Bitstream Vera Sans Mono.tgf",
    "Fontin.tgf",
    "Fontin Italic.tgf",
    "Fontin SmallCaps.tgf",
    "Fontin SmallCaps Italic.tgf"
)

$NoRuntime = [bool]$NoRuntime
$NoHooks = [bool]$NoHooks
$HasRuntimePayload = Test-Path (Join-Path $Payload "runtime\SimpleGraphicExtend.dll")
if (-not $HasRuntimePayload -and -not $NoRuntime) {
    Write-Host "Runtime payload not found; installing data-only safe localization."
    $NoRuntime = $true
    $NoHooks = $true
}

function Find-PoBRoot {
    param([string]$Requested)
    $candidates = @()
    if ($Requested) { $candidates += $Requested }
    if ($env:POB2_PATH) { $candidates += $env:POB2_PATH }
    $candidates += $PackageRoot
    $candidates += (Split-Path $PackageRoot -Parent)
    $candidates += (Get-Location).Path
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate "Launch.lua"))) {
            return (Resolve-Path $candidate).Path
        }
    }
    throw "PoB2 folder not found. Put this PoB2-JP folder inside the Path of Building Community (PoE2) folder, or run: .\Install-PoB2-JP.ps1 -PoBRoot `"D:\Path of Building Community (PoE2)`""
}

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $backup = "$Path$BackupSuffix"
        if (-not (Test-Path $backup)) {
            Copy-Item -LiteralPath $Path -Destination $backup -Force
        }
    }
}

function Copy-FileWithBackup {
    param([string]$Source, [string]$Destination)
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    Backup-File $Destination
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Copy-DirectoryClean {
    param([string]$Source, [string]$Destination)
    if (Test-Path $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination -Parent) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Set-TextUtf8NoBom {
    param([string]$Path, [string]$Value)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Patch-LaunchLua {
    param([string]$Path)
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($text.Contains("local function poejpSafeTranslate")) {
        Write-Host "Launch.lua already patched"
        return
    }
    if ($text.Contains($LaunchMarker)) {
        $backup = "$Path$BackupSuffix"
        if (Test-Path $backup) {
            Copy-Item -LiteralPath $backup -Destination $Path -Force
            $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
            Write-Host "Restored old Launch.lua hook before repatching"
        }
    }

    $oldHook = [string]::Join("`n", @(
"`t`tlocal _DrawString = DrawString",
"`t`tfunction DrawString(x, y, align, height, font, text)",
"`t`t`tif type(text) == `"string`" then",
"`t`t`t`ttext = poejp.tDisplay(text)",
"`t`t`tend",
"`t`t`treturn _DrawString(x, y, align, height, font, text)",
"`t`tend",
""
))

    $newHook = [string]::Join("`n", @(
"`t`tlocal function poejpSafeTranslate(text)",
"`t`t`tlocal ok, translated = pcall(poejp.tDisplay, text)",
"`t`t`tif ok and type(translated) == `"string`" then",
"`t`t`t`treturn translated",
"`t`t`tend",
"`t`t`treturn text",
"`t`tend",
"`t`tlocal _DrawString = DrawString",
"`t`tlocal _DrawStringWidth = DrawStringWidth",
"`t`tfunction DrawString(x, y, align, height, font, text)",
"`t`t`tif type(text) == `"string`" then",
"`t`t`t`ttext = poejpSafeTranslate(text)",
"`t`t`tend",
"`t`t`treturn _DrawString(x, y, align, height, font, text)",
"`t`tend",
"`t`tfunction DrawStringWidth(height, font, text)",
"`t`t`tif type(text) == `"string`" then",
"`t`t`t`ttext = poejpSafeTranslate(text)",
"`t`t`tend",
"`t`t`treturn _DrawStringWidth(height, font, text)",
"`t`tend",
""
))

    if ($text.Contains($LaunchMarker)) {
        if ($text.Contains($oldHook)) {
            Backup-File $Path
            $text = $text.Replace($oldHook, $newHook)
            Set-TextUtf8NoBom $Path $text
            Write-Host "Patched Launch.lua width hook"
            return
        }
        Write-Host "Launch.lua has an unknown existing PoB2-JP hook; skipped"
        return
    }

    $anchor = "`tRenderInit(`"DPI_AWARE`")"
    if (-not $text.Contains($anchor)) {
        throw "Launch.lua RenderInit anchor not found"
    }
    $block = [string]::Join("`n", @(
"`t-- pob2jp: load translator",
"`tlocal poejpLoadOk, poejpLoaded = pcall(LoadModule, `"Modules/PoeJP/Init`")",
"`tif poejpLoadOk then",
"`t`tpoejp = poejpLoaded",
"`telse",
"`t`tConPrintf(`"PoB2-JP: translator load failed: %s`", tostring(poejpLoaded))",
"`tend",
"`tif poejp and poejp.enabled then",
"`t`tConPrintf(`"PoB2-JP: %d translations loaded (%s)`", poejp.count, poejp.locale)",
"`t`tlocal function poejpSafeTranslate(text)",
"`t`t`tlocal ok, translated = pcall(poejp.tDisplay, text)",
"`t`t`tif ok and type(translated) == `"string`" then",
"`t`t`t`treturn translated",
"`t`t`tend",
"`t`t`treturn text",
"`t`tend",
"`t`tlocal _DrawString = DrawString",
"`t`tlocal _DrawStringWidth = DrawStringWidth",
"`t`tfunction DrawString(x, y, align, height, font, text)",
"`t`t`tif type(text) == `"string`" then",
"`t`t`t`ttext = poejpSafeTranslate(text)",
"`t`t`tend",
"`t`t`treturn _DrawString(x, y, align, height, font, text)",
"`t`tend",
"`t`tfunction DrawStringWidth(height, font, text)",
"`t`t`tif type(text) == `"string`" then",
"`t`t`t`ttext = poejpSafeTranslate(text)",
"`t`t`tend",
"`t`t`treturn _DrawStringWidth(height, font, text)",
"`t`tend",
"`telseif poejp then",
"`t`tConPrintf(`"PoB2-JP: translation CSV not loaded`")",
"`tend",
""
))
    Backup-File $Path
    $text = $text.Replace($anchor, "$anchor`n$block")
    Set-TextUtf8NoBom $Path $text
    Write-Host "Patched Launch.lua"
}

function Patch-MainLua {
    param([string]$Path)
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($text.Contains($MainMarker) -or $text.Contains("type(_G.poejp)")) {
        Write-Host "Main.lua already patched"
        return
    }
    $old = [string]::Join("`n", @(
"function main:DetectUnicodeSupport()",
"`t-- PoeCharm has utf8 global that normal PoB doesn't have",
"`tself.unicode = type(_G.utf8) == `"table`"",
"`tif self.unicode then",
"`t`tConPrintf(`"Unicode support detected`")",
"`tend",
"end",
""
))
    $oldCrLf = $old.Replace("`n", "`r`n")
    $new = [string]::Join("`n", @(
"function main:DetectUnicodeSupport()",
"`t-- pob2jp: unicode detect",
"`tself.unicode = type(_G.utf8) == `"table`" or type(_G.charm) == `"table`" or type(_G.poejp) == `"table`"",
"`tif self.unicode then",
"`t`tConPrintf(`"Unicode support detected`")",
"`tend",
"end",
""
))
    $newForFile = if ($text.Contains($oldCrLf)) { $new.Replace("`n", "`r`n") } else { $new }
    Backup-File $Path
    if ($text.Contains($oldCrLf)) {
        $text = $text.Replace($oldCrLf, $newForFile)
    } elseif ($text.Contains($old)) {
        $text = $text.Replace($old, $newForFile)
    } else {
        $pattern = 'function main:DetectUnicodeSupport\(\)\s+-- PoeCharm has utf8 global that normal PoB doesn''t have\s+self\.unicode = type\(_G\.utf8\) == "table"\s+if self\.unicode then\s+ConPrintf\("Unicode support detected"\)\s+end\s+end'
        $replaced = [regex]::Replace($text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newForFile }, 1)
        if ($replaced -eq $text) {
            Write-Host "Main.lua unicode block not found; skipped"
            return
        }
        $text = $replaced
    }
    Set-TextUtf8NoBom $Path $text
    Write-Host "Patched Main.lua"
}

function Patch-CommonLua {
    param([string]$Path)
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $changed = $false
    $oldGsub = "`t`t:gsub(`"[\128-\255]`", `"?`")"
    if ($text.Contains($oldGsub)) {
        $text = $text.Replace($oldGsub, "`t`t$CommonMarker`n`t`t-- :gsub(`"[\128-\255]`", `"?`")")
        $changed = $true
    }
    $oldMatch = "`t`tif self:match(orPattern) then"
    $newMatch = "`t`tif charm and charm.TranslateMatch and charm.TranslateMatch(self, orPattern) or self:match(orPattern) then"
    if ($text.Contains($oldMatch) -and -not $text.Contains($newMatch)) {
        $text = $text.Replace($oldMatch, $newMatch)
        $changed = $true
    }
    if (-not $changed) {
        Write-Host "Common.lua already patched or no known anchors"
        return
    }
    Backup-File $Path
    Set-TextUtf8NoBom $Path $text
    Write-Host "Patched Common.lua"
}

function First-Existing {
    param([string[]]$Paths)
    foreach ($path in $Paths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

function Install-Fonts {
    param([string]$Root)
    $winFonts = Join-Path $env:WINDIR "Fonts"
    $regular = First-Existing @(
        (Join-Path $winFonts "YuGothM.ttc"),
        (Join-Path $winFonts "YuGothR.ttc"),
        (Join-Path $winFonts "meiryo.ttc"),
        (Join-Path $winFonts "msgothic.ttc")
    )
    $bold = First-Existing @(
        (Join-Path $winFonts "YuGothB.ttc"),
        (Join-Path $winFonts "YuGothM.ttc"),
        (Join-Path $winFonts "meiryob.ttc"),
        (Join-Path $winFonts "meiryo.ttc"),
        (Join-Path $winFonts "msgothic.ttc")
    )
    if (-not $regular) {
        Write-Host "Japanese Windows font not found; skipped font override"
        return
    }
    if (-not $bold) { $bold = $regular }
    $fontDir = Join-Path $Root "SimpleGraphic\Fonts"
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    Copy-FileWithBackup $regular (Join-Path $fontDir "JpUI.ttf")
    Copy-FileWithBackup $bold (Join-Path $fontDir "JpUI-Bold.ttf")
    $tgf = "{`n  `"fonts`": [`n    {`"file`": `"JpUI.ttf`", `"scale`": 1.0}`n  ]`n}`n"
    foreach ($name in $FontTargets) {
        $target = Join-Path $fontDir $name
        Backup-File $target
        Set-TextUtf8NoBom $target $tgf
    }
    $cfg = Join-Path $Root "Launch.cfg"
    if (Test-Path $cfg) {
        $kept = Get-Content -LiteralPath $cfg -Encoding UTF8 | Where-Object { $_ -notmatch '^set\s+(font_name|font_resolution|font_spacing_x)\s+' }
        Backup-File $cfg
        if ($kept.Count -gt 0) {
            Set-Content -LiteralPath $cfg -Value $kept -Encoding UTF8
        } else {
            Remove-Item -LiteralPath $cfg -Force
        }
    }
}

function Install-Runtime {
    param([string]$Root)
    $runtimeRoot = Join-Path $Payload "runtime"
    foreach ($name in $RuntimeDlls) {
        $source = Join-Path $runtimeRoot $name
        if (-not (Test-Path $source)) { throw "Runtime file missing: $name" }
    }
    $simple = Join-Path $Root "SimpleGraphic.dll"
    $simpleIsCjk = (Test-Path $simple) -and ((Get-Item $simple).Length -lt $OfficialSimpleGraphicMinSize)
    if (-not $simpleIsCjk) {
        Copy-FileWithBackup (Join-Path $runtimeRoot "SimpleGraphicExtend.dll") $simple
    }
    $added = @()
    foreach ($name in $RuntimeDlls) {
        if ($name -eq "SimpleGraphicExtend.dll") { continue }
        $dst = Join-Path $Root $name
        if ($simpleIsCjk -and (Test-Path $dst)) { continue }
        if (-not (Test-Path $dst)) { $added += $name }
        Copy-FileWithBackup (Join-Path $runtimeRoot $name) $dst
    }
    Install-Fonts $Root
    $marker = @{ added = $added } | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath (Join-Path $Root ".pob2jp-runtime.json") -Value $marker -Encoding UTF8
}

function Restore-RuntimeBackups {
    param([string]$Root)
    $names = @("SimpleGraphic.dll")
    foreach ($name in $RuntimeDlls) {
        if ($name -ne "SimpleGraphicExtend.dll") {
            $names += $name
        }
    }
    foreach ($name in $names) {
        $target = Join-Path $Root $name
        $backup = "$target$BackupSuffix"
        if (Test-Path $backup) {
            Copy-Item -LiteralPath $backup -Destination $target -Force
            Write-Host "Restored runtime backup: $name"
        }
    }
}

function Restore-HookBackups {
    param([string]$Root)
    $paths = @(
        (Join-Path $Root "Launch.lua"),
        (Join-Path $Root "Modules\Main.lua"),
        (Join-Path $Root "Modules\Common.lua")
    )
    foreach ($target in $paths) {
        $backup = "$target$BackupSuffix"
        if (Test-Path $backup) {
            Copy-Item -LiteralPath $backup -Destination $target -Force
            Write-Host "Restored hook backup: $target"
        }
    }
}

$Root = Find-PoBRoot $PoBRoot
Write-Host "PoB2 root: $Root"

Copy-DirectoryClean (Join-Path $Payload "Data\Translate\ja-JP") (Join-Path $Root "Data\Translate\ja-JP")
Copy-FileWithBackup (Join-Path $Payload "Data\Translate.json") (Join-Path $Root "Data\Translate.json")
Copy-FileWithBackup (Join-Path $Payload "Data\Settings.conf") (Join-Path $Root "Data\Settings.conf")

if ($NoRuntime) {
    Restore-RuntimeBackups $Root
} else {
    Copy-DirectoryClean (Join-Path $Payload "Modules\PoeJP") (Join-Path $Root "Modules\PoeJP")
    Patch-LaunchLua (Join-Path $Root "Launch.lua")
    Patch-MainLua (Join-Path $Root "Modules\Main.lua")
    Patch-CommonLua (Join-Path $Root "Modules\Common.lua")
    Install-Runtime $Root
}

if ($NoHooks) {
    Restore-HookBackups $Root
} elseif ($NoRuntime) {
    Copy-DirectoryClean (Join-Path $Payload "Modules\PoeJP") (Join-Path $Root "Modules\PoeJP")
    Patch-LaunchLua (Join-Path $Root "Launch.lua")
}

Write-Host "PoB2-JP install complete"
