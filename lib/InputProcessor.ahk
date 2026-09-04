; ============================================================
; InputProcessor.ahk - Vim-style remap command mode
; ============================================================

class InputProcessor {
    static GuiObj := ""
    static IsVisible := false
    static IsClosing := false
    static InputHk := ""
    static TimerObj := ""
    static Timeout := 2.0
    static TargetHwnd := 0
    static ActiveProcess := ""
    static ActiveProgram := ""
    static AvailableKeys := Array()
    static Sequence := Array()
    static Candidates := Array()
    static Filtered := Array()
    static ExactMatch := ""
    static HeldKeys := Map()
    static ActivationKey := ""
    static KeysDisplay := ""
    static StatusDisplay := ""
    static ShortcutLV := ""

    static Show() {
        if (this.IsVisible)
            return

        this.AvailableKeys := Config.GetRemapKeys()
        if (this.AvailableKeys.Length < 2) {
            GuiManager.ShowRemapSetup()
            return
        }
        if (!RemapManager.AssignmentsAreComplete(this.AvailableKeys)) {
            if (RemapManager.AssignAll(this.AvailableKeys) < 0) {
                GuiManager.ShowRemapSetup()
                return
            }
        }

        this.TargetHwnd := WinExist("A")
        if (!this.TargetHwnd) {
            TrayTip(I18n.t("sheet.no_active_window"), "Key Atlas", "Iconi")
            return
        }
        activeClass := ""
        try activeClass := WinGetClass(this.TargetHwnd)
        if (activeClass = "Progman" || activeClass = "WorkerW"
            || activeClass = "Shell_TrayWnd") {
            TrayTip(I18n.t("sheet.no_active_window"), "Key Atlas", "Iconi")
            return
        }

        try this.ActiveProcess := WinGetProcessName(this.TargetHwnd)
        catch {
            TrayTip(I18n.t("sheet.no_active_window"), "Key Atlas", "Iconi")
            return
        }
        if (!Database.IsProcessRegistered(this.ActiveProcess)) {
            TrayTip(I18n.t("sheet.software_unregistered") this.ActiveProcess,
                "Key Atlas", "Iconi")
            return
        }

        try this.ActiveProgram := WinGetTitle(this.TargetHwnd)
        catch
            this.ActiveProgram := this.ActiveProcess
        this.Candidates := RemapManager.GetForProcess(this.ActiveProcess)
        if (this.Candidates.Length = 0) {
            TrayTip(I18n.t("remap.no_assignments"), "Key Atlas", "Iconi")
            GuiManager.ShowRemapSetup()
            return
        }

        this.Sequence := Array()
        this.Filtered := this.Candidates.Clone()
        this.ExactMatch := ""
        this.HeldKeys := Map()
        this.Timeout := Config.GetRemapTimeout()
        this.IsClosing := false
        this._CreateOverlay()
        this._RenderCandidates()
        this.IsVisible := true
        this._WaitForActivationRelease()
    }

    static Hide() {
        if (!this.IsVisible && this.GuiObj = "")
            return
        this.IsClosing := true
        this._StopTimeout()
        try this.InputHk.Stop()
        this.InputHk := ""
        try this.GuiObj.Destroy()
        this.GuiObj := ""
        this.IsVisible := false
    }

    static Toggle() {
        if (this.IsVisible && this.InputHk = "")
            return
        if (this.IsVisible)
            this.Hide()
        else
            this.Show()
    }

    static _CreateOverlay() {
        this.GuiObj := Gui("+ToolWindow +AlwaysOnTop -Caption +Border -SysMenu +Owner")
        this.GuiObj.BackColor := Theme.ToBGR(Theme.OVERLAY())
        this.GuiObj.Opt("+LastFound")
        WinSetTransparent(Config.GetCheatsheetOpacity(), this.GuiObj)
        this.GuiObj.MarginX := 18
        this.GuiObj.MarginY := 14

        bright := Theme.TXTBRIGHT()
        dim := Theme.TXTDIM()
        accent := Theme.ACC()
        surfHex := Format("{:06X}", Theme.ToBGR(Theme.SURF()))
        borderHex := Format("{:06X}", Theme.ToBGR(Theme.BDR()))

        this.GuiObj.SetFont("s17 bold c" bright, "Segoe UI")
        this.GuiObj.Add("Text", "xm w704 h30", I18n.t("remap.palette_title"))
        this.GuiObj.SetFont("s9 norm c" dim, "Segoe UI")
        this.GuiObj.Add("Text", "xm y+1 w704 h20", I18n.t("remap.context") this.ActiveProcess)

        this.GuiObj.SetFont("s18 bold c" accent, "Consolas")
        this.KeysDisplay := this.GuiObj.Add("Text",
            "xm y+12 w704 h38 Center Background0x" surfHex, I18n.t("remap.waiting"))
        this.GuiObj.SetFont("s9 norm c" dim, "Segoe UI")
        this.StatusDisplay := this.GuiObj.Add("Text", "xm y+7 w704 h20", "")
        this.GuiObj.Add("Text", "xm y+3 w704 h1 Background0x" borderHex)

        this.GuiObj.SetFont("s10 norm c" bright, "Segoe UI")
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xm y+5 w704 r11 Grid -Multi Background0x" surfHex " c" bright,
            [I18n.t("col.remap"), I18n.t("col.desc"), I18n.t("col.trigger")])
        this.ShortcutLV.ModifyCol(1, 130)
        this.ShortcutLV.ModifyCol(2, 370)
        this.ShortcutLV.ModifyCol(3, 185)

