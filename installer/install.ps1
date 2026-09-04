[CmdletBinding()]
param(
    [string]$InstallPath = (Join-Path $env:LOCALAPPDATA "KeyAtlas"),
    [switch]$NoStart
)

$ErrorActionPreference = "Stop"
$taskName = "Key Atlas"
$sourceRoot = $PSScriptRoot
$sourceExe = Join-Path $sourceRoot "KeyAtlas.exe"

if (-not (Test-Path $sourceExe)) {
    throw "KeyAtlas.exe must be in the same folder as install.ps1."
}

New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
$writeCheck = Join-Path $InstallPath ".key-atlas-write-check-$([guid]::NewGuid())"
try {
    New-Item -ItemType File -Path $writeCheck -Force | Out-Null
    Remove-Item $writeCheck -Force
} catch {
    throw "InstallPath must be writable by the signed-in user: $InstallPath"
}

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Get-Process -Name "KeyAtlas" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "KeyAtlas" -ErrorAction SilentlyContinue | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue

Copy-Item $sourceExe $InstallPath -Force
Copy-Item (Join-Path $sourceRoot "uninstall.ps1") $InstallPath -Force
Copy-Item (Join-Path $sourceRoot "README-Windows.md") $InstallPath -Force

if (Test-Path (Join-Path $sourceRoot "assets")) {
    Copy-Item (Join-Path $sourceRoot "assets") $InstallPath -Recurse -Force
}

# Keep user-maintained configuration and shortcut data when installing an update.
foreach ($directory in @("config", "data")) {
    $sourceDirectory = Join-Path $sourceRoot $directory
    $destinationDirectory = Join-Path $InstallPath $directory
    if ((Test-Path $sourceDirectory) -and -not (Test-Path $destinationDirectory)) {
        Copy-Item $sourceDirectory $InstallPath -Recurse
    }
}

$userId = "$env:USERDOMAIN\$env:USERNAME"
$action = New-ScheduledTaskAction -Execute (Join-Path $InstallPath "KeyAtlas.exe")
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel LeastPrivilege
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null

if (-not $NoStart) {
    Start-ScheduledTask -TaskName $taskName
}

Write-Host "Key Atlas installed to $InstallPath."
Write-Host "It will start automatically whenever $userId signs in."
