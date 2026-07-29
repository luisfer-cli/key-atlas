; ============================================================
; InputProcessor.ahk - Key Sequence Capture and Execution (Remap Mode)
; ============================================================

class InputProcessor {
    static GuiObj := ""
    static IsVisible := false
    static InputHk := ""
    static AccumulatedKeys := ""
    static Timeout := 2.0
    static TimerObj := ""
    static KeysDisplay := ""
    static StatusDisplay := ""

    static Show() {
        if (this.IsVisible)
            return

        this.AccumulatedKeys := ""
        this.Timeout := Config.Get("remap.timeout", 2.0)

        this._CreateOverlay()
        this._StartInput()
        this.IsVisible := true
    }

    static Hide() {
        if (!this.IsVisible)
            return

        this._StopInput()
        this._StopTimeout()
        try this.GuiObj.Destroy()
        this.GuiObj := ""
        this.IsVisible := false
    }

    ; ==========================================================
    ; Internal: Overlay GUI
    ; ==========================================================

    static _CreateOverlay() {
        this.GuiObj := Gui("+ToolWindow +AlwaysOnTop -Caption +Border -SysMenu +Owner")

        bgColor := Theme.ToBGR(Theme.OVERLAY())
        bdrColor := Theme.ToBGR(Theme.BDR())
        this.GuiObj.BackColor := bgColor
        this.GuiObj.Opt("+LastFound")
        WinSetTransparent(Config.GetCheatsheetOpacity(), this.GuiObj)

        this.GuiObj.MarginX := 16
        this.GuiObj.MarginY := 12

        accColor := Format("{:06X}", Theme.ToBGR(Theme.ACC()))
        txtColor := Format("{:06X}", Theme.ToBGR(Theme.TXTBRIGHT()))
        dimColor := Format("{:06X}", Theme.ToBGR(Theme.TXTDIM()))

        this.GuiObj.SetFont("s12 bold c0x" accColor, "Segoe UI")
        this.GuiObj.Add("Text", "xm w400 Center", "Key Atlas - Modo Remap")

        this.GuiObj.SetFont("s10 c0x" txtColor, "Consolas")

        activeProcess := WinGetProcessName("A")
        if (StrLen(activeProcess) > 40)
            activeProcess := SubStr(activeProcess, 1, 37) . "..."
        this.GuiObj.Add("Text", "xm y+2 w400 Center", activeProcess)

        this.GuiObj.Add("Text", "xm y+10 h2 w400 Background0x" Format("{:06X}", Theme.ToBGR(Theme.BDR())))

        this.GuiObj.SetFont("s18 bold c0x" txtColor, "Consolas")
        this.KeysDisplay := this.GuiObj.Add("Text", "xm y+8 w400 Center", "Esperando teclas...")

        this.GuiObj.SetFont("s9 c0x" dimColor, "Segoe UI")
        this.StatusDisplay := this.GuiObj.Add("Text", "xm y+4 w400 Center",
            "Escribe la secuencia o combinacion de teclas")

        this.GuiObj.SetFont("s8 c0x" dimColor, "Segoe UI")
        this.GuiObj.Add("Text", "xm y+10 w400 Center",
            "[Esc] cancelar  |  [" .
            HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()) .
            "] activar de nuevo")

