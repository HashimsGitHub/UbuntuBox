# Apply-TerminalTheme.ps1
# Installs Hack Nerd Font and applies xcad theme ONLY to the UbuntuBox profile
# in Windows Terminal. All other profiles and the user's theme are untouched.
# On uninstall, UninstallTerminalTheme.ps1 fully reverses every change.
# UbuntuBox v2.2 - Hashim Hilal

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  UbuntuBox - Terminal Theme Installer   " -ForegroundColor Cyan
Write-Host "  Font : Hack Nerd Font Mono, size 14    " -ForegroundColor Cyan
Write-Host "  Theme: xcad  (UbuntuBox profile only)  " -ForegroundColor Cyan
Write-Host "  Your existing theme is NOT changed.    " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# STEP 1 - Install Hack Nerd Font (per-user, no admin required)
#          Records a manifest of installed files so uninstall is clean.
# ------------------------------------------------------------------
Write-Host "[1/3] Installing Hack Nerd Font..." -ForegroundColor Yellow

$FontDir     = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$FontReg     = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$TempZip     = "$env:TEMP\HackNerdFont.zip"
$TempDir     = "$env:TEMP\HackNerdFont"
$FontUrl     = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
$ManifestDir = "$env:LOCALAPPDATA\UbuntuBox"
$Manifest    = "$ManifestDir\installed-fonts.txt"

$alreadyInstalled = $false
try {
    $regProps = Get-Item $FontReg -ErrorAction SilentlyContinue
    if ($regProps) {
        $alreadyInstalled = ($regProps.Property | Where-Object { $_ -like "*Hack Nerd Font*" }).Count -gt 0
    }
} catch {}

if ($alreadyInstalled) {
    Write-Host "  OK Hack Nerd Font already installed - skipping download" -ForegroundColor Green
} else {
    Write-Host "  Downloading from GitHub (this may take a moment)..." -ForegroundColor Gray
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $FontUrl -OutFile $TempZip -UseBasicParsing
    } catch {
        Write-Host ""
        Write-Host "  ERROR: Download failed - $_" -ForegroundColor Red
        Write-Host "  Download Hack Nerd Font manually from: https://www.nerdfonts.com/font-downloads" -ForegroundColor Yellow
        Write-Host "  Install the TTF files then re-run this script." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }

    Write-Host "  Extracting..." -ForegroundColor Gray
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
    Remove-Item $TempZip -Force

    if (-not (Test-Path $FontDir))     { New-Item -ItemType Directory -Path $FontDir     -Force | Out-Null }
    if (-not (Test-Path $ManifestDir)) { New-Item -ItemType Directory -Path $ManifestDir -Force | Out-Null }

    $installedNames = [System.Collections.ArrayList]@()
    foreach ($font in (Get-ChildItem -Path $TempDir -Include "*.ttf","*.otf" -Recurse)) {
        $dest    = Join-Path $FontDir $font.Name
        Copy-Item $font.FullName -Destination $dest -Force
        $regName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name) + " (TrueType)"
        New-ItemProperty -Path $FontReg -Name $regName -Value $font.Name -PropertyType String -Force | Out-Null
        $installedNames.Add($font.Name) | Out-Null
    }
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    # Manifest lets the uninstaller remove only the files we added
    $installedNames | Set-Content $Manifest -Encoding UTF8
    Write-Host "  OK Installed $($installedNames.Count) font files" -ForegroundColor Green
    Write-Host "  Manifest saved for clean uninstall" -ForegroundColor Gray
}

# ------------------------------------------------------------------
# STEP 2 - Apply xcad scheme + font ONLY to the UbuntuBox profile.
#          profiles.defaults is NOT touched - user theme preserved.
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Applying xcad theme to UbuntuBox profile only..." -ForegroundColor Yellow

$WTSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:APPDATA\Microsoft\Windows Terminal\settings.json"
)

$WTSettings = $null
foreach ($p in $WTSettingsPaths) { if (Test-Path $p) { $WTSettings = $p; break } }

if (-not $WTSettings) {
    Write-Host "  ERROR: Windows Terminal settings.json not found." -ForegroundColor Red
    Write-Host "  Open Windows Terminal at least once, then re-run this script." -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"
    exit 1
}

Write-Host "  Found: $WTSettings" -ForegroundColor Gray

# Save one clean backup (fixed name so uninstaller can restore it)
$Backup = $WTSettings + ".ubuntubox_backup"
if (-not (Test-Path $Backup)) {
    Copy-Item $WTSettings $Backup -Force
    Write-Host "  Original settings backed up: $(Split-Path $Backup -Leaf)" -ForegroundColor Gray
} else {
    Write-Host "  Backup already exists - keeping original" -ForegroundColor Gray
}

# Parse (strip // comments and trailing commas first)
$raw = Get-Content $WTSettings -Raw -Encoding UTF8
$raw = $raw -replace '(?m)^\s*//.*$', ''
$raw = $raw -replace ',(\s*[}\]])', '$1'

try {
    $settings = $raw | ConvertFrom-Json
} catch {
    Write-Host "  ERROR: Could not parse settings.json - $_" -ForegroundColor Red
    Write-Host "  Restore your backup from: $Backup" -ForegroundColor Yellow
    Read-Host "  Press Enter to exit"
    exit 1
}

