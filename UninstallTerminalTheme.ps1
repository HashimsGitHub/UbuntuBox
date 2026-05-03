# UninstallTerminalTheme.ps1
# Reverses everything Apply-TerminalTheme.ps1 did:
#   - Removes xcad color scheme from Windows Terminal (if no other profile uses it)
#   - Removes font/theme overrides from the UbuntuBox profile entry
#   - Removes the Hack Nerd Font files and registry entries we installed
#   - Removes the UbuntuBox font manifest
# Called automatically by the Inno Setup uninstaller.
# UbuntuBox v2.2 - Hashim Hilal

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "  UbuntuBox - Reverting terminal theme..." -ForegroundColor Yellow

# ------------------------------------------------------------------
# PART 1 - Restore Windows Terminal settings
# ------------------------------------------------------------------
$WTSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:APPDATA\Microsoft\Windows Terminal\settings.json"
)

$WTSettings = $null
foreach ($p in $WTSettingsPaths) { if (Test-Path $p) { $WTSettings = $p; break } }

if ($WTSettings) {
    $Backup = $WTSettings + ".ubuntubox_backup"

    if (Test-Path $Backup) {
        # Restore from the clean backup taken before we first touched settings.json
        Copy-Item $Backup $WTSettings -Force
        Remove-Item $Backup -Force
        Write-Host "  OK Windows Terminal settings restored from backup" -ForegroundColor Green
    } else {
        # No backup (e.g. user ran Apply-TerminalTheme after a previous unclean uninstall).
        # Surgically remove only what we added.
        $raw = Get-Content $WTSettings -Raw -Encoding UTF8
        $raw = $raw -replace '(?m)^\s*//.*$', ''
        $raw = $raw -replace ',(\s*[}\]])', '$1'

        try {
            $settings = $raw | ConvertFrom-Json

            # Remove xcad from schemes if present and not used by any other profile
            if ($settings.PSObject.Properties.Name -contains "schemes") {
                $schemeList   = [System.Collections.ArrayList]@($settings.schemes)
                $usedByOthers = $false

                if ($settings.PSObject.Properties.Name -contains "profiles" -and
                    $settings.profiles.PSObject.Properties.Name -contains "list") {
                    foreach ($prof in $settings.profiles.list) {
                        $pname = if ($prof.PSObject.Properties.Name -contains "name") { $prof.name } else { "" }
                        if (@("UbuntuBox","UbuntuBox (WSL)") -notcontains $pname) {
                            if ($prof.PSObject.Properties.Name -contains "colorScheme" -and $prof.colorScheme -eq "xcad") {
                                $usedByOthers = $true
                            }
                        }
                    }
                }

                if (-not $usedByOthers) {
                    $newSchemes = $schemeList | Where-Object { $_.name -ne "xcad" }
                    $settings.schemes = @($newSchemes)
                    Write-Host "  OK xcad color scheme removed" -ForegroundColor Green
                } else {
                    Write-Host "  xcad scheme kept (used by another profile)" -ForegroundColor Gray
                }
            }

            # Remove UbuntuBox-specific overrides from its profile entry
            $ubuntuBoxNames  = @("UbuntuBox", "UbuntuBox (WSL)")
            $propsWeAdded    = @("colorScheme","font","cursorShape","opacity","padding","useAcrylic","historySize","scrollbarState")

            if ($settings.PSObject.Properties.Name -contains "profiles" -and
                $settings.profiles.PSObject.Properties.Name -contains "list") {

                $profileList = $settings.profiles.list
                for ($i = 0; $i -lt $profileList.Count; $i++) {
                    $prof     = $profileList[$i]
                    $profName = if ($prof.PSObject.Properties.Name -contains "name") { $prof.name } else { "" }
                    if ($ubuntuBoxNames -contains $profName) {
                        foreach ($prop in $propsWeAdded) {
                            if ($prof.PSObject.Properties.Name -contains $prop) {
                                $prof.PSObject.Properties.Remove($prop)
                            }
                        }
                        $profileList[$i] = $prof
                        Write-Host "  OK Theme properties removed from '$profName' profile" -ForegroundColor Green
                    }
                }
                $settings.profiles.list = $profileList
            }

            $settings | ConvertTo-Json -Depth 20 | Set-Content $WTSettings -Encoding UTF8
        } catch {
            Write-Host "  WARNING: Could not parse settings.json during cleanup - $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Windows Terminal settings.json not found - nothing to restore" -ForegroundColor Gray
}

# ------------------------------------------------------------------
# PART 2 - Remove Hack Nerd Font files and registry entries
#          Only removes files listed in our manifest - never touches
#          fonts the user had before UbuntuBox was installed.
# ------------------------------------------------------------------
$Manifest = "$env:LOCALAPPDATA\UbuntuBox\installed-fonts.txt"
$FontDir  = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$FontReg  = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

if (Test-Path $Manifest) {
    $fontNames = Get-Content $Manifest -Encoding UTF8
    $removed   = 0
    foreach ($name in $fontNames) {
        # Remove file
        $fontFile = Join-Path $FontDir $name
        if (Test-Path $fontFile) {
            Remove-Item $fontFile -Force
            $removed++
        }
        # Remove registry entry
        $regName = [System.IO.Path]::GetFileNameWithoutExtension($name) + " (TrueType)"
        if ((Get-ItemProperty $FontReg -ErrorAction SilentlyContinue).$regName) {
            Remove-ItemProperty -Path $FontReg -Name $regName -Force
        }
    }
    Remove-Item $Manifest -Force
    Write-Host "  OK Removed $removed Hack Nerd Font files" -ForegroundColor Green
} else {
    Write-Host "  Font manifest not found - Hack Nerd Font was not installed by UbuntuBox" -ForegroundColor Gray
}

# Remove manifest dir if empty
$ManifestDir = "$env:LOCALAPPDATA\UbuntuBox"
if ((Test-Path $ManifestDir) -and -not (Get-ChildItem $ManifestDir)) {
    Remove-Item $ManifestDir -Force
}

Write-Host "  OK Terminal theme fully restored to original" -ForegroundColor Green
Write-Host ""