        this.GuiObj.Show("AutoSize NoActivate xCenter yCenter")
    }

    ; ==========================================================
    ; Internal: Input Capture
    ; ==========================================================

    static _StartInput() {
        maxKeys := Config.Get("remap.maxKeys", 6)
        this.InputHk := InputHook("V L" maxKeys, "{Esc}{Enter}")
        this.InputHk.NotifyNonText := true
        this.InputHk.KeyOpt("{All}", "N")
        this.InputHk.KeyOpt("{Esc}{Enter}", "E -N")
        this.InputHk.OnChar := this._OnChar.Bind(this)
        this.InputHk.OnKeyDown := this._OnKeyDown.Bind(this)
        this.InputHk.OnEnd := this._OnEnd.Bind(this)
        this.InputHk.Start()
        this._StartTimeout()
    }

    static _StopInput() {
        try this.InputHk.Stop()
        this.InputHk := ""
    }

    ; OnChar: handles text-producing keys (regular characters)
    static _OnChar(ih, char) {
        if (char = Chr(27) || char = Chr(13))
            return

        this.AccumulatedKeys .= char
        this._UpdateDisplay()
        this._TryMatch()
        this._ResetTimeout()
    }

    ; OnKeyDown: handles non-text keys and modifier state tracking
    static _OnKeyDown(ih, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))

        modifierNames := ["LControl", "RControl", "LCtrl", "RCtrl",
            "LAlt", "RAlt", "LShift", "RShift", "LWin", "RWin",
            "Control", "Ctrl", "Alt", "Shift", "Win"]

        isModifier := false
        for modName in modifierNames {
            if (keyName = modName) {
                isModifier := true
                break
            }
        }

        if (isModifier) {
            this._ResetTimeout()
            return
        }

        if (keyName = "Escape" || keyName = "Enter")
            return

        ; Check if this key produces text (will be handled by OnChar instead)
        if (this._ProducesText(vk)) {
            this._ResetTimeout()
            return
        }

        ; Non-text key (arrows, F-keys, etc.) - build combo representation
        combo := this._BuildComboString(keyName)
        this.AccumulatedKeys .= combo
        this._UpdateDisplay()
        this._TryMatch()
        this._ResetTimeout()
    }

    static _ProducesText(vk) {
        ; VK codes that typically produce text: 0x30-0x39 (0-9), 0x41-0x5A (A-Z),
        ; 0x20 (Space), 0xBA-0xE2 (punctuation, various)
        ; Oem keys and alphanumeric
        if (vk >= 0x30 && vk <= 0x39)
            return true
        if (vk >= 0x41 && vk <= 0x5A)
            return true
        if (vk = 0x20)
            return true
        if (vk >= 0xBA && vk <= 0xC0)
            return true
        if (vk >= 0xDB && vk <= 0xE4)
            return true
        return false
    }

    static _BuildComboString(keyName) {
        prefix := ""
        if (GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P"))
            prefix .= "Ctrl+"
        if (GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P"))
            prefix .= "Alt+"
        if (GetKeyState("LShift", "P") || GetKeyState("RShift", "P"))
            prefix .= "Shift+"
        if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
            prefix .= "Win+"
        return prefix . keyName
    }

    static _OnEnd(ih) {
        reason := ih.EndReason
        if (reason = "EndKey") {
            endKey := ih.EndKey
            if (endKey = "Escape") {
                this.Hide()
            } else if (endKey = "Enter") {
                this._TryMatch()
                this.Hide()
            }
        } else if (reason = "Timeout") {
            if (this.AccumulatedKeys != "")
                this._TryMatch()
            this.Hide()
        } else if (reason = "Max") {
            this._TryMatch()
            this.Hide()
        }
    }

    ; ==========================================================
    ; Internal: Matching and Execution
    ; ==========================================================

    static _TryMatch() {
        if (this.AccumulatedKeys = "")
            return

        activeShortcuts := Database.GetForActiveWindow()
        if (activeShortcuts.Length = 0) {
            activeShortcuts := Database.GetAll()
        }

        ; Try exact trigger key match first
        for shortcut in activeShortcuts {
            trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
            if (this.AccumulatedKeys = trigger) {
                this._ExecuteShortcut(shortcut)
                this.Hide()
                return
            }
        }

        ; Check partial matches
        partialMatches := Array()
        for shortcut in activeShortcuts {
            trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
            if (InStr(trigger, this.AccumulatedKeys) = 1)
                partialMatches.Push(shortcut)
        }

        if (partialMatches.Length = 1) {
            this._UpdateStatus("Encontrado: " partialMatches[1]["description"] .
                " [Enter para ejecutar]")
        } else if (partialMatches.Length > 1) {
            this._UpdateStatus(partialMatches.Length . " coincidencias parciales...")
        } else {
            this._UpdateStatus("Sin coincidencias - [Esc] para cancelar")
        }
    }

    static _ExecuteShortcut(shortcut) {
        if (!shortcut.Has("targetKeys") || shortcut["targetKeys"] = "") {
            this._UpdateStatus("Error: sin teclas destino definidas")
            return
        }

        targetKeys := shortcut["targetKeys"]
        try {
            SetKeyDelay(-1, -1)
            Send(targetKeys)
            this._UpdateStatus("Ejecutado: " shortcut["description"])
        } catch as err {
            this._UpdateStatus("Error: " err.Message)
        }
    }

    ; ==========================================================
    ; Internal: Display Updates
    ; ==========================================================

    static _UpdateDisplay() {
        if (this.AccumulatedKeys = "") {
            this.KeysDisplay.Text := "Esperando teclas..."
        } else {
            displayKeys := HotkeyManager.FormatForDisplay(this.AccumulatedKeys)
            this.KeysDisplay.Text := displayKeys
        }
    }

    static _UpdateStatus(msg) {
        this.StatusDisplay.Text := msg
    }

    ; ==========================================================
    ; Internal: Timeout Management
    ; ==========================================================

    static _StartTimeout() {
        this._StopTimeout()
        timeoutMs := Integer(this.Timeout * 1000)
        if (timeoutMs < 100)
            timeoutMs := 1000
        this.TimerObj := ObjBindMethod(this, "_OnTimeout")
        SetTimer(this.TimerObj, -timeoutMs)
    }

    static _ResetTimeout() {
        this._StartTimeout()
    }

    static _StopTimeout() {
        if (this.TimerObj != "") {
            SetTimer(this.TimerObj, 0)
            this.TimerObj := ""
        }
    }

    static _OnTimeout() {
        if (this.IsVisible) {
            if (this.AccumulatedKeys != "")
                this._TryMatch()
            this.Hide()
        }
    }
}
