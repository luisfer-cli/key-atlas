# Key Atlas

Key Atlas is a minimal Windows keyboard shortcut assistant built with AutoHotkey v2. It helps you discover, organize, and execute application-specific shortcuts without leaving your workflow.

- Website: <https://luisfer-cli.github.io/key-atlas/>
- Releases: <https://github.com/luisfer-cli/key-atlas/releases/latest>

## Features

- Context-aware shortcut library for the active Windows application.
- Which-key style cheatsheet overlay.
- One-handed remap mode for compact command workflows.
- JSON-based shortcut database and settings.
- Portable `.exe` or per-user install with Windows startup.

## Download

Go to the latest release and choose one of the Windows assets:

- `KeyAtlas-Setup-*-windows-x64.exe` — recommended Windows installer. Open it and follow the wizard.
- `KeyAtlas-portable-*-windows-x64.exe` — run directly. From the tray menu, choose **Install / start with Windows** if you want it to launch after sign-in.
- `KeyAtlas-installer-*-windows-x64.zip` — advanced/manual package with installer scripts, uninstaller, default config, and shortcut data.

## Install from the zip package

Extract the zip, open PowerShell in the extracted folder, then run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The installer copies Key Atlas to:

```text
%LOCALAPPDATA%\KeyAtlas
```

and registers a per-user Scheduled Task named `Key Atlas` so it starts when you sign in.

## Portable usage

Download and run the portable `.exe`. It does not install anything by default.

To enable startup from the portable app:

1. Run `KeyAtlas-portable-*-windows-x64.exe`.
2. Right-click the tray icon.
3. Select **Install / start with Windows**.

## Uninstall

If installed from the zip package:

```powershell
& "$env:LOCALAPPDATA\KeyAtlas\uninstall.ps1" -RemoveFiles
```

If installed from the portable tray action, remove the `Key Atlas` task from Windows Task Scheduler and delete `%LOCALAPPDATA%\KeyAtlas`.

## Configuration

Key Atlas stores its configuration and shortcut library as JSON:

```text
config/settings.json
data/shortcuts.json
```

The installed copy keeps user-maintained `config` and `data` folders when updating.

## Development

Requirements:

- Windows
- AutoHotkey v2.0+

Run from source:

```powershell
AutoHotkey64.exe .\KeyAtlas.ahk
```

The release workflow compiles `KeyAtlas.ahk` into a Windows executable using `Ahk2Exe` on GitHub Actions.

## Windows security warnings

Windows SmartScreen may warn about unsigned executables downloaded from the internet. The long-term fix is to sign releases with a code-signing certificate and build reputation over time.

## Author

Built by [Luis Fer](https://luis-fer.dev).
