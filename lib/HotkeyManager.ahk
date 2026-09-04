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
        newHotkey := Trim(Config.GetTriggerHotkey())
        newMode := Config.GetDefaultMode()

        if (newHotkey = "")
            newHotkey := "^+Space"

        if (newHotkey != this.CurrentHotkey) {
            oldHotkey := this.CurrentHotkey
            if (oldHotkey != "") {
                try {
                    Hotkey(oldHotkey, "Off")
                } catch as err {
                    Config.SetTriggerHotkey(oldHotkey)
                    Config.Save()
                    MsgBox("Error registrando hotkey '" newHotkey "': " err.Message,
                        "Key Atlas - Error", "Icon!")
                    return false
                }
            }
            try {
                Hotkey(newHotkey, this.OnTriggerCallback, "On")
            } catch as err {
                fallbackHotkey := oldHotkey != "" ? oldHotkey : "^+Space"
                try {
                    Hotkey(fallbackHotkey, this.OnTriggerCallback, "On")
                    this.CurrentHotkey := fallbackHotkey
                } catch {
                    this.CurrentHotkey := ""
                }
                Config.SetTriggerHotkey(fallbackHotkey)
                Config.Save()
                MsgBox("Error registrando hotkey '" newHotkey "': " err.Message,
                    "Key Atlas - Error", "Icon!")
                return false
            }
            this.CurrentHotkey := newHotkey
        }
        this.CurrentMode := newMode
        return true
    }

    ; Get all possible trigger keys for display
    static GetCurrentTrigger() {
        if (this.CurrentHotkey = "")
            return Config.GetTriggerHotkey()
        return this.CurrentHotkey
    }

    ; Format hotkey for display (^ = Ctrl, + = Shift, ! = Alt, # = Win)
    static FormatForDisplay(hotkeyStr) {
        display := ""
        index := 1
        while (index <= StrLen(hotkeyStr)) {
            symbol := SubStr(hotkeyStr, index, 1)
            side := ""
            if ((symbol = "<" || symbol = ">") && index < StrLen(hotkeyStr)) {
                side := symbol = "<" ? "L" : "R"
                index++
                symbol := SubStr(hotkeyStr, index, 1)
            }
            switch symbol {
                case "^": display .= side "Ctrl+"
                case "+": display .= side "Shift+"
                case "!": display .= side "Alt+"
                case "#": display .= side "Win+"
                case "*", "~", "$":
                default:
                    return display . SubStr(hotkeyStr, index - (side != "" ? 1 : 0))
            }
            index++
        }
        return display
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
