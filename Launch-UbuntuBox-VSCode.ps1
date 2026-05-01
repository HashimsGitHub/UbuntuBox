# Launch-UbuntuBox-VSCode.ps1 - VS Code terminal launcher
$PodmanPath = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (-not (Test-Path $PodmanPath)) {
    $PodmanPath = "$env:ProgramFiles (x86)\RedHat\Podman\podman.exe"
}

# Start Podman machine silently if not running
$check = & $PodmanPath info 2>$null
if (-not $check) {
    $ErrorActionPreference = "SilentlyContinue"
    & $PodmanPath machine start 2>$null
    $ErrorActionPreference = "Continue"
    Start-Sleep -Seconds 6
}

# Remove stale vscode session container if exists
$existing = & $PodmanPath ps -a --format "{{.Names}}" 2>$null
if ($existing -match "ubuntubox-vscode") {
    & $PodmanPath rm -f ubuntubox-vscode 2>$null | Out-Null
}

# Mount same home folder as desktop app so files are shared
$HomeMount = "$env:USERPROFILE\UbuntuBox"
if (-not (Test-Path $HomeMount)) {
    New-Item -ItemType Directory -Path $HomeMount | Out-Null
}

$vol = $HomeMount + ":/root"
$runArgs = @("run", "-it", "--rm", "-v", $vol, "--name", "ubuntubox-vscode", "localhost/ubuntu-box:latest")
& $PodmanPath @runArgs
