# UninstallImage.ps1

$podman = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (-not (Test-Path $podman)) {
    $podman = "$env:ProgramFiles (x86)\RedHat\Podman\podman.exe"
}

if (-not (Test-Path $podman)) {
    Write-Host "  Podman not found - skipping image removal" -ForegroundColor Gray
    exit 0
}

# ── Stop and remove ALL running containers ────────────────────────────────────
Write-Host "  Stopping UbuntuBox containers..." -ForegroundColor Yellow
& $podman stop ubuntu-box-session  2>$null | Out-Null
& $podman stop ubuntubox-vscode    2>$null | Out-Null
& $podman rm -f ubuntu-box-session 2>$null | Out-Null
& $podman rm -f ubuntubox-vscode   2>$null | Out-Null

# ── Remove ALL ubuntu-box images by every possible name/tag ──────────────────
Write-Host "  Removing all UbuntuBox images..." -ForegroundColor Yellow
& $podman rmi localhost/ubuntu-box:latest --force 2>$null | Out-Null
& $podman rmi localhost/ubuntu-box         --force 2>$null | Out-Null
& $podman rmi ubuntu-box:latest            --force 2>$null | Out-Null
& $podman rmi ubuntu-box                   --force 2>$null | Out-Null

# ── Remove all dangling/untagged images ───────────────────────────────────────
& $podman image prune -f 2>$null | Out-Null

# ── Final check - force remove anything ubuntu-box related still remaining ────
$remaining = & $podman images --format "{{.Repository}}:{{.ID}}" 2>$null | Where-Object { $_ -match "ubuntu-box" }
if ($remaining) {
    foreach ($img in $remaining) {
        $id = ($img -split ":")[1]
        & $podman rmi $id --force 2>$null | Out-Null
    }
}

Write-Host "  OK All UbuntuBox images and containers removed" -ForegroundColor Green
