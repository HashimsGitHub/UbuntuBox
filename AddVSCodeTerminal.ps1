# AddVSCodeTerminal.ps1 - Adds UbuntuBox (WSL) as VS Code terminal profile

$settingsPath = "$env:APPDATA\Code\User\settings.json"

$launcherPath = "$env:ProgramFiles (x86)\UbuntuBox\Launch-UbuntuBox-VSCode.ps1"
if (-not (Test-Path $launcherPath)) {
    $launcherPath = "$env:ProgramFiles\UbuntuBox\Launch-UbuntuBox-VSCode.ps1"
}

if (-not (Test-Path $settingsPath)) {
    New-Item -ItemType File -Path $settingsPath -Force | Out-Null
    Set-Content $settingsPath -Value "{}" -Encoding UTF8
}

$raw = Get-Content $settingsPath -Raw -ErrorAction SilentlyContinue
if (-not $raw -or $raw.Trim() -eq "") { $raw = "{}" }

try {
    $settings = $raw | ConvertFrom-Json
} catch {
    $settings = [PSCustomObject]@{}
}

$profKey = "terminal.integrated.profiles.windows"
if (-not ($settings.PSObject.Properties.Name -contains $profKey)) {
    $settings | Add-Member -NotePropertyName $profKey -NotePropertyValue ([PSCustomObject]@{})
}

# Register as a proper WSL-style terminal using overrideName
# so it shows as a Linux terminal in VS Code, not PowerShell
$ubuntuProfile = [PSCustomObject]@{
    path         = "powershell.exe"
    args         = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $launcherPath)
    icon         = "terminal-linux"
    color        = "terminal.ansiYellow"
    overrideName = $true
}
$settings.$profKey | Add-Member -NotePropertyName "UbuntuBox (WSL)" -NotePropertyValue $ubuntuProfile -Force

# Remove old plain UbuntuBox entry if present from previous install
if ($settings.$profKey.PSObject.Properties.Name -contains "UbuntuBox") {
    $settings.$profKey.PSObject.Properties.Remove("UbuntuBox")
}

# Hide podman-machine-default entries
foreach ($key in @("podman-machine-default (WSL)", "podman-machine-default")) {
    if (-not ($settings.$profKey.PSObject.Properties.Name -contains $key)) {
        $settings.$profKey | Add-Member -NotePropertyName $key -NotePropertyValue $null -Force
    } else {
        $settings.$profKey.$key = $null
    }
}

# Do NOT set as default - user keeps their existing default terminal

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "  OK UbuntuBox (WSL) registered in VS Code terminal list" -ForegroundColor Green
Write-Host "  OK podman-machine-default hidden" -ForegroundColor Green
Write-Host "  OK Your default terminal is unchanged" -ForegroundColor Green
Write-Host "  Please restart VS Code, then pick UbuntuBox (WSL) from the terminal dropdown." -ForegroundColor Cyan