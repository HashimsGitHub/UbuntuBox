# InitPodman.ps1
$podman = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (Test-Path $podman) {
    & $podman machine init 2>$null
    Start-Sleep -Seconds 5
    & $podman machine start 2>$null
}
