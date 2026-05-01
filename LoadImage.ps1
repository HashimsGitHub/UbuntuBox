# LoadImage.ps1
param([string]$AppDir)
$podman = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (Test-Path $podman) {
    & $podman load -i "$AppDir\ubuntu-box.tar"
}
