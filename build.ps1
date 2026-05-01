# build.ps1 - UbuntuBox Build Script
# Requirements: Podman installed, Inno Setup 6 installed
# Certificate: Place UbuntuBox.pfx in this folder before building

$PodmanPath = "$env:ProgramFiles\RedHat\Podman\podman.exe"
$InnoSetupPath = "$env:ProgramFiles (x86)\Inno Setup 6\ISCC.exe"
$CertFile = ".\UbuntuBox.pfx"
$CertPassword = "UbuntuBox2024"

Write-Host ""
Write-Host "  UbuntuBox - Build Script" -ForegroundColor Cyan
Write-Host ""

# --- Step 1: Check requirements ---
Write-Host "[1/6] Checking requirements..." -ForegroundColor Yellow

if (-not (Test-Path $PodmanPath)) {
    Write-Host "  ERROR: Podman not found" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Podman found" -ForegroundColor Green

if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "  ERROR: Inno Setup 6 not found" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Inno Setup found" -ForegroundColor Green

if (-not (Test-Path ".\podman-installer.exe")) {
    Write-Host "  ERROR: podman-installer.exe not found" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Podman installer found" -ForegroundColor Green

# --- Step 2: Check certificate ---
Write-Host ""
Write-Host "[2/6] Checking certificate..." -ForegroundColor Yellow

if (Test-Path $CertFile) {
    Write-Host "  OK Certificate found: $CertFile" -ForegroundColor Green
    Write-Host "  NOTE: Make sure password in build.ps1 matches your PFX password" -ForegroundColor Gray
} else {
    Write-Host "  WARNING: UbuntuBox.pfx not found - installer will not be signed" -ForegroundColor Yellow
    Write-Host "  To sign: convert your certificate to PFX using OpenSSL:" -ForegroundColor Gray
    Write-Host "  openssl pkcs12 -export -out UbuntuBox.pfx -inkey private.key -in certificate.crt -name Hashim Hilal" -ForegroundColor Gray
    Write-Host "  Then set CertPassword in build.ps1 to match" -ForegroundColor Gray
}

# --- Step 3: Start Podman machine ---
Write-Host ""
Write-Host "[3/6] Checking Podman machine..." -ForegroundColor Yellow

$machineList = & $PodmanPath machine list --format "{{.Name}}" 2>$null
if (-not $machineList) {
    Write-Host "  No machine found. Initialising..." -ForegroundColor Yellow
    & $PodmanPath machine init 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: machine init failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK Machine initialised" -ForegroundColor Green
}

$pingCheck = & $PodmanPath info 2>$null
if ($LASTEXITCODE -eq 0 -and $pingCheck) {
    Write-Host "  OK Podman machine already running" -ForegroundColor Green
} else {
    Write-Host "  Starting Podman machine..." -ForegroundColor Yellow
    try {
        $ErrorActionPreference = "SilentlyContinue"
        & $PodmanPath machine start 2>$null
        $ErrorActionPreference = "Continue"
    } catch {
        $ErrorActionPreference = "Continue"
    }
    Start-Sleep -Seconds 6
    $checkAfter = & $PodmanPath info 2>$null
    if (-not $checkAfter) {
        Write-Host "  ERROR: Podman machine did not start" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK Podman machine started" -ForegroundColor Green
}
Write-Host "  OK Podman ready" -ForegroundColor Green

# --- Step 4: Build container image ---
Write-Host ""
Write-Host "[4/6] Building Ubuntu container image..." -ForegroundColor Yellow
& $PodmanPath build -t ubuntu-box -f .\Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Image built: ubuntu-box" -ForegroundColor Green

# --- Step 5: Export image to tar ---
Write-Host ""
Write-Host "[5/6] Exporting image to ubuntu-box.tar..." -ForegroundColor Yellow
Write-Host "  Please wait, this may take a few minutes..." -ForegroundColor Gray
& $PodmanPath save -o ubuntu-box.tar ubuntu-box
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Export failed" -ForegroundColor Red
    exit 1
}
$sizeMB = [math]::Round((Get-Item ".\ubuntu-box.tar").Length / 1MB, 1)
Write-Host ("  OK Exported: ubuntu-box.tar " + $sizeMB + " MB") -ForegroundColor Green

# --- Step 6: Compile and sign installer ---
Write-Host ""
Write-Host "[6/6] Compiling installer with Inno Setup..." -ForegroundColor Yellow
& $InnoSetupPath ".\UbuntuBoxSetup.iss"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Inno Setup compilation failed" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Installer compiled" -ForegroundColor Green

# Sign the installer if cert exists
if (Test-Path $CertFile) {
    Write-Host "  Signing installer..." -ForegroundColor Yellow
    $SignTool = $null
    $found = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match 'x64' } | Select-Object -First 1
    if ($found) { $SignTool = $found.FullName }
    if ($SignTool) {
        & $SignTool sign /fd SHA256 /f $CertFile /p $CertPassword /tr http://timestamp.digicert.com /td SHA256 ".\Output\UbuntuBoxSetup.exe"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK Installer signed - users will see: Publisher: Hashim Hilal" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: Signing failed. Check PFX password in build.ps1" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WARNING: signtool.exe not found" -ForegroundColor Yellow
        Write-Host "  Download Windows SDK: https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor Gray
    }
} else {
    Write-Host "  Skipping signing - no certificate found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "  Output: .\Output\UbuntuBoxSetup.exe" -ForegroundColor Green
Write-Host ""