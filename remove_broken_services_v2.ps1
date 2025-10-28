# ==============================
# 🧹 Remove Broken Services Script (v2 with logging)
# ==============================
# Finds Windows services whose executable paths no longer exist
# and optionally deletes them (e.g. leftovers like OpenVPNService)
# Generates a log file with results
# ==============================

$logDir = "$env:USERPROFILE\Desktop\ServiceCleanupLogs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = "$logDir\ServiceCleanup_$timestamp.txt"

Write-Host "`n=== Checking for broken Windows services... ===" -ForegroundColor Cyan
"=== Service Cleanup Report ($timestamp) ===" | Out-File -FilePath $logFile -Encoding UTF8
"User: $env:USERNAME" | Out-File -Append $logFile
"Computer: $env:COMPUTERNAME" | Out-File -Append $logFile
"----------------------------------------" | Out-File -Append $logFile

# Collect all services with their paths
$services = Get-WmiObject win32_service | Select Name, DisplayName, State, PathName

# Filter those with missing executables
$broken = @()
foreach ($svc in $services) {
    if ($svc.PathName -and ($svc.PathName -match '^[a-zA-Z]:\\')) {
        $exe = ($svc.PathName -split ' ')[0].Trim('"')
        if (-not (Test-Path $exe)) {
            $broken += $svc
        }
    }
}

if ($broken.Count -eq 0) {
    Write-Host "✅ No broken services found!" -ForegroundColor Green
    "No broken services found." | Out-File -Append $logFile
    exit
}

Write-Host "`n⚠️  Found $($broken.Count) broken services:`n" -ForegroundColor Yellow
$broken | Format-Table Name, DisplayName, PathName -AutoSize
"Found $($broken.Count) broken services:" | Out-File -Append $logFile
$broken | ForEach-Object {
    "$($_.Name) | $($_.DisplayName) | $($_.PathName)" | Out-File -Append $logFile
}

"----------------------------------------" | Out-File -Append $logFile

# Ask for confirmation
$confirm = Read-Host "`nDo you want to remove these services? (Y/N)"
if ($confirm -match '^[Yy]') {
    foreach ($svc in $broken) {
        try {
            Write-Host "🗑️  Removing service: $($svc.Name)" -ForegroundColor Red
            sc.exe delete $svc.Name | Out-Null
            "Removed service: $($svc.Name)" | Out-File -Append $logFile
        } catch {
            Write-Host "⚠️  Failed to remove $($svc.Name): $_" -ForegroundColor Yellow
            "FAILED to remove: $($svc.Name) | Error: $_" | Out-File -Append $logFile
        }
    }
    Write-Host "`n✅ Cleanup complete! Please reboot your system." -ForegroundColor Green
    "`nCleanup complete. Please reboot your system." | Out-File -Append $logFile
} else {
    Write-Host "`n❎ No services were deleted." -ForegroundColor Yellow
    "No services deleted by user choice." | Out-File -Append $logFile
}

Write-Host "`n📄 Log saved to: $logFile" -ForegroundColor Cyan