        this.GuiObj.SetFont("s9 norm c" dim, "Segoe UI")
        this.GuiObj.Add("Text", "xm y+8 w704 Center", I18n.t("remap.vim_footer"))
        this.GuiObj.Show("AutoSize NoActivate xCenter yCenter")
    }

    static _StartInput() {
        this.InputHk := InputHook("L0")
        this.InputHk.NotifyNonText := true
        this.InputHk.KeyOpt("{All}", "N S")
        this.InputHk.OnKeyDown := this._OnKeyDown.Bind(this)
        this.InputHk.OnKeyUp := this._OnKeyUp.Bind(this)
        this.InputHk.Start()
        this._StartTimeout()
    }

    static _WaitForActivationRelease() {
        if (!this.IsVisible)
            return
        this.ActivationKey := RegExReplace(Config.GetTriggerHotkey(), "[<>^+!#*~$]")
        this.ActivationKey := Trim(StrReplace(this.ActivationKey, " Up", ""))
        triggerHeld := false
        if (this.ActivationKey != "")
            try triggerHeld := GetKeyState(this.ActivationKey, "P")
        if (GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P")
            || GetKeyState("Shift", "P") || GetKeyState("LWin", "P")
            || GetKeyState("RWin", "P") || triggerHeld) {
            this.TimerObj := ObjBindMethod(this, "_WaitForActivationRelease")
            SetTimer(this.TimerObj, -25)
            return
        }
        this.TimerObj := ""
        this._StartInput()
    }

    static _OnKeyDown(ih, vk, sc) {
        if (this.IsClosing)
            return
        physicalKey := vk ":" sc
        if (this.HeldKeys.Has(physicalKey))
            return
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
        this.HeldKeys[physicalKey] := keyName

        if (vk = 0x1B) {
            this.Hide()
            return
        }
        if (vk = 0x0D) {
            if (this.ExactMatch != "")
                this._Execute(this.ExactMatch)
            return
        }
        if (vk = 0x08) {
            if (this.Sequence.Length > 0)
                this.Sequence.Pop()
            this._FilterCandidates()
            return
        }

        key := RemapManager.NormalizeKey(keyName)
        if (key = "" || this._IsModifier(key))
            return
        if (!this._IsAllowedKey(key)) {
            this._UpdateStatus(I18n.t("remap.key_not_available") key)
            return
        }

        this.Sequence.Push(key)
        this._FilterCandidates()
    }

    static _OnKeyUp(ih, vk, sc) {
        physicalKey := vk ":" sc
        if (this.HeldKeys.Has(physicalKey))
            this.HeldKeys.Delete(physicalKey)
    }

    static _FilterCandidates() {
        this.Filtered := Array()
        this.ExactMatch := ""
        hasLongerMatch := false

        for shortcut in this.Candidates {
            remapKeys := RemapManager.ParseSequence(shortcut["remapKeys"])
            if (!this._SequenceMatchesPrefix(remapKeys))
                continue
            this.Filtered.Push(shortcut)
            if (remapKeys.Length = this.Sequence.Length)
                this.ExactMatch := shortcut
            else
                hasLongerMatch := true
        }

        this._RenderCandidates()
        if (this.Filtered.Length = 0) {
            this._UpdateStatus(I18n.t("remap.no_match"))
            this._SetCloseTimer(800)
            return
        }
        if (this.ExactMatch != "" && !hasLongerMatch) {
            this._Execute(this.ExactMatch)
            return
        }

        if (this.ExactMatch != "")
            this._UpdateStatus(I18n.t("remap.exact_waiting"))
        else
            this._UpdateStatus(this.Filtered.Length . I18n.t("remap.partial"))
        this._StartTimeout()
    }

    static _SequenceMatchesPrefix(candidate) {
        if (candidate.Length < this.Sequence.Length)
            return false
        for index, key in this.Sequence {
            if (candidate[index] != key)
                return false
        }
        return true
    }

    static _RenderCandidates() {
        this.ShortcutLV.Delete()
        maxItems := Config.GetCheatsheetMaxItems()
        for index, shortcut in this.Filtered {
            if (index > maxItems)
                break
            remap := RemapManager.FormatSequence(shortcut["remapKeys"])
            desc := shortcut.Has("description") ? shortcut["description"] : ""
            original := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
            this.ShortcutLV.Add(, remap, desc, original)
        }
        this._UpdateDisplay()
        if (this.Sequence.Length = 0)
            this._UpdateStatus(this.Filtered.Length . I18n.t("remap.available"))
    }

    static _UpdateDisplay() {
        this.KeysDisplay.Text := this.Sequence.Length = 0
            ? I18n.t("remap.waiting") : RemapManager.FormatSequence(this.Sequence)
    }

    static _UpdateStatus(message) {
        if (this.StatusDisplay != "")
            this.StatusDisplay.Text := message
    }

    static _Execute(shortcut) {
        if (this.IsClosing)
            return
        if (!shortcut.Has("targetKeys") || shortcut["targetKeys"] = "") {
            this._UpdateStatus(I18n.t("remap.err_target"))
            this._SetCloseTimer(1000)
            return
        }
        targetKeys := shortcut["targetKeys"]
        targetHwnd := this.TargetHwnd
        targetProcess := this.ActiveProcess
        this.IsClosing := true
        this._StopTimeout()

        released := this._WaitForHeldKeysRelease(2000)
        if (!released) {
            this.Hide()
            TrayTip(I18n.t("remap.release_timeout"), "Key Atlas", "Icon!")
            return
        }
        this.Hide()

        if (!WinExist("ahk_id " targetHwnd) || WinExist("A") != targetHwnd) {
            TrayTip(I18n.t("remap.context_changed"), "Key Atlas", "Icon!")
            return
        }
        currentProcess := ""
        try currentProcess := WinGetProcessName(targetHwnd)
        if (StrLower(currentProcess) != StrLower(targetProcess)) {
            TrayTip(I18n.t("remap.context_changed"), "Key Atlas", "Icon!")
            return
        }

        try {
            SetKeyDelay(-1, -1)
            Send(targetKeys)
        } catch as err {
            TrayTip(I18n.t("remap.err_prefix") err.Message, "Key Atlas", "Icon!")
        }
    }

    static _WaitForHeldKeysRelease(timeoutMs) {
        deadline := A_TickCount + timeoutMs
        loop {
            heldKeyNames := Array()
            for _, keyName in this.HeldKeys
                heldKeyNames.Push(keyName)
            anyHeld := false
            for keyName in heldKeyNames {
                try {
                    if (GetKeyState(keyName, "P")) {
                        anyHeld := true
                        break
                    }
                }
            }
            if (!anyHeld)
                return true
            if (A_TickCount >= deadline)
                return false
            Sleep(10)
        }
    }

    static _IsAllowedKey(key) {
        for allowedKey in this.AvailableKeys {
            if (key = allowedKey)
                return true
        }
        return false
    }

    static _IsModifier(key) {
        return key = "ctrl" || key = "alt" || key = "shift" || key = "lwin"
            || key = "rwin" || key = "lshift" || key = "rshift"
            || key = "lalt" || key = "ralt" || key = "lctrl" || key = "rctrl"
    }

    static _StartTimeout() {
        this._StopTimeout()
        timeoutMs := Max(500, Integer(this.Timeout * 1000))
        this.TimerObj := ObjBindMethod(this, "_OnTimeout")
        SetTimer(this.TimerObj, -timeoutMs)
    }

    static _SetCloseTimer(delay) {
        this._StopTimeout()
        this.TimerObj := ObjBindMethod(this, "Hide")
        SetTimer(this.TimerObj, -delay)
    }

    static _StopTimeout() {
        if (this.TimerObj != "") {
            SetTimer(this.TimerObj, 0)
            this.TimerObj := ""
        }
    }

    static _OnTimeout() {
        this.TimerObj := ""
        if (!this.IsVisible)
            return
        if (this.ExactMatch != "")
            this._Execute(this.ExactMatch)
        else
            this.Hide()
    }
}
