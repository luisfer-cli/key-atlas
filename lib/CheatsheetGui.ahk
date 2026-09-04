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
    static SearchText := ""
    static DisplayedCount := 0
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

        this.GuiObj.BackColor := Theme.ToBGR(Theme.OVERLAY())
        this.GuiObj.Opt("+LastFound")
        WinSetTransparent(Config.GetCheatsheetOpacity(), this.GuiObj)

        this.GuiObj.MarginX := 18
        this.GuiObj.MarginY := 14

        bright := Theme.TXTBRIGHT()
        dim := Theme.TXTDIM()
        surfBGR := Theme.ToBGR(Theme.SURF())
        bdrBGR := Theme.ToBGR(Theme.BDR())
        surfHex := Format("{:06X}", surfBGR)
        bdrHex := Format("{:06X}", bdrBGR)

        ; Header
        this.GuiObj.SetFont("s17 bold c" bright, "Segoe UI")
        this.GuiObj.Add("Text", "xm w704 h30", I18n.t("sheet.title"))
        this.GuiObj.SetFont("s9 c" dim, "Segoe UI")
        processName := this.ActiveProcess
        if (StrLen(processName) > 55)
            processName := SubStr(processName, 1, 52) . "..."
        this.GuiObj.Add("Text", "xm y+1 w704 h20", I18n.t("sheet.context") processName)

        ; Visible search affordance
        this.GuiObj.SetFont("s10 c" bright, "Segoe UI")
        this.SearchText := this.GuiObj.Add("Text", "xm y+12 w704 h30 Background0x" surfHex,
            "  " I18n.t("sheet.search_empty"))
        this.GuiObj.SetFont("s9 c" dim, "Segoe UI")
        this.StatusText := this.GuiObj.Add("Text", "xm y+7 w704 h20", "")

        ; Separator
        this.GuiObj.Add("Text", "xm y+3 w704 h1 Background0x" bdrHex)

        ; Shortcuts ListView
        this.GuiObj.SetFont("s10 c" bright, "Segoe UI")
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xm y+5 w704 r14 Grid -Multi Background0x" surfHex " c" bright,
            [I18n.t("col.trigger"), I18n.t("col.desc"), I18n.t("col.category")])
        this.ShortcutLV.OnEvent("DoubleClick", (_, row) => this._ExecuteAndClose(row))

        ; Footer
        this.GuiObj.SetFont("s9 c" dim, "Segoe UI")
        this.GuiObj.Add("Text", "xm y+8 w704 Center", I18n.t("sheet.footer"))

        this.GuiObj.Show("AutoSize NoActivate")
    }

    ; ==========================================================
    ; List Rendering (no destroy, just update LV + status text)
    ; ==========================================================

    static _RenderList() {
        this.ShortcutLV.Delete()
        total := 0
        maxItems := Config.GetCheatsheetMaxItems()

        for catName, catShortcuts in this.Groups {
            for shortcut in catShortcuts {
                if (total >= maxItems)
                    break

                total++
                desc := shortcut.Has("description") ? shortcut["description"] : "(--)"
                trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
                mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
                category := catName
                if (mode = "cheatsheet")
                    category .= "  -  " I18n.t("sheet.reference")
                this.ShortcutLV.Add(, trigger, desc, category)
            }
            if (total >= maxItems)
                break
        }

        if (total = 0) {
            this.ShortcutLV.Add(, "", I18n.t("sheet.no_shortcuts"), "")
            this.ShortcutLV.Add(, "Ctrl+N", I18n.t("sheet.hint"), "")
        }
        this.DisplayedCount := total

        ; Select current index
        if (this.SelectedIndex > total)
            this.SelectedIndex := Max(1, total)
        if (total > 0)
            this.ShortcutLV.Modify(this.SelectedIndex, "Select Vis")

        this.ShortcutLV.ModifyCol(1, 115)
        this.ShortcutLV.ModifyCol(2, 375)
        this.ShortcutLV.ModifyCol(3, 195)
    }

    static _UpdateStatus() {
        if (this.SearchQuery != "")
            this.SearchText.Text := "  " I18n.t("sheet.search") this.SearchQuery
        else
            this.SearchText.Text := "  " I18n.t("sheet.search_empty")
        shortcutCount := this.Shortcuts is Array ? this.Shortcuts.Length : 0
        this.StatusText.Text := this.DisplayedCount . " " . I18n.t("sheet.showing")
            . " " . shortcutCount
    }

    ; ==========================================================
    ; Input Handling
    ; ==========================================================

    static _StartInput() {
        this.InputHk := InputHook("L20 T10", "{Esc}{Enter}")
        this.InputHk.KeyOpt("{Esc}{Enter}", "-N")
        this.InputHk.KeyOpt("{Up}{Down}{Left}{Right}{Backspace}", "N S")
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
            program := this.ActiveProgram
            process := this.ActiveProcess
            trigger := this.SearchQuery
            this.Hide()
            GuiManager.QuickAdd(program, process, trigger)
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
            endKey := StrLower(ih.EndKey)
            if (endKey = "escape" || endKey = "esc") {
                this.Hide()
            } else if (endKey = "enter") {
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

        if (selectedShortcut.Has("mode") && selectedShortcut["mode"] = "cheatsheet") {
            TrayTip(I18n.t("sheet.reference_notice"), "Key Atlas", "Iconi")
            return
        }

        this._SendShortcut(selectedShortcut)
    }

    static _ExecuteAndClose(row) {
        if (row = 0)
            return
        this.SelectedIndex := row
        this._ExecuteSelected()
        this.Hide()
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
