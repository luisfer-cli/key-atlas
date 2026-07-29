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
#Include "lib\Theme.ahk"
#Include "lib\Database.ahk"
#Include "lib\HotkeyManager.ahk"
#Include "lib\CheatsheetGui.ahk"
#Include "lib\InputProcessor.ahk"
#Include "lib\GuiManager.ahk"

; ---- Initialization ----
Init()

; ---- System Tray Menu ----
SetupTray()

; ---- Main Loop (keeps script alive) ----
Persistent()

; ============================================================
; Initialization
; ============================================================

Init() {
    Config.Init()
    Database.Init()
    Theme.Init()

    HotkeyManager.Init(OnTriggerActivated)

    iconPath := A_ScriptDir . "\assets\icon.ico"
    if FileExist(iconPath)
        TraySetIcon(iconPath)
    A_IconTip := "Key Atlas - Asistente de Atajos" .
        "`nTrigger: " . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()) .
        "`nModo: " . HotkeyManager.GetCurrentMode()

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

    TrayMenu.Add("Abrir Configuracion", (*) => OpenConfig())
    TrayMenu.Default := "Abrir Configuracion"

    TrayMenu.Add()
    TrayMenu.Add("Modo Cheatsheet", (*) => SwitchMode("cheatsheet"))
    TrayMenu.Add("Modo Remap", (*) => SwitchMode("remap"))

    TrayMenu.Add()
    TrayMenu.Add("Recargar Base de Datos", (*) => ReloadDatabase())
    TrayMenu.Add("Recargar Configuracion", (*) => ReloadConfig())

    TrayMenu.Add()
    TrayMenu.Add("Acerca de Key Atlas", (*) => ShowAbout())
    TrayMenu.Add("Salir", (*) => ExitApp())
}

; ============================================================
; Trigger Handler
; ============================================================

OnTriggerActivated(*) {
    mode := HotkeyManager.GetCurrentMode()

    if (mode = "cheatsheet") {
        CheatsheetGui.Toggle()
    } else {
        InputProcessor.Show()
    }
}

; ============================================================
; Tray Menu Actions
; ============================================================

OpenConfig() {
    GuiManager.Show()
}

SwitchMode(newMode) {
    HotkeyManager.SwitchMode(newMode)
    A_IconTip := "Key Atlas - Asistente de Atajos" .
        "`nTrigger: " . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()) .
        "`nModo: " . HotkeyManager.GetCurrentMode()

    if (CheatsheetGui.IsVisible)
        CheatsheetGui.Hide()
    if (InputProcessor.IsVisible)
        InputProcessor.Hide()

    MsgBox("Modo cambiado a: " . newMode, "Key Atlas")
}

ReloadDatabase() {
    Database.Reload()
    TrayTip("Base de datos recargada: " . Database.GetAll().Length . " atajos.",
        "Key Atlas")
}

ReloadConfig() {
    Config.Reload()
    HotkeyManager.UpdateTrigger()
    TrayTip("Configuracion recargada.", "Key Atlas")
}

ShowAbout() {
    aboutMsg := "
    (
        Key Atlas v1.0.0

        Asistente de atajos de teclado universal.

        Funcionalidades:
        - Cheatsheet estilo which-key
        - Modo remap para ejecutar atajos
        - Base de datos JSON configurable
        - Multiples temas de color
        - Deteccion automatica de programa activo

        Trigger: " . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()) . "
        Modo actual: " . HotkeyManager.GetCurrentMode() . "

        AutoHotkey v2.0
    )"

    MsgBox(aboutMsg, "Key Atlas - Acerca de")
}
