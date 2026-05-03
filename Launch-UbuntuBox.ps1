# UbuntuBox Launcher

$PodmanPath = "$env:ProgramFiles\RedHat\Podman\podman.exe"

function Write-Banner {
    Write-Host ""
    Write-Host "  UbuntuBox" -ForegroundColor Cyan
    Write-Host "  Developed by Hashim Hilal" -ForegroundColor Cyan
    Write-Host ""
}

function Test-PodmanInstalled {
    return Test-Path $PodmanPath
}

function Test-ImageLoaded {
    $images = & $PodmanPath images --format "{{.Repository}}" 2>$null
    return ($images -contains "ubuntu-box") -or ($images -contains "localhost/ubuntu-box")
}

function Start-PodmanMachine {
    Write-Host "  Starting Podman machine..." -ForegroundColor Yellow

    # Update WSL kernel silently - fixes fresh install issues
    $ErrorActionPreference = "SilentlyContinue"
    wsl --update 2>$null
    wsl --set-default-version 2 2>$null
    $ErrorActionPreference = "Continue"

    # Init machine if it does not exist
    $machineList = & $PodmanPath machine list --format "{{.Name}}" 2>$null
    if (-not $machineList) {
        Write-Host "  No machine found. Initialising..." -ForegroundColor Yellow
        $ErrorActionPreference = "SilentlyContinue"
        & $PodmanPath machine init 2>$null
        $ErrorActionPreference = "Continue"
        Start-Sleep -Seconds 8
    }

    # Try to start with retries
    $maxRetries = 3
    for ($i = 1; $i -le $maxRetries; $i++) {
        $ErrorActionPreference = "SilentlyContinue"
        $startOut = & $PodmanPath machine start 2>&1
        $ErrorActionPreference = "Continue"

        # Auto-fix WSL kernel if needed
        if ($startOut -match "wsl2kernel" -or $startOut -match "requires an update") {
            Write-Host "  Updating WSL2 kernel..." -ForegroundColor Yellow
            wsl --update
            Start-Sleep -Seconds 10
        }

        Start-Sleep -Seconds 8

        $check = & $PodmanPath info 2>$null
        if ($LASTEXITCODE -eq 0 -and $check) {
            Write-Host "  OK Podman machine running" -ForegroundColor Green
            return $true
        }

        Write-Host "  Retrying... ($i/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }

    Write-Host ""
    Write-Host "  ERROR: Could not start Podman machine." -ForegroundColor Red
    Write-Host "  Please open PowerShell as Administrator and run:" -ForegroundColor Yellow
    Write-Host "    wsl --update" -ForegroundColor Cyan
    Write-Host "  Then relaunch UbuntuBox." -ForegroundColor Yellow
    return $false
}

function Remove-StaleContainer {
    $existing = & $PodmanPath ps -a --format "{{.Names}}" 2>$null
    if ($existing -match "ubuntu-box-session") {
        Write-Host "  Cleaning up previous session..." -ForegroundColor Yellow
        & $PodmanPath rm -f ubuntu-box-session 2>$null | Out-Null
    }
}

function Load-Image {
    $locations = @(
        "$env:ProgramFiles\UbuntuBox\ubuntu-box.tar",
        "$env:ProgramFiles (x86)\UbuntuBox\ubuntu-box.tar"
    )
    foreach ($path in $locations) {
        if (Test-Path $path) {
            Write-Host "  Loading Ubuntu image..." -ForegroundColor Yellow
            & $PodmanPath load -i $path
            return $true
        }
    }
    return $false
}

Write-Banner

if (-not (Test-PodmanInstalled)) {
    Write-Host "  ERROR: Podman is not installed." -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

$alreadyRunning = & $PodmanPath info 2>$null
if ($LASTEXITCODE -ne 0 -or -not $alreadyRunning) {
    $ok = Start-PodmanMachine
    if (-not $ok) {
        Read-Host "  Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "  OK Podman already running" -ForegroundColor Green
}

if (-not (Test-ImageLoaded)) {
    Write-Host "  Ubuntu image not found. Attempting to load..." -ForegroundColor Yellow
    $loaded = Load-Image
    if (-not $loaded) {
        Write-Host "  ERROR: ubuntu-box.tar not found." -ForegroundColor Red
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

Remove-StaleContainer

$HomeMount = "$env:USERPROFILE\UbuntuBox"
if (-not (Test-Path $HomeMount)) {
    New-Item -ItemType Directory -Path $HomeMount | Out-Null
}

# ── Seed config files into the persistent home folder (first run only) ────────
# The volume mount (-v) overwrites /root inside the container with whatever is
# in $HomeMount on Windows. On a fresh install that folder is empty, which means
# the .bashrc and neofetch config baked into the image at build time are hidden.
# We copy them here once so they survive the mount on every subsequent launch.
$InstallDir = "$env:ProgramFiles\UbuntuBox"
if (-not (Test-Path $InstallDir)) {
    $InstallDir = "$env:ProgramFiles (x86)\UbuntuBox"
}

$BashrcSrc      = "$InstallDir\bashrc"
$BashrcDest     = "$HomeMount\.bashrc"
$NeofetchDir    = "$HomeMount\.config\neofetch"
$NeofetchSrc    = "$InstallDir\neofetch.conf"
$NeofetchDest   = "$NeofetchDir\config.conf"

if ((Test-Path $BashrcSrc) -and (-not (Test-Path $BashrcDest))) {
    Copy-Item $BashrcSrc $BashrcDest -Force
    Write-Host "  OK Seeded .bashrc to home folder" -ForegroundColor Green
}

if ((Test-Path $NeofetchSrc) -and (-not (Test-Path $NeofetchDest))) {
    New-Item -ItemType Directory -Path $NeofetchDir -Force | Out-Null
    Copy-Item $NeofetchSrc $NeofetchDest -Force
    Write-Host "  OK Seeded neofetch config to home folder" -ForegroundColor Green
}
# ─────────────────────────────────────────────────────────────────────────────

Write-Host "  Launching Ubuntu terminal..." -ForegroundColor Green
Write-Host "  Files shared at: $HomeMount" -ForegroundColor Gray
Write-Host ""

$vol = $HomeMount + ":/root"
$runArgs = @("run", "-it", "--rm", "-v", $vol, "--name", "ubuntu-box-session", "localhost/ubuntu-box:latest")

& $PodmanPath @runArgs
