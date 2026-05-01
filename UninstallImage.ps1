# UninstallImage.ps1
$p = "$env:ProgramFiles\RedHat\Podman\podman.exe"
if (Test-Path $p) {
    & $p rmi ubuntu-box 2>$null
    & $p rmi localhost/ubuntu-box 2>$null
}
