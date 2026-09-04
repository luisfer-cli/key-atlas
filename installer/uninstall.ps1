[CmdletBinding()]
param(
    [switch]$RemoveFiles
)

$ErrorActionPreference = "Stop"
$taskName = "Key Atlas"

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Get-Process -Name "KeyAtlas" -ErrorAction SilentlyContinue | Stop-Process -Force

if ($RemoveFiles) {
    $installPath = $PSScriptRoot
    Start-Process cmd.exe -ArgumentList "/c timeout /t 2 /nobreak >nul & rmdir /s /q `"$installPath`"" -WindowStyle Hidden
}

Write-Host "The Key Atlas startup task has been removed."
