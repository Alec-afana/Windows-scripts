# === Поиск BSOD-ошибок VIDEO_MEMORY_MANAGEMENT_INTERNAL ===

Write-Host "=== Проверка, были ли ошибки dxgmms2.sys / VIDEO_MEMORY_MANAGEMENT_INTERNAL ===`n"

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'
    StartTime = (Get-Date).AddDays(-7)
} | Where-Object {
    $_.Message -match "VIDEO_MEMORY_MANAGEMENT_INTERNAL" -or
    $_.Message -match "dxgmms2.sys"
} | Select TimeCreated, Message -First 10 | Format-List
