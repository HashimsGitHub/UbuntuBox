# EnableFeatures.ps1
$features = @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')
$needReboot = $false
$tmpDir = [System.IO.Path]::GetTempPath()

foreach ($f in $features) {
    $state = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction SilentlyContinue
    if ($state -and $state.State -ne 'Enabled') {
        Write-Host "  Enabling $f..."
        $result = Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart
        if ($result.RestartNeeded) { $needReboot = $true }
    }
}

if (-not $needReboot) {
    Set-Content -Path (Join-Path $tmpDir 'features_ok.txt') -Value 'ok'
    Write-Host '  OK All features enabled, no reboot needed'
} else {
    Write-Host '  Reboot required to complete feature activation'
}
