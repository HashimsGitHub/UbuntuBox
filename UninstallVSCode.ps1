# UninstallVSCode.ps1
$s = "$env:APPDATA\Code\User\settings.json"
if (Test-Path $s) {
    $j = Get-Content $s -Raw | ConvertFrom-Json
    $prof = "terminal.integrated.profiles.windows"
    foreach ($name in @("UbuntuBox (WSL)", "UbuntuBox")) {
        if ($j.$prof.PSObject.Properties[$name]) {
            $j.$prof.PSObject.Properties.Remove($name)
        }
    }
    foreach ($name in @("podman-machine-default (WSL)", "podman-machine-default")) {
        if ($j.$prof.PSObject.Properties[$name]) {
            $j.$prof.PSObject.Properties.Remove($name)
        }
    }
    $defKey = "terminal.integrated.defaultProfile.windows"
    if ($j.$defKey -eq "UbuntuBox (WSL)" -or $j.$defKey -eq "UbuntuBox") {
        $j.PSObject.Properties.Remove($defKey)
    }
    $j | ConvertTo-Json -Depth 10 | Set-Content $s -Encoding UTF8
}