# 2a. Add xcad to schemes array (only if not already present)
$xcadScheme = [PSCustomObject]@{
    name                = "xcad"
    background          = "#1A1A1A"
    foreground          = "#F1F1F1"
    black               = "#121212"
    blue                = "#2B4FFF"
    brightBlack         = "#666666"
    brightBlue          = "#5C78FF"
    brightCyan          = "#5AC8FF"
    brightGreen         = "#905AFF"
    brightPurple        = "#5EA2FF"
    brightRed           = "#BA5AFF"
    brightWhite         = "#FFFFFF"
    brightYellow        = "#685AFF"
    cursorColor         = "#FFFFFF"
    cyan                = "#28B9FF"
    green               = "#7129FF"
    purple              = "#2883FF"
    red                 = "#A52AFF"
    selectionBackground = "#FFFFFF"
    white               = "#F1F1F1"
    yellow              = "#3D2AFF"
}

if (-not ($settings.PSObject.Properties.Name -contains "schemes")) {
    $settings | Add-Member -NotePropertyName "schemes" -NotePropertyValue @()
}
$schemeList = [System.Collections.ArrayList]@($settings.schemes)
$xcadIdx = -1
for ($i = 0; $i -lt $schemeList.Count; $i++) {
    if ($schemeList[$i].name -eq "xcad") { $xcadIdx = $i; break }
}
if ($xcadIdx -ge 0) {
    $schemeList[$xcadIdx] = $xcadScheme
} else {
    $schemeList.Add($xcadScheme) | Out-Null
}
$settings.schemes = $schemeList.ToArray()
Write-Host "  xcad color scheme registered" -ForegroundColor Gray

# 2b. Find UbuntuBox entry in profiles.list and patch ONLY that entry
$ubuntuBoxNames = @("UbuntuBox", "UbuntuBox (WSL)")
$patchedProfile  = $false

if ($settings.PSObject.Properties.Name -contains "profiles" -and
    $settings.profiles.PSObject.Properties.Name -contains "list") {

    $profileList = $settings.profiles.list
    for ($i = 0; $i -lt $profileList.Count; $i++) {
        $prof     = $profileList[$i]
        $profName = if ($prof.PSObject.Properties.Name -contains "name") { $prof.name } else { "" }

        if ($ubuntuBoxNames -contains $profName) {
            # These props go on the UbuntuBox profile ONLY
            $fontObj   = [PSCustomObject]@{ face = "Hack Nerd Font Mono"; size = 14 }
            $propsToSet = @{
                colorScheme    = "xcad"
                font           = $fontObj
                cursorShape    = "filledBox"
                opacity        = 95
                padding        = "8"
                useAcrylic     = $false
                historySize    = 12000
                scrollbarState = "visible"
            }
            foreach ($key in $propsToSet.Keys) {
                if ($prof.PSObject.Properties.Name -contains $key) {
                    $prof.$key = $propsToSet[$key]
                } else {
                    $prof | Add-Member -NotePropertyName $key -NotePropertyValue $propsToSet[$key]
                }
            }
            $profileList[$i] = $prof
            $patchedProfile  = $true
            Write-Host "  OK xcad + Hack Nerd Font applied to '$profName' only" -ForegroundColor Green
        }
    }
    $settings.profiles.list = $profileList
}

if (-not $patchedProfile) {
    Write-Host "  NOTE: UbuntuBox profile not yet in Windows Terminal list." -ForegroundColor Yellow
    Write-Host "  xcad scheme is registered and ready." -ForegroundColor Gray
    Write-Host "  Open UbuntuBox once so Windows Terminal creates its profile," -ForegroundColor Gray
    Write-Host "  then re-run this script to apply the font and theme to it." -ForegroundColor Gray
}

$settings | ConvertTo-Json -Depth 20 | Set-Content $WTSettings -Encoding UTF8
Write-Host "  OK settings.json saved - all other profiles untouched" -ForegroundColor Green

# ------------------------------------------------------------------
# STEP 3 - Optional: Starship prompt inside UbuntuBox
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Starship prompt (optional)..." -ForegroundColor Yellow

$wslOut = $null
try { $wslOut = (wsl --list --quiet 2>&1 | Out-String) } catch {}

if ($wslOut -and $wslOut -match "UbuntuBox") {
    $choice = Read-Host "  Install Starship prompt inside UbuntuBox for icons and git status? (y/N)"
    if ($choice -match "^[Yy]$") {
        Write-Host "  Installing Starship inside UbuntuBox..." -ForegroundColor Gray
        wsl -d UbuntuBox -- bash -c "curl -sS https://starship.rs/install.sh | sh -s -- --yes && grep -qxF 'eval `"`$(starship init bash)`"' ~/.bashrc || echo 'eval `"`$(starship init bash)`"' >> ~/.bashrc"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK Starship installed - activates on next terminal open" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Starship install may have failed. Run inside Ubuntu:" -ForegroundColor Yellow
            Write-Host "    curl -sS https://starship.rs/install.sh | sh" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Skipped." -ForegroundColor Gray
    }
} else {
    Write-Host "  UbuntuBox not detected - skipping Starship." -ForegroundColor Gray
    Write-Host "  Launch UbuntuBox first, then re-run to add Starship." -ForegroundColor Gray
}

# ------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  DONE! Restart Windows Terminal now.    " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Summary:" -ForegroundColor White
Write-Host "    UbuntuBox profile -> xcad theme + Hack Nerd Font Mono 14" -ForegroundColor Green
Write-Host "    All other profiles -> UNCHANGED" -ForegroundColor Gray
Write-Host "    Your default theme -> UNCHANGED" -ForegroundColor Gray
Write-Host ""
Write-Host "  On uninstall, everything above is fully reversed." -ForegroundColor Gray
Write-Host ""
