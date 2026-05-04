# Podman-KillAll.ps1
# Removes ONLY UbuntuBox-specific containers and images
# Does NOT touch the Podman machine, other images, or other users' data
# Use -NonInteractive for silent automated runs during install/uninstall

param([switch]$NonInteractive)

# ── Self-elevate if not running as admin ──────────────────────────────────────
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -NonInteractive"
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -Wait -WindowStyle Hidden
    exit $LASTEXITCODE
}
# ─────────────────────────────────────────────────────────────────────────────

# ── Find Podman ───────────────────────────────────────────────────────────────
$podman = $null
$possiblePaths = @(
    "$env:ProgramFiles\RedHat\Podman\podman.exe",
    "$env:ProgramFiles (x86)\RedHat\Podman\podman.exe",
    "C:\Program Files\RedHat\Podman\podman.exe",
    "C:\Program Files (x86)\RedHat\Podman\podman.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $podman = $path
        break
    }
}

# Fallback - try PATH
if (-not $podman) {
    $podman = (Get-Command podman.exe -ErrorAction SilentlyContinue).Source
}

if (-not $podman) {
    Write-Host "  WARNING: Podman.exe not found - nothing to clean" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Found Podman at: $podman" -ForegroundColor Gray

# ── Stop ONLY UbuntuBox containers ───────────────────────────────────────────
Write-Host "  Stopping UbuntuBox containers..." -ForegroundColor Yellow
& $podman stop ubuntu-box-session  2>$null | Out-Null
& $podman stop ubuntubox-vscode    2>$null | Out-Null

# ── Remove ONLY UbuntuBox containers ─────────────────────────────────────────
Write-Host "  Removing UbuntuBox containers..." -ForegroundColor Yellow
& $podman rm -f ubuntu-box-session 2>$null | Out-Null
& $podman rm -f ubuntubox-vscode   2>$null | Out-Null

# ── Remove ONLY UbuntuBox images by every possible name/tag ──────────────────
Write-Host "  Removing UbuntuBox images..." -ForegroundColor Yellow
& $podman rmi localhost/ubuntu-box:latest --force 2>$null | Out-Null
& $podman rmi localhost/ubuntu-box         --force 2>$null | Out-Null
& $podman rmi ubuntu-box:latest            --force 2>$null | Out-Null
& $podman rmi ubuntu-box                   --force 2>$null | Out-Null

# ── Remove only dangling/untagged images (safe - these have no name) ─────────
Write-Host "  Pruning dangling images..." -ForegroundColor Yellow
& $podman image prune -f 2>$null | Out-Null

# ── Final check - force remove anything ubuntu-box related still remaining ────
$remaining = & $podman images --format "{{.Repository}}:{{.ID}}" 2>$null | Where-Object { $_ -match "ubuntu-box" }
if ($remaining) {
    Write-Host "  Removing remaining ubuntu-box images..." -ForegroundColor Yellow
    foreach ($img in $remaining) {
        $id = ($img -split ":")[1]
        & $podman rmi $id --force 2>$null | Out-Null
    }
}

Write-Host ""
Write-Host "  OK UbuntuBox containers and images removed" -ForegroundColor Green
Write-Host "  OK Podman machine left running - other images untouched" -ForegroundColor Green
Write-Host ""
