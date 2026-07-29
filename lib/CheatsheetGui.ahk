; ============================================================
; CheatsheetGui.ahk - Which-key Style Overlay
; ============================================================

class CheatsheetGui {
    static GuiObj := ""
    static IsVisible := false
    static Shortcuts := Array()
    static Groups := Map()
    static SelectedIndex := 1
    static SearchQuery := ""
    static InputHk := ""
    static ShortcutLV := ""
    static StatusText := ""
    static ActiveProgram := ""
    static ActiveProcess := ""

    static Show() {
        if (this.IsVisible)
            return

        this.ActiveProcess := WinGetProcessName("A")
        this.ActiveProgram := WinGetTitle("A")
        this.Shortcuts := Database.GetForActiveWindow()
        this.Groups := Database.GroupByCategory(this.Shortcuts)
        this.SelectedIndex := 1
        this.SearchQuery := ""

        this._CreateOverlay()
        this._RenderList()
        this._UpdateStatus()
        this._StartInput()
        this.IsVisible := true
    }

    static Hide() {
        if (!this.IsVisible)
            return

        this._StopInput()
        try this.GuiObj.Destroy()
        this.GuiObj := ""
        this.IsVisible := false
    }

    static Toggle() {
        if (this.IsVisible)
            this.Hide()
        else
            this.Show()
    }

    ; ==========================================================
    ; Overlay GUI (created once per Show)
    ; ==========================================================

    static _CreateOverlay() {
        this.GuiObj := Gui("+ToolWindow +AlwaysOnTop -Caption +Border -SysMenu +Owner")

        bgColor := Theme.ToBGR(Theme.OVERLAY())
        this.GuiObj.BackColor := bgColor
        this.GuiObj.Opt("+LastFound")
        WinSetTransparent(Config.GetCheatsheetOpacity(), this.GuiObj)

        this.GuiObj.MarginX := 12
        this.GuiObj.MarginY := 8

        accColor := Format("{:06X}", Theme.ToBGR(Theme.ACC()))
        brightColor := Format("{:06X}", Theme.ToBGR(Theme.TXTBRIGHT()))
        dimColor := Format("{:06X}", Theme.ToBGR(Theme.TXTDIM()))
        surfColor := Format("{:06X}", Theme.ToBGR(Theme.SURF()))
        bdrColor := Format("{:06X}", Theme.ToBGR(Theme.BDR()))

        ; Header
        this.GuiObj.SetFont("s11 bold c0x" brightColor, "Consolas")
        processName := this.ActiveProcess
        if (StrLen(processName) > 55)
            processName := SubStr(processName, 1, 52) . "..."
        this.GuiObj.Add("Text", "xm w580", I18n.t("sheet.header") processName)

        ; Status / search info
        this.GuiObj.SetFont("s9 c0x" dimColor, "Consolas")
        this.StatusText := this.GuiObj.Add("Text", "xm y+2 w580", "")

        ; Separator
        this.GuiObj.Add("Text", "xm y+4 w580 h1 Background0x" bdrColor)

        ; Shortcuts ListView
        this.GuiObj.SetFont("s9 c0x" brightColor, "Consolas")
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xm y+4 w580 r14 Grid -Hdr -Multi Background0x" surfColor .
            " c0x" brightColor,
            ["Line"])

