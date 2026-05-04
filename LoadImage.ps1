# LoadImage.ps1
param([string]$AppDir)

$podman = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (-not (Test-Path $podman)) {
    $podman = "$env:ProgramFiles (x86)\RedHat\Podman\podman.exe"
}

if (-not (Test-Path $podman)) {
    Write-Host "  ERROR: Podman not found" -ForegroundColor Red
    exit 1
}

# ── Find the tar in either Program Files location ─────────────────────────────
$tarPath = "$AppDir\ubuntu-box.tar"
if (-not (Test-Path $tarPath)) {
    $tarPath = "$env:ProgramFiles (x86)\UbuntuBox\ubuntu-box.tar"
}
if (-not (Test-Path $tarPath)) {
    $tarPath = "$env:ProgramFiles\UbuntuBox\ubuntu-box.tar"
}
if (-not (Test-Path $tarPath)) {
    Write-Host "  ERROR: ubuntu-box.tar not found" -ForegroundColor Red
    exit 1
}

Write-Host "  Found image at: $tarPath" -ForegroundColor Gray

# ── Stop and remove ALL running containers ────────────────────────────────────
Write-Host "  Stopping any running UbuntuBox containers..." -ForegroundColor Yellow
& $podman stop ubuntu-box-session  2>$null | Out-Null
& $podman stop ubuntubox-vscode    2>$null | Out-Null
& $podman rm -f ubuntu-box-session 2>$null | Out-Null
& $podman rm -f ubuntubox-vscode   2>$null | Out-Null

# ── Remove ALL existing ubuntu-box images by every possible name/tag ──────────
Write-Host "  Removing all existing ubuntu-box images..." -ForegroundColor Yellow
& $podman rmi localhost/ubuntu-box:latest --force 2>$null | Out-Null
& $podman rmi localhost/ubuntu-box         --force 2>$null | Out-Null
& $podman rmi ubuntu-box:latest            --force 2>$null | Out-Null
& $podman rmi ubuntu-box                   --force 2>$null | Out-Null

# Remove any remaining dangling images
& $podman image prune -f 2>$null | Out-Null

# Confirm all ubuntu-box images are gone
$remaining = & $podman images --format "{{.Repository}}" 2>$null | Where-Object { $_ -match "ubuntu-box" }
if ($remaining) {
    Write-Host "  WARNING: Could not remove all existing images, forcing..." -ForegroundColor Yellow
    foreach ($img in $remaining) {
        & $podman rmi $img --force 2>$null | Out-Null
    }
}

Write-Host "  OK All old images cleared" -ForegroundColor Green

# ── Load the new image ────────────────────────────────────────────────────────
Write-Host "  Loading ubuntu-box image..." -ForegroundColor Yellow

$maxRetries = 3
$loaded = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    & $podman load -i $tarPath
    if ($LASTEXITCODE -eq 0) {
        $loaded = $true
        break
    }
    Write-Host "  Load attempt $i failed, retrying..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

if (-not $loaded) {
    Write-Host "  ERROR: Failed to load ubuntu-box.tar after $maxRetries attempts" -ForegroundColor Red
    exit 1
}

# ── Verify the image is correct ───────────────────────────────────────────────
Write-Host "  Verifying image..." -ForegroundColor Yellow

$neofetch = & $podman run --rm localhost/ubuntu-box:latest which neofetch 2>$null
if (-not $neofetch) {
    Write-Host "  ERROR: Image loaded but neofetch missing - tar may be corrupt" -ForegroundColor Red
    exit 1
}

$logo = & $podman run --rm localhost/ubuntu-box:latest test -f /etc/ubuntubox/ubuntubox-logo.png 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Image loaded but ubuntubox-logo.png missing" -ForegroundColor Red
    exit 1
}

$chafa = & $podman run --rm localhost/ubuntu-box:latest which chafa 2>$null
if (-not $chafa) {
    Write-Host "  ERROR: Image loaded but chafa missing" -ForegroundColor Red
    exit 1
}

Write-Host "  OK neofetch verified" -ForegroundColor Green
Write-Host "  OK ubuntubox-logo.png verified" -ForegroundColor Green
Write-Host "  OK chafa verified" -ForegroundColor Green
Write-Host "  OK Image loaded and fully verified" -ForegroundColor Green
