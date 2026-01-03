# PowerShell script to move Docker Desktop WSL2 data to D: drive
# Run this script as Administrator

Write-Host "=== Docker Desktop WSL2 Migration to D: Drive ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select Run as Administrator" -ForegroundColor Yellow
    pause
    exit 1
}

# Configuration
$targetPath = "D:\docker-wsl"
$tempPath = "D:\docker-wsl-temp"

# Step 1: Check if Docker is running
Write-Host "Step 1: Checking Docker status..." -ForegroundColor Yellow
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProcess) {
    Write-Host "WARNING: Docker Desktop is currently running!" -ForegroundColor Red
    Write-Host "Please close Docker Desktop completely before continuing." -ForegroundColor Yellow
    Write-Host "1. Right-click Docker Desktop in system tray" -ForegroundColor Yellow
    Write-Host "2. Select Quit Docker Desktop" -ForegroundColor Yellow
    Write-Host "3. Wait for it to fully shut down (may take 30-60 seconds)" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Have you closed Docker Desktop? (yes/no)"
    if ($continue -ne "yes") {
        Write-Host "Aborting migration." -ForegroundColor Red
        exit 1
    }
}

# Step 2: List current WSL distributions
Write-Host ""
Write-Host "Step 2: Detecting WSL distributions..." -ForegroundColor Yellow
wsl --list -v
Write-Host ""

# Detect which Docker distributions exist
# Use wsl.exe to get proper output and check each distribution
$hasDockerData = $false
$hasDockerDesktop = $false

# Try to get info about each distribution
try {
    wsl.exe -d docker-desktop-data --exec echo "test" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $hasDockerData = $true }
} catch { }

try {
    wsl.exe -d docker-desktop --exec echo "test" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $hasDockerDesktop = $true }
} catch { }

Write-Host "Found distributions:" -ForegroundColor Cyan
if ($hasDockerData) {
    Write-Host "  [OK] docker-desktop-data" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] docker-desktop-data (not found)" -ForegroundColor Yellow
}
if ($hasDockerDesktop) {
    Write-Host "  [OK] docker-desktop" -ForegroundColor Green
} else {
    Write-Host "  [SKIP] docker-desktop (not found)" -ForegroundColor Yellow
}
Write-Host ""

if (-not $hasDockerData -and -not $hasDockerDesktop) {
    Write-Host "ERROR: No Docker WSL distributions found!" -ForegroundColor Red
    Write-Host "Please ensure Docker Desktop is installed and has been started at least once." -ForegroundColor Yellow
    pause
    exit 1
}

# Step 3: Create directories
Write-Host "Step 3: Creating target directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $tempPath | Out-Null
New-Item -ItemType Directory -Force -Path "$targetPath\data" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetPath\distro" | Out-Null
Write-Host "Created: $targetPath" -ForegroundColor Green

# Step 4: Export docker-desktop-data (if exists)
$exportedData = $false
if ($hasDockerData) {
    Write-Host ""
    Write-Host "Step 4: Exporting docker-desktop-data (this may take several minutes)..." -ForegroundColor Yellow
    $exportPath = "$tempPath\docker-desktop-data.tar"
    wsl --export docker-desktop-data "$exportPath"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Export completed successfully!" -ForegroundColor Green
        $fileSize = (Get-Item $exportPath).Length / 1GB
        Write-Host "Export size: $([math]::Round($fileSize, 2)) GB" -ForegroundColor Cyan
        $exportedData = $true
    } else {
        Write-Host "WARNING: Failed to export docker-desktop-data" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Step 4: Skipping docker-desktop-data (not found)" -ForegroundColor Yellow
}

# Step 5: Export docker-desktop (if exists)
$exportedDesktop = $false
if ($hasDockerDesktop) {
    Write-Host ""
    Write-Host "Step 5: Exporting docker-desktop..." -ForegroundColor Yellow
    $exportPath2 = "$tempPath\docker-desktop.tar"
    wsl --export docker-desktop "$exportPath2"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Export completed successfully!" -ForegroundColor Green
        $fileSize2 = (Get-Item $exportPath2).Length / 1GB
        Write-Host "Export size: $([math]::Round($fileSize2, 2)) GB" -ForegroundColor Cyan
        $exportedDesktop = $true
    } else {
        Write-Host "WARNING: Failed to export docker-desktop" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Step 5: Skipping docker-desktop (not found)" -ForegroundColor Yellow
}