        ; Footer
        this.GuiObj.SetFont("s8 c0x" dimColor, "Consolas")
        footerText := "[" HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger())
            . "]" I18n.t("sheet.footer")
        this.GuiObj.Add("Text", "xm y+6 w580", footerText)

        this.GuiObj.Show("AutoSize NoActivate")
    }

    ; ==========================================================
    ; List Rendering (no destroy, just update LV + status text)
    ; ==========================================================

    static _RenderList() {
        this.ShortcutLV.Delete()
        itemIdx := 0
        total := 0
        maxItems := Config.GetCheatsheetMaxItems()

        for catName, catShortcuts in this.Groups {
            for shortcut in catShortcuts {
                if (total >= maxItems)
                    break

                total++
                desc := shortcut.Has("description") ? shortcut["description"] : "(--)"
                trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
                catTag := "[" catName "]"

                if (StrLen(desc) > 30)
                    desc := SubStr(desc, 1, 27) . "..."

                displayText := Format("     {1:-8} {2:-30} {3}",
                    catTag, desc, trigger)
                this.ShortcutLV.Add(, displayText)
            }
            if (total >= maxItems)
                break
        }

        if (total = 0) {
            this.ShortcutLV.Add(, "  " I18n.t("sheet.no_shortcuts"))
            this.ShortcutLV.Add(, "  " I18n.t("sheet.hint"))
        }

        ; Select current index
        if (this.SelectedIndex > total)
            this.SelectedIndex := Max(1, total)
        if (total > 0)
            this.ShortcutLV.Modify(this.SelectedIndex, "Select Vis")

        this.ShortcutLV.ModifyCol(1, 570)
    }

    static _UpdateStatus() {
        if (this.SearchQuery != "")
            this.StatusText.Text := I18n.t("sheet.search") this.SearchQuery
                . " (" this.Shortcuts.Length ")"
        else
            this.StatusText.Text := this.Shortcuts.Length I18n.t("sheet.available")
    }

    ; ==========================================================
    ; Input Handling
    ; ==========================================================

    static _StartInput() {
        this.InputHk := InputHook("L20 T10")
        this.InputHk.KeyOpt("{Esc}", "E")
        this.InputHk.KeyOpt("{Enter}", "E")
        this.InputHk.KeyOpt("{Up}{Down}{Left}{Right}", "N V")
        this.InputHk.KeyOpt("{Backspace}", "N")
        this.InputHk.NotifyNonText := true
        this.InputHk.OnChar := this._OnChar.Bind(this)
        this.InputHk.OnKeyDown := this._OnKeyDown.Bind(this)
        this.InputHk.OnEnd := this._OnEnd.Bind(this)
        this.InputHk.Start()
    }

    static _StopInput() {
        try this.InputHk.Stop()
        this.InputHk := ""
    }

    static _OnChar(ih, char) {
        this.SearchQuery .= char
        this.SelectedIndex := 1
        this._ApplyFilter()
    }

    static _ApplyFilter() {
        query := StrLower(this.SearchQuery)
        if (query = "") {
            this.Shortcuts := Database.GetForActiveWindow()
        } else {
            filtered := Array()
            for shortcut in Database.GetForActiveWindow() {
                desc := StrLower(shortcut.Has("description") ? shortcut["description"] : "")
                trig := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
                if (InStr(desc, query) || InStr(trig, query) = 1)
                    filtered.Push(shortcut)
            }
            this.Shortcuts := filtered
        }
        this.Groups := Database.GroupByCategory(this.Shortcuts)
        this._RenderList()
        this._UpdateStatus()
    }

    static _OnKeyDown(ih, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))

        ; Ctrl+N: quick-add shortcut
        if (keyName = "n" && GetKeyState("Ctrl", "P")) {
            GuiManager.QuickAdd(this.ActiveProgram, this.ActiveProcess, this.SearchQuery)
            return
        }

        if (vk = 0x26) { ; Up
            if (this.SelectedIndex > 1)
                this.SelectedIndex--
            this._RenderList()
        } else if (vk = 0x28) { ; Down
            totalItems := this.ShortcutLV.GetCount()
            if (this.SelectedIndex < totalItems)
                this.SelectedIndex++
            this._RenderList()
        } else if (vk = 0x08) { ; Backspace
            if (StrLen(this.SearchQuery) > 0) {
                this.SearchQuery := SubStr(this.SearchQuery, 1, -1)
                this.SelectedIndex := 1
                this._ApplyFilter()
            }
        }
    }

    static _OnEnd(ih) {
        if (ih.EndReason = "EndKey") {
            if (ih.EndKey = "Escape") {
                this.Hide()
            } else if (ih.EndKey = "Enter") {
                this._ExecuteSelected()
                this.Hide()
            }
        }
    }

    ; ==========================================================
    ; Execution
    ; ==========================================================

    static _ExecuteSelected() {
        selectedShortcut := this._GetSelectedShortcut()
        if (selectedShortcut = "")
            return

        this._SendShortcut(selectedShortcut)
    }

    static _GetSelectedShortcut() {
        idx := 0
        for _, shortcuts in this.Groups {
            for shortcut in shortcuts {
                idx++
                if (idx = this.SelectedIndex)
                    return shortcut
            }
        }
        return ""
    }

    static _SendShortcut(shortcut) {
        if (!shortcut.Has("targetKeys") || shortcut["targetKeys"] = "")
            return

        targetKeys := shortcut["targetKeys"]
        try {
            SetKeyDelay(-1, -1)
            Send(targetKeys)
        } catch as err {
            TrayTip("Error: " err.Message, "Key Atlas", "Icon!")
        }
    }
}
