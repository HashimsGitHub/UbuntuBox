# InitPodman.ps1 - Initialises and starts Podman machine during install
$podman = "$env:ProgramFiles\RedHat\Podman\podman.exe"

if (-not (Test-Path $podman)) {
    Write-Host "  ERROR: Podman not found" -ForegroundColor Red
    exit 1
}

# Step 1: Update WSL kernel first - required on fresh installs
Write-Host "  Updating WSL kernel..." -ForegroundColor Yellow
$ErrorActionPreference = "SilentlyContinue"
wsl --update 2>$null
wsl --set-default-version 2 2>$null
$ErrorActionPreference = "Continue"
Start-Sleep -Seconds 5

# Step 2: Init machine if it does not exist
$machineList = & $podman machine list --format "{{.Name}}" 2>$null
if (-not $machineList) {
    Write-Host "  Initialising Podman machine..."
    $ErrorActionPreference = "SilentlyContinue"
    & $podman machine init 2>$null
    $ErrorActionPreference = "Continue"
    Start-Sleep -Seconds 8
}

# Step 3: Try to start machine with retries
$maxRetries = 3
$started = $false
for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Host "  Starting Podman machine (attempt $i of $maxRetries)..."
    $ErrorActionPreference = "SilentlyContinue"
    $startOut = & $podman machine start 2>&1
    $ErrorActionPreference = "Continue"

    # Detect WSL kernel update required
    if ($startOut -match "wsl2kernel" -or $startOut -match "requires an update") {
        Write-Host "  WSL2 kernel update required. Running update..." -ForegroundColor Yellow
        wsl --update
        Start-Sleep -Seconds 10
    }

    Start-Sleep -Seconds 8
    $check = & $podman info 2>$null
    if ($LASTEXITCODE -eq 0 -and $check) {
        $started = $true
        Write-Host "  OK Podman machine running" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 5
}

if (-not $started) {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "  -----------------------------------------------" -ForegroundColor Yellow
    Write-Host "  ACTION REQUIRED: WSL2 kernel needs updating." -ForegroundColor Yellow
    Write-Host "  -----------------------------------------------" -ForegroundColor Yellow
    Write-Host "  Please open PowerShell as Administrator and run:" -ForegroundColor White
    Write-Host "" 
    Write-Host "      wsl --update" -ForegroundColor Cyan
    Write-Host "" 
    Write-Host "  Then relaunch UbuntuBox from the desktop shortcut." -ForegroundColor White
    Write-Host "  -----------------------------------------------" -ForegroundColor Yellow
}