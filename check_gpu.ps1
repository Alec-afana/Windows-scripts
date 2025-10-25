Write-Host "=== GPU Driver Check ===" -ForegroundColor Cyan

# Get GPU info
$gpus = Get-WmiObject Win32_VideoController | Select Name, DriverVersion, DriverDate, InfSection, InfPath, PNPDeviceID
Write-Host "`n-- Detected GPUs --" -ForegroundColor Yellow
$gpus | Format-Table -AutoSize

# Check INF files
Write-Host "`n-- Checking INF files --" -ForegroundColor Yellow
foreach ($gpu in $gpus) {
    $infFile = Join-Path "C:\Windows\INF" $gpu.InfPath
    if (Test-Path $infFile) {
        Write-Host "[OK] INF found: $infFile" -ForegroundColor Green
    } else {
        Write-Host "[!] Missing INF file: $infFile" -ForegroundColor Red
    }
}

# Registry check
Write-Host "`n-- Registry check --" -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm",
    "HKLM:\SYSTEM\CurrentControlSet\Services\amdkmdag"
)
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        Write-Host "[OK] Found: $path" -ForegroundColor Green
        Get-ItemProperty -Path $path | Select-Object DriverVersion, ImagePath | Format-List
    } else {
        Write-Host "[!] Not found: $path" -ForegroundColor Red
    }
}

# Check active version in system
Write-Host "`n-- Active version DirectX --" -ForegroundColor Yellow
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" | Select-Object Version | Format-List

# Check conflicts
Write-Host "`n-- Checking conflicts --" -ForegroundColor Yellow
if ($gpus.Count -gt 1) {
	Write-Host "Detected $($gpus.Count) GPU. Checking how much using..." -ForegroundColor Cyan
	$processes = Get-Process | Where-Object { $_.Path -like "*System32*" -and $_.Name -match "dwm|csrss|winlogon" }
	foreach ($p in $processes) {
	  Write-Host "Process $($p.Name) using GPU ID: $($p.Id)"
	}
} else {
	Write-Host "Detected only one GPU - no conflicts." -ForegroundColor Green
}

# Check driver DLLs
Write-Host "`n-- Checking driver DLLs --" -ForegroundColor Yellow
$dirs = @("C:\Windows\System32", "C:\Windows\SysWOW64")
foreach ($dir in $dirs) {
    $oldFiles = Get-ChildItem $dir -Include nvlddmkm.sys, amdkmdag.sys -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $oldFiles) {
        $ver = (Get-Item $file.FullName).VersionInfo.ProductVersion
        Write-Host "$($file.FullName) — version $ver"
    }
}

Write-Host "`n=== Check finished ===" -ForegroundColor Cyan