# Check if at least one export succeeded
if (-not $exportedData -and -not $exportedDesktop) {
    Write-Host ""
    Write-Host "ERROR: No distributions were successfully exported!" -ForegroundColor Red
    Write-Host "Cannot proceed with migration." -ForegroundColor Yellow
    pause
    exit 1
}

# Step 6: Unregister old distributions
Write-Host ""
Write-Host "Step 6: Unregistering old WSL distributions..." -ForegroundColor Yellow
Write-Host "WARNING: This will remove the old Docker WSL distributions from C: drive!" -ForegroundColor Red
Write-Host "Backups have been created in: $tempPath" -ForegroundColor Cyan
$confirm = Read-Host "Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Aborting. Your data has been exported to: $tempPath" -ForegroundColor Yellow
    pause
    exit 1
}

# Unregister only distributions that were successfully exported
if ($exportedData -and $hasDockerData) {
    wsl --unregister docker-desktop-data
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Unregistered docker-desktop-data" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Failed to unregister docker-desktop-data" -ForegroundColor Yellow
    }
}

if ($exportedDesktop -and $hasDockerDesktop) {
    wsl --unregister docker-desktop
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Unregistered docker-desktop" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Failed to unregister docker-desktop" -ForegroundColor Yellow
    }
}

# Step 7: Import to new location
Write-Host ""
Write-Host "Step 7: Importing to D: drive (this may take several minutes)..." -ForegroundColor Yellow

# Import only distributions that were successfully exported
if ($exportedData) {
    Write-Host "Importing docker-desktop-data..." -ForegroundColor Cyan
    wsl --import docker-desktop-data "$targetPath\data" "$tempPath\docker-desktop-data.tar" --version 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Imported docker-desktop-data successfully!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to import docker-desktop-data" -ForegroundColor Red
        Write-Host "Your backup is still available at: $tempPath" -ForegroundColor Yellow
        pause
        exit 1
    }
}

if ($exportedDesktop) {
    Write-Host "Importing docker-desktop..." -ForegroundColor Cyan
    wsl --import docker-desktop "$targetPath\distro" "$tempPath\docker-desktop.tar" --version 2
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Imported docker-desktop successfully!" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Failed to import docker-desktop" -ForegroundColor Red
        Write-Host "Your backup is still available at: $tempPath" -ForegroundColor Yellow
        pause
        exit 1
    }
}

# Step 8: Verify
Write-Host ""
Write-Host "Step 8: Verifying new WSL distributions:" -ForegroundColor Yellow
wsl --list -v

# Calculate space migrated
Write-Host ""
Write-Host "Migration Summary:" -ForegroundColor Cyan
$totalSize = 0
if ($exportedData -and (Test-Path "$tempPath\docker-desktop-data.tar")) {
    $size = (Get-Item "$tempPath\docker-desktop-data.tar").Length / 1GB
    $totalSize += $size
    Write-Host "  docker-desktop-data: $([math]::Round($size, 2)) GB" -ForegroundColor White
}
if ($exportedDesktop -and (Test-Path "$tempPath\docker-desktop.tar")) {
    $size = (Get-Item "$tempPath\docker-desktop.tar").Length / 1GB
    $totalSize += $size
    Write-Host "  docker-desktop: $([math]::Round($size, 2)) GB" -ForegroundColor White
}
Write-Host "  Total migrated: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Green
Write-Host "  Freed on C: drive: ~$([math]::Round($totalSize, 2)) GB" -ForegroundColor Green

# Step 9: Cleanup
Write-Host ""
Write-Host "Step 9: Cleanup temporary files..." -ForegroundColor Yellow
Write-Host "Backup files location: $tempPath" -ForegroundColor Cyan
$cleanup = Read-Host "Delete temporary backup files? (yes/no)"
if ($cleanup -eq "yes") {
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Cleanup completed!" -ForegroundColor Green
} else {
    Write-Host "Temporary backup files kept at: $tempPath" -ForegroundColor Yellow
    Write-Host "You can manually delete them later once you verified Docker works." -ForegroundColor Yellow
}

# Final message
Write-Host ""
Write-Host "=== Migration Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Docker WSL distributions moved to: $targetPath" -ForegroundColor Cyan
Write-Host "Estimated C: drive space freed: ~$([math]::Round($totalSize, 2)) GB" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start Docker Desktop" -ForegroundColor White
Write-Host "2. Wait for it to fully initialize (1-2 minutes)" -ForegroundColor White
Write-Host "3. Verify containers and images:" -ForegroundColor White
Write-Host "   - docker images" -ForegroundColor Gray
Write-Host "   - docker ps -a" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..."
pause
