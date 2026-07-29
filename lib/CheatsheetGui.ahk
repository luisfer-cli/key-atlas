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
    static RowControls := Array()
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
        this.RowControls := Array()

        this._CreateGui()
        this._Render()
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
    ; Internal: GUI Creation
    ; ==========================================================

    static _CreateGui() {
        this.GuiObj := Gui("+ToolWindow +AlwaysOnTop -Caption +Border -SysMenu +Owner")

        bgColor := Theme.ToBGR(Theme.OVERLAY())
        bdrColor := Theme.ToBGR(Theme.BDR())

        this.GuiObj.BackColor := bgColor
        this.GuiObj.Opt("+LastFound")
        WinSetTransparent(Config.GetCheatsheetOpacity(), this.GuiObj)

        ; Set font
        fontSize := Config.Get("cheatsheet.fontSize", 10)
        fgColor := Theme.ToBGR(Theme.TXT())
        this.GuiObj.SetFont("s" . fontSize . " c0x" . Format("{:06X}", fgColor), "Consolas")
        this.GuiObj.MarginX := 12
        this.GuiObj.MarginY := 8
    }

    ; ==========================================================
    ; Internal: Render Shortcuts
    ; ==========================================================

    static _Render() {
        this._ClearControls()

        headerColor := Theme.ToBGR(Theme.ACC())
        dimColor := Theme.ToBGR(Theme.TXTDIM())
        brightColor := Theme.ToBGR(Theme.TXTBRIGHT())

        this.GuiObj.SetFont("s11 bold c0x" . Format("{:06X}", brightColor), "Consolas")

        processName := this.ActiveProcess
        if (StrLen(processName) > 40)
            processName := SubStr(processName, 1, 37) . "..."

        headerTxt := this.GuiObj.Add("Text", "xm y" . this.GuiObj.MarginY . " w500",
            I18n.t("sheet.header") . processName)
        this.RowControls.Push(headerTxt)

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", dimColor), "Consolas")

        if (this.SearchQuery != "")
            this.GuiObj.Add("Text", "xm y+2 w500",
                I18n.t("sheet.search") this.SearchQuery " (" this.Shortcuts.Length I18n.t("sheet.results"))
        else
            this.GuiObj.Add("Text", "xm y+2 w500",
                this.Shortcuts.Length I18n.t("sheet.available"))

        ; Separator line
        sepColor := Theme.ToBGR(Theme.BDR())
        this.GuiObj.Add("Text", "xm y+4 w500 h1 Background0x" . Format("{:06X}", sepColor), "")

        ; Render shortcuts grouped by category
        rowY := 0
        itemIdx := 0
        maxItems := Config.GetCheatsheetMaxItems()
        rendered := 0

        for catName, catShortcuts in this.Groups {
            if (rendered >= maxItems)
                break

            ; Category header
            accColor := Theme.ToBGR(Theme.ACC())
            this.GuiObj.SetFont("s9 bold c0x" . Format("{:06X}", accColor), "Consolas")

            catLabel := this.GuiObj.Add("Text", "xm y+8 w500", catName)
            this.RowControls.Push(catLabel)
            catLabel.GetPos(,,, &rowHeight)
            rowY += 8 + rowHeight
            rendered++

            for shortcut in catShortcuts {
                if (rendered >= maxItems + 1)
                    break

                itemIdx++
                isSelected := itemIdx = this.SelectedIndex

                bgOpt := isSelected ? " Background0x" . Format("{:06X}", Theme.ToBGR(Theme.HL())) : ""
                txtColor := isSelected ? Theme.ToBGR(Theme.TXTBRIGHT()) : Theme.ToBGR(Theme.TXT())

                this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Consolas")

                desc := shortcut.Has("description") ? shortcut["description"] : "(--)"
                trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
                mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
                modeIndicator := mode = "remap" ? "[R]" : "[C]"

                displayText := Format("{1:-6} {2:-35} {3}",
                    modeIndicator, desc, trigger)

                ctrl := this.GuiObj.Add("Text", "xm y+2 w600" . bgOpt, displayText)
                this.RowControls.Push(ctrl)
                rendered++
            }
        }

        if (itemIdx = 0) {
            warnColor := Theme.ToBGR(Theme.GetColor("warning"))
            this.GuiObj.SetFont("s10 c0x" . Format("{:06X}", warnColor), "Consolas")
            noResults := this.GuiObj.Add("Text", "xm y+10 w500", I18n.t("sheet.no_shortcuts"))
            this.RowControls.Push(noResults)

            dimColor := Theme.ToBGR(Theme.TXTDIM())
            this.GuiObj.SetFont("s8 c0x" . Format("{:06X}", dimColor), "Consolas")
            hint := this.GuiObj.Add("Text", "xm y+2 w500", I18n.t("sheet.hint"))
            this.RowControls.Push(hint)
        }

        ; Footer
        dimColor := Theme.ToBGR(Theme.TXTDIM())
        this.GuiObj.SetFont("s8 c0x" . Format("{:06X}", dimColor), "Consolas")
        footer := this.GuiObj.Add("Text", "xm y+12 w500",
            "[" . HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger())
            . "]" I18n.t("sheet.footer"))
        this.RowControls.Push(footer)

        this.GuiObj.Show("AutoSize NoActivate")
    }

    static _ClearControls() {
        for ctrl in this.RowControls {
            try ctrl.Destroy()
        }
        this.RowControls := Array()
    }

    ; ==========================================================
    ; Internal: Input Handling for Filtering
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

        query := StrLower(this.SearchQuery)
        filtered := Array()
        activeShortcuts := Database.GetForActiveWindow()

        for shortcut in activeShortcuts {
            desc := StrLower(shortcut.Has("description") ? shortcut["description"] : "")
            trig := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
            if (InStr(desc, query) || InStr(trig, query) = 1)
                filtered.Push(shortcut)
        }

        this.Shortcuts := filtered
        this.Groups := Database.GroupByCategory(this.Shortcuts)
        this._Render()
    }

    static _OnKeyDown(ih, vk, sc) {
        keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))

        ; Ctrl+N: quick-add shortcut for current program
        if (keyName = "n" && (GetKeyState("Ctrl", "P"))) {
            GuiManager.QuickAdd(this.ActiveProgram, this.ActiveProcess, this.SearchQuery)
            return
        }

        if (vk = 0x26) { ; Up
            if (this.SelectedIndex > 1)
                this.SelectedIndex--
            this._Render()
        } else if (vk = 0x28) { ; Down
            totalItems := 0
            for _, shortcuts in this.Groups
                totalItems += shortcuts.Length
            if (this.SelectedIndex < totalItems)
                this.SelectedIndex++
            this._Render()
        } else if (vk = 0x08) { ; Backspace
            if (StrLen(this.SearchQuery) > 0) {
                this.SearchQuery := SubStr(this.SearchQuery, 1, -1)
                this.SelectedIndex := 1

                query := StrLower(this.SearchQuery)
                filtered := Array()
                activeShortcuts := Database.GetForActiveWindow()

                for shortcut in activeShortcuts {
                    desc := StrLower(shortcut.Has("description") ? shortcut["description"] : "")
                    trig := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
                    if (InStr(desc, query) || InStr(trig, query) = 1)
                        filtered.Push(shortcut)
                }

                this.Shortcuts := filtered
                this.Groups := Database.GroupByCategory(this.Shortcuts)
                this._Render()
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
    ; Internal: Execution
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
            TrayTip("Error executing shortcut: " err.Message, "Key Atlas", "Icon!")
        }
    }
}
