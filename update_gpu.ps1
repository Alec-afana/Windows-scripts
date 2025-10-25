Write-Host "Определяем GPU..."
$gpus = Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion, DriverDate
$gpus | Format-Table

foreach ($gpu in $gpus) {
    if ($gpu.Name -like "*NVIDIA*") {
        Write-Host "Скачиваем NVIDIA драйвер..."
        Start-Process "https://www.nvidia.com/Download/index.aspx?lang=ru"
    }
    elseif ($gpu.Name -like "*AMD*" -or $gpu.Name -like "*Radeon*") {
        Write-Host "Скачиваем AMD драйвер..."
        Start-Process "https://www.amd.com/ru/support"
    }
}

Write-Host "`n После загрузки установи драйверы и перезагрузи компьютер."
