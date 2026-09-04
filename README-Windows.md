# Key Atlas for Windows

`KeyAtlas.exe` is a compiled AutoHotkey v2 application. It runs without an
AutoHotkey installation.

## Install and keep active

Open PowerShell in this extracted folder and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The installer copies Key Atlas to `%LOCALAPPDATA%\KeyAtlas`, starts it now,
and registers a per-user Scheduled Task named `Key Atlas`. It starts at every
interactive sign-in and restarts the program up to three times after a failure.
This is deliberately not a Windows service: services run outside the desktop
session, so they cannot provide a tray icon or global keyboard hooks.

Run the installer with `-NoStart` to wait until the next sign-in, or with a
different user-writable destination:

```powershell
.\install.ps1 -InstallPath "D:\Apps\KeyAtlas" -NoStart
```

## Uninstall

Run the installed uninstaller to remove the startup task. Add `-RemoveFiles`
to also delete the installed application, settings, and shortcut data:

```powershell
& "$env:LOCALAPPDATA\KeyAtlas\uninstall.ps1" -RemoveFiles
```
