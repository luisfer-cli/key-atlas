; ============================================================
; HotkeyManager.ahk - Dynamic Global Hotkey Registration
; ============================================================

class HotkeyManager {
    static CurrentHotkey := ""
    static CurrentMode := ""
    static OnTriggerCallback := ""

    static Init(callback) {
        this.OnTriggerCallback := callback
        this.CurrentMode := Config.GetDefaultMode()
        this.UpdateTrigger()
        return this
    }

    ; Re-register the trigger hotkey (e.g., after user changes it in settings)
    static UpdateTrigger() {
        newHotkey := Config.GetTriggerHotkey()
        newMode := Config.GetDefaultMode()

        if (newHotkey = "")
            newHotkey := "^+Space"

        if (newHotkey != this.CurrentHotkey || newMode != this.CurrentMode) {
            try {
                if (this.CurrentHotkey != "")
                    Hotkey(this.CurrentHotkey, "Off")

                Hotkey(newHotkey, this.OnTriggerCallback, "On")
                this.CurrentHotkey := newHotkey
                this.CurrentMode := newMode
            } catch as err {
                MsgBox("Error registrando hotkey '" newHotkey "': " err.Message,
                    "Key Atlas - Error", "Icon!")
            }
        }
    }

    ; Get all possible trigger keys for display
    static GetCurrentTrigger() {
        if (this.CurrentHotkey = "")
            return Config.GetTriggerHotkey()
        return this.CurrentHotkey
    }

    ; Format hotkey for display (^ = Ctrl, + = Shift, ! = Alt, # = Win)
    static FormatForDisplay(hotkeyStr) {
        result := hotkeyStr
        result := StrReplace(result, "^", "Ctrl+")
        result := StrReplace(result, "+", "Shift+")
        result := StrReplace(result, "!", "Alt+")
        result := StrReplace(result, "#", "Win+")
        result := RegExReplace(result, ">\^", "RCtrl+")
        result := RegExReplace(result, "<\^", "LCtrl+")
        result := RegExReplace(result, ">\+", "RShift+")
        result := RegExReplace(result, "<\+", "LShift+")
        result := RegExReplace(result, ">!", "RAlt+")
        result := RegExReplace(result, "<!", "LAlt+")
        result := RegExReplace(result, ">#", "RWin+")
        result := RegExReplace(result, "<#", "LWin+")
        return result
    }

    ; Get current mode name
    static GetCurrentMode() {
        if (this.CurrentMode = "")
            return Config.GetDefaultMode()
        return this.CurrentMode
    }

    static SwitchMode(newMode) {
        Config.SetDefaultMode(newMode)
        this.CurrentMode := newMode
        Config.Save()
    }
}
