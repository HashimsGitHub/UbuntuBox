# UbuntuBox Launcher
$PodmanPath = "$env:ProgramFiles\RedHat\Podman\podman.exe"

function Write-Banner {
    Write-Host ""
    Write-Host "  UbuntuBox v2.0" -ForegroundColor Cyan
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
    try {
        $ErrorActionPreference = "SilentlyContinue"
        & $PodmanPath machine start 2>$null
        $ErrorActionPreference = "Continue"
    } catch {
        $ErrorActionPreference = "Continue"
    }
    Start-Sleep -Seconds 5
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

Start-PodmanMachine

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

Write-Host "  Launching Ubuntu terminal..." -ForegroundColor Green
Write-Host "  Files shared at: $HomeMount" -ForegroundColor Gray
Write-Host ""

$vol = $HomeMount + ":/root"
$runArgs = @("run", "-it", "--rm", "-v", $vol, "--name", "ubuntu-box-session", "localhost/ubuntu-box:latest")
& $PodmanPath @runArgs
