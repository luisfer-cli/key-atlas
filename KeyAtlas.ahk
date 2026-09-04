; ============================================================
; KeyAtlas.ahk - Keyboard Shortcut Assistant
; Main Entry Point
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, OutputDebug

; ---- Includes ----
#Include "lib\Json.ahk"
#Include "lib\Config.ahk"
#Include "lib\I18n.ahk"
#Include "lib\Theme.ahk"
#Include "lib\Database.ahk"
#Include "lib\RemapManager.ahk"
#Include "lib\KeyCaptureGui.ahk"
#Include "lib\HotkeyManager.ahk"
#Include "lib\CheatsheetGui.ahk"
#Include "lib\InputProcessor.ahk"
#Include "lib\GuiManager.ahk"

; ---- Initialization ----
Init()

; ---- System Tray Menu ----
SetupTray()

if (ShouldOpenConfigOnStart())
    SetTimer((*) => OpenConfig(), -100)

; ---- Main Loop (keeps script alive) ----
Persistent()

; ============================================================
; Initialization
; ============================================================

Init() {
    Config.Init()
    Database.Init()
    I18n.Init()
    Theme.Init()

    HotkeyManager.Init(OnTriggerActivated)

    iconPath := A_ScriptDir . "\assets\icon.ico"
    if FileExist(iconPath)
        TraySetIcon(iconPath)
    A_IconTip := I18n.t("tray.title") .
        "`n" I18n.t("tray.trigger") HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger())

    OutputDebug("Key Atlas initialized.")
    OutputDebug("Trigger: " . Config.GetTriggerHotkey())
    OutputDebug("Mode: " . Config.GetDefaultMode())
    OutputDebug("Theme: " . Config.GetTheme())
    OutputDebug("Shortcuts loaded: " . Database.GetAll().Length)
}

; ============================================================
; System Tray Menu
; ============================================================

SetupTray() {
    TrayMenu := A_TrayMenu
    TrayMenu.Delete()

    TrayMenu.Add(I18n.t("menu.open"), (*) => OpenConfig())
    TrayMenu.Default := I18n.t("menu.open")

    ModeMenu := Menu()
    ModeMenu.Add(I18n.t("menu.cheatsheet"), (*) => SwitchAppMode("cheatsheet"))
    ModeMenu.Add(I18n.t("menu.remap"), (*) => SwitchAppMode("remap"))
    if (Config.GetDefaultMode() = "remap")
        ModeMenu.Check(I18n.t("menu.remap"))
    else
        ModeMenu.Check(I18n.t("menu.cheatsheet"))
    TrayMenu.Add(I18n.t("menu.mode"), ModeMenu)

    TrayMenu.Add()
    TrayMenu.Add(I18n.t("menu.reload_db"), (*) => ReloadDatabase())
    TrayMenu.Add(I18n.t("menu.reload_cfg"), (*) => ReloadConfig())

    TrayMenu.Add()
    TrayMenu.Add(I18n.t("menu.install_startup"), (*) => InstallForStartup())
    TrayMenu.Add(I18n.t("menu.about"), (*) => ShowAbout())
    TrayMenu.Add(I18n.t("menu.exit"), (*) => ExitApp())

    A_IconTip := I18n.t("tray.title") . "`n"
        . I18n.t("tray.trigger") . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger())
}

; ============================================================
; Trigger Handler
; ============================================================

OnTriggerActivated(*) {
    if (Config.GetDefaultMode() = "remap") {
        CheatsheetGui.Hide()
        InputProcessor.Toggle()
    } else {
        InputProcessor.Hide()
        CheatsheetGui.Toggle()
    }
}

; ============================================================
; Tray Menu Actions
; ============================================================

OpenConfig() {
    GuiManager.Show()
}

ShouldOpenConfigOnStart() {
    for arg in A_Args {
        if (arg = "--open-config" || arg = "/open-config")
            return true
    }
    return false
}

SwitchAppMode(mode) {
    if (mode = "remap" && Config.GetRemapKeys().Length < 2) {
        GuiManager.ShowRemapSetup()
        return
    }
    if (mode = "remap" && !RemapManager.AssignmentsAreComplete(Config.GetRemapKeys())) {
        if (RemapManager.AssignAll(Config.GetRemapKeys()) < 0) {
            GuiManager.ShowRemapSetup()
            return
        }
    }
    CheatsheetGui.Hide()
    InputProcessor.Hide()
    HotkeyManager.SwitchMode(mode)
    SetupTray()
    TrayTip(I18n.t("msg.mode_changed") mode, "Key Atlas", "Iconi")
}

ReloadDatabase() {
    Database.Reload()
    TrayTip(I18n.t("msg.db_reloaded") Database.GetAll().Length I18n.t("msg.shortcuts_count"),
        "Key Atlas")
}

ReloadConfig() {
    Config.Reload()
    HotkeyManager.UpdateTrigger()
    SetupTray()
    TrayTip(I18n.t("msg.cfg_reloaded"), "Key Atlas")
}

InstallForStartup() {
    installPath := EnvGet("LOCALAPPDATA") . "\KeyAtlas"
    exePath := installPath . "\KeyAtlas.exe"
    scriptPath := A_Temp . "\key-atlas-install-startup-" . A_TickCount . ".ps1"
    sourceExe := StrReplace(A_ScriptFullPath, "'", "''")
    targetExe := StrReplace(exePath, "'", "''")

    psScript := "$ErrorActionPreference = 'Stop'`n"
        . "$installPath = Join-Path $env:LOCALAPPDATA 'KeyAtlas'`n"
        . "New-Item -ItemType Directory -Path $installPath -Force | Out-Null`n"
        . "Copy-Item -LiteralPath '" sourceExe "' -Destination '" targetExe "' -Force`n"
        . "$userId = $env:USERDOMAIN + '\' + $env:USERNAME`n"
        . "$action = New-ScheduledTaskAction -Execute '" targetExe "'`n"
        . "$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId`n"
        . "$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel LeastPrivilege`n"
        . "$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)`n"
        . "$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings`n"
        . "Register-ScheduledTask -TaskName 'Key Atlas' -InputObject $task -Force | Out-Null`n"

    try {
        FileAppend(psScript, scriptPath, "UTF-8")
        q := Chr(34)
        exitCode := RunWait("powershell.exe -NoProfile -ExecutionPolicy Bypass -File " q scriptPath q, , "Hide")
        if (exitCode != 0)
            throw Error(I18n.t("msg.startup_install_err") exitCode)
        TrayTip(I18n.t("msg.startup_installed") installPath, "Key Atlas", "Iconi")
    } catch as err {
        MsgBox(I18n.t("msg.startup_install_err") err.Message, "Key Atlas", "IconX")
    } finally {
        if (FileExist(scriptPath))
            FileDelete(scriptPath)
    }
}

ShowAbout() {
    aboutMsg := I18n.t("about.body") . "`n`n"
        . I18n.t("tray.trigger") . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()) . "`n"
        . I18n.t("tray.mode") . HotkeyManager.GetCurrentMode() . "`n`n"
        . "AutoHotkey v2.0"

    MsgBox(aboutMsg, I18n.t("about.title"))
}
