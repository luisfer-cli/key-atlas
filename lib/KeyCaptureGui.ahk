; ============================================================
; KeyCaptureGui.ahk - Interactive hotkey and sequence capture
; ============================================================

class KeyCaptureGui {
    static GuiObj := ""
    static InputHk := ""
    static Callback := ""
    static Mode := ""
    static Values := Array()
    static AllowedKeys := Array()
    static HeldKeys := Map()
    static DisplayText := ""
    static HintText := ""
    static PendingResult := ""
    static IsFinishing := false
    static OwnerHwnd := 0
    static TimerObj := ""

    static Show(mode, callback, initialValue := "", allowedKeys := "", ownerGui := "") {
        this.Close()
        this.Mode := mode
        this.Callback := callback
        this.Values := (mode = "pool" || mode = "sequence")
            ? RemapManager.ParseSequence(initialValue) : Array()
        this.AllowedKeys := allowedKeys is Array
            ? RemapManager.ParseKeyPool(allowedKeys) : Array()
        this.HeldKeys := Map()
        this.PendingResult := ""
        this.IsFinishing := false
        this.OwnerHwnd := 0
        if (ownerGui != "")
            try this.OwnerHwnd := ownerGui.Hwnd
        if (this.OwnerHwnd)
            try WinSetEnabled(false, "ahk_id " this.OwnerHwnd)

        guiOptions := "+AlwaysOnTop +ToolWindow"
        if (this.OwnerHwnd)
            guiOptions .= " +Owner" this.OwnerHwnd
        this.GuiObj := Gui(guiOptions, I18n.t("capture.title"))
        this.GuiObj.BackColor := Theme.ToBGR(Theme.BG())
        this.GuiObj.MarginX := 24
        this.GuiObj.MarginY := 20
        surfHex := Format("{:06X}", Theme.ToBGR(Theme.SURF()))

        this.GuiObj.SetFont("s17 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        this.GuiObj.Add("Text", "xm ym w500 h32", I18n.t("capture.heading"))
        this.GuiObj.SetFont("s9 norm c" Theme.TXTDIM(), "Segoe UI")
        promptKey := (mode = "pool" || mode = "sequence")
            ? "capture.sequence_prompt" : "capture.chord_prompt"
        this.GuiObj.Add("Text", "xm y+3 w500 h40", I18n.t(promptKey))

        this.GuiObj.SetFont("s18 bold c" Theme.ACC(), "Consolas")
        this.DisplayText := this.GuiObj.Add("Text",
            "xm y+14 w500 h48 Center Background0x" surfHex, "")
        this.GuiObj.SetFont("s9 norm c" Theme.TXTDIM(), "Segoe UI")
        this.HintText := this.GuiObj.Add("Text", "xm y+8 w500 h24 Center", "")

        if (mode = "pool" || mode = "sequence") {
            this.GuiObj.SetFont("s10 bold c" Theme.ACC(), "Segoe UI")
            doneBtn := this.GuiObj.Add("Button", "xm y+18 w150 h36 Default",
                I18n.t("capture.done"))
            doneBtn.OnEvent("Click", (*) => this._FinishSequence())
            clearBtn := this.GuiObj.Add("Button", "x+10 yp w110 h36", I18n.t("capture.clear"))
            clearBtn.OnEvent("Click", (*) => this.Clear())
        }

        this.GuiObj.OnEvent("Escape", (*) => this.Close())
        this.GuiObj.OnEvent("Close", (*) => this.Close())
        this._UpdateDisplay()
        this.GuiObj.Show("w550 h290 Center")
        this._StartWhenModifiersReleased()
    }

    static Close() {
        ownerHwnd := this.OwnerHwnd
        this._StopTimer()
        if (this.InputHk != "")
            try this.InputHk.Stop()
        this.InputHk := ""
        if (this.GuiObj != "")
            try this.GuiObj.Destroy()
        this.GuiObj := ""
        this.Callback := ""
        this.IsFinishing := true
        this.OwnerHwnd := 0
        if (ownerHwnd && WinExist("ahk_id " ownerHwnd)) {
            try WinSetEnabled(true, "ahk_id " ownerHwnd)
            try WinActivate("ahk_id " ownerHwnd)
        }
    }

    static Clear() {
        this.Values := Array()
        this._UpdateDisplay()
    }

    static _StartInput() {
        this.InputHk := InputHook("L0")
        this.InputHk.NotifyNonText := true
        this.InputHk.KeyOpt("{All}", "N S")
        this.InputHk.OnKeyDown := this._OnKeyDown.Bind(this)
        this.InputHk.OnKeyUp := this._OnKeyUp.Bind(this)
        this.InputHk.Start()
    }

    static _StartWhenModifiersReleased() {
        if (this.GuiObj = "")
            return
        if (this._AnyLogicalModifierHeld()) {
            this.HintText.Text := I18n.t("capture.release_modifiers")
            this._Schedule("_StartWhenModifiersReleased")
            return
        }
        this._UpdateDisplay()
        this._StartInput()
    }

    static _OnKeyDown(ih, vk, sc) {
        if (this.IsFinishing)
            return
        physicalKey := vk ":" sc
        if (this.HeldKeys.Has(physicalKey))
            return
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        if (keyName = "") {
            this.HintText.Text := I18n.t("capture.unknown_key")
            return
        }
        this.HeldKeys[physicalKey] := keyName

        if (vk = 0x1B) {
            this.Close()
            return
        }

        if (this.Mode = "pool" || this.Mode = "sequence") {
            if (vk = 0x0D) {
                this._FinishSequence()
                return
            }
            if (vk = 0x08) {
                if (this.Values.Length > 0)
                    this.Values.Pop()
                this._UpdateDisplay()
                return
            }
            key := RemapManager.NormalizeKey(keyName)
            if (key = "" || this._IsModifier(key))
                return
            if (this.Mode = "sequence" && this.AllowedKeys.Length > 0
                && !this._Contains(this.AllowedKeys, key)) {
                this.HintText.Text := I18n.t("capture.key_not_allowed") key
                return
            }
            if (this.Mode = "pool" && this._Contains(this.Values, key))
                return
            this.Values.Push(key)
            this._UpdateDisplay()
            return
        }

        if (this._IsModifier(StrLower(keyName))) {
            this.DisplayText.Text := this._ModifierDisplay()
            return
        }
        if (this._HasDoubleSidedModifier()) {
            this.HintText.Text := I18n.t("capture.double_modifier")
            return
        }
        this.PendingResult := this._BuildChordResult(keyName, vk, sc)
        this.DisplayText.Text := this.PendingResult["display"]
        this.HintText.Text := I18n.t("capture.release")
        this.IsFinishing := true
        this._Schedule("_FinishChordWhenReleased")
    }

    static _OnKeyUp(ih, vk, sc) {
        physicalKey := vk ":" sc
        if (this.HeldKeys.Has(physicalKey))
            this.HeldKeys.Delete(physicalKey)
    }

    static _FinishChordWhenReleased() {
        if (this.GuiObj = "")
            return
        if (this.HeldKeys.Count > 0 || this._AnyModifierHeld()) {
            this._Schedule("_FinishChordWhenReleased")
            return
        }
        this._Complete(this.PendingResult)
    }

    static _FinishSequence() {
        minimum := this.Mode = "pool" ? 2 : 1
        if (this.Values.Length < minimum) {
            this.HintText.Text := this.Mode = "pool"
                ? I18n.t("msg.remap_pool_required") : I18n.t("capture.sequence_required")
            return
        }
        this._Complete(this.Values.Clone())
    }

    static _Complete(result) {
        callback := this.Callback
        ownerHwnd := this.OwnerHwnd
        this._StopTimer()
        if (this.InputHk != "")
            try this.InputHk.Stop()
        this.InputHk := ""
        if (this.GuiObj != "")
            try this.GuiObj.Destroy()
        this.GuiObj := ""
        this.Callback := ""
        this.IsFinishing := true
        this.OwnerHwnd := 0
        if (ownerHwnd && WinExist("ahk_id " ownerHwnd))
            try WinSetEnabled(true, "ahk_id " ownerHwnd)
        if (callback != "" && (!ownerHwnd || WinExist("ahk_id " ownerHwnd)))
            callback.Call(result)
    }

    static _UpdateDisplay() {
        if (this.DisplayText = "")
            return
        display := RemapManager.FormatSequence(this.Values)
        this.DisplayText.Text := display = "" ? I18n.t("capture.waiting") : display
        this.HintText.Text := (this.Mode = "pool" || this.Mode = "sequence")
            ? I18n.t("capture.sequence_footer") : I18n.t("capture.chord_footer")
    }

    static _BuildChordResult(keyName, vk, sc) {
        lCtrl := GetKeyState("LCtrl", "P"), rCtrl := GetKeyState("RCtrl", "P")
        lAlt := GetKeyState("LAlt", "P"), rAlt := GetKeyState("RAlt", "P")
        lShift := GetKeyState("LShift", "P"), rShift := GetKeyState("RShift", "P")
        lWin := GetKeyState("LWin", "P"), rWin := GetKeyState("RWin", "P")
        display := this._ModifierLabel("Ctrl", lCtrl, rCtrl)
            . this._ModifierLabel("Alt", lAlt, rAlt)
            . this._ModifierLabel("Shift", lShift, rShift)
            . this._ModifierLabel("Win", lWin, rWin) . keyName
        hotkeySuffix := StrLen(keyName) = 1 && !RegExMatch(keyName, "i)^[a-z0-9]$")
            ? Format("vk{:02X}sc{:03X}", vk, sc) : keyName
        hotkey := this._HotkeyModifier("^", lCtrl, rCtrl)
            . this._HotkeyModifier("!", lAlt, rAlt)
            . this._HotkeyModifier("+", lShift, rShift)
            . this._HotkeyModifier("#", lWin, rWin) . hotkeySuffix
        sendKey := StrLen(keyName) = 1 ? StrLower(keyName) : "{" keyName "}"
        if (StrLen(keyName) = 1 && (InStr("+^!#{}", keyName) || keyName = Chr(96)))
            sendKey := "{" keyName "}"
        sendDown := this._SendModifier("Ctrl", lCtrl, rCtrl, true)
            . this._SendModifier("Alt", lAlt, rAlt, true)
            . this._SendModifier("Shift", lShift, rShift, true)
            . this._SendModifier("Win", lWin, rWin, true)
        sendUp := this._SendModifier("Win", lWin, rWin, false)
            . this._SendModifier("Shift", lShift, rShift, false)
            . this._SendModifier("Alt", lAlt, rAlt, false)
            . this._SendModifier("Ctrl", lCtrl, rCtrl, false)
        sendValue := sendDown . sendKey . sendUp
        return Map("display", display, "hotkey", hotkey, "send", sendValue)
    }

    static _ModifierDisplay() {
        display := this._ModifierLabel("Ctrl", GetKeyState("LCtrl", "P"), GetKeyState("RCtrl", "P"))
            . this._ModifierLabel("Alt", GetKeyState("LAlt", "P"), GetKeyState("RAlt", "P"))
            . this._ModifierLabel("Shift", GetKeyState("LShift", "P"), GetKeyState("RShift", "P"))
            . this._ModifierLabel("Win", GetKeyState("LWin", "P"), GetKeyState("RWin", "P"))
        return display = "" ? I18n.t("capture.waiting") : display
    }

    static _ModifierLabel(name, leftPressed, rightPressed) {
        if (leftPressed && rightPressed)
            return name "+"
        if (leftPressed)
            return "L" name "+"
        if (rightPressed)
            return "R" name "+"
        return ""
    }

    static _HotkeyModifier(symbol, leftPressed, rightPressed) {
        if (leftPressed && rightPressed)
            return symbol
        if (leftPressed)
            return "<" symbol
        if (rightPressed)
            return ">" symbol
        return ""
    }

    static _SendModifier(name, leftPressed, rightPressed, isDown) {
        state := isDown ? " down}" : " up}"
        result := ""
        if (leftPressed)
            result .= "{L" name state
        if (rightPressed)
            result .= "{R" name state
        return result
    }

    static _AnyModifierHeld() {
        return GetKeyState("LCtrl", "P") || GetKeyState("RCtrl", "P")
            || GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P")
            || GetKeyState("LShift", "P") || GetKeyState("RShift", "P")
            || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    }

    static _AnyLogicalModifierHeld() {
        return GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("Shift")
            || GetKeyState("LWin") || GetKeyState("RWin")
    }

    static _HasDoubleSidedModifier() {
        return (GetKeyState("LCtrl", "P") && GetKeyState("RCtrl", "P"))
            || (GetKeyState("LAlt", "P") && GetKeyState("RAlt", "P"))
            || (GetKeyState("LShift", "P") && GetKeyState("RShift", "P"))
            || (GetKeyState("LWin", "P") && GetKeyState("RWin", "P"))
    }

    static _Schedule(methodName) {
        this._StopTimer()
        this.TimerObj := ObjBindMethod(this, methodName)
        SetTimer(this.TimerObj, -25)
    }

    static _StopTimer() {
        if (this.TimerObj != "") {
            SetTimer(this.TimerObj, 0)
            this.TimerObj := ""
        }
    }

    static _Contains(values, wanted) {
        for value in values {
            if (value = wanted)
                return true
        }
        return false
    }

    static _IsModifier(key) {
        return key = "ctrl" || key = "alt" || key = "shift" || key = "lwin"
            || key = "rwin" || key = "lshift" || key = "rshift"
            || key = "lalt" || key = "ralt" || key = "lctrl" || key = "rctrl"
    }
}
