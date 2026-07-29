; ============================================================
; GuiManager.ahk - Main Configuration Window
; ============================================================

class GuiManager {
    static GuiObj := ""
    static IsVisible := false
    static TabCtrl := ""
    static ShortcutLV := ""
    static SearchEdit := ""
    static EditingId := ""

    static Show() {
        if (this.IsVisible) {
            this.GuiObj.Show()
            WinActivate(this.GuiObj.Hwnd)
            return
        }
        this._CreateGui()
        this._PopulateListView()
        this.GuiObj.Show("w820 h600 Center")
        this.IsVisible := true
    }

    static Hide() {
        if (this.IsVisible) {
            this.GuiObj.Hide()
        }
    }

    static Close() {
        this.IsVisible := false
        try this.GuiObj.Destroy()
        this.GuiObj := ""
    }

    ; ==========================================================
    ; Internal: Main GUI Creation
    ; ==========================================================

    static _CreateGui() {
        bgColor := Theme.ToBGR(Theme.BG())
        txtColor := Theme.ToBGR(Theme.TXT())

        this.GuiObj := Gui("+Resize +MinSize640x480", "Key Atlas - Configuracion")
        this.GuiObj.BackColor := bgColor
        this.GuiObj.MarginX := 10
        this.GuiObj.MarginY := 10

        this.GuiObj.OnEvent("Close", (*) => this.Close())
        this.GuiObj.OnEvent("Escape", (*) => this.Close())

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        this.TabCtrl := this.GuiObj.Add("Tab3", "w780 h520 +Theme",
            ["Atajos", "Editor", "Configuracion"])

        this._CreateShortcutsTab()
        this._CreateEditorTab()
        this._CreateSettingsTab()

        this.TabCtrl.UseTab()
    }

    ; ==========================================================
    ; Tab 1: Shortcuts List
    ; ==========================================================

    static _CreateShortcutsTab() {
        this.TabCtrl.UseTab(1)

        ; Search bar
        this.GuiObj.Add("Text", "xm y+5 w60", "Buscar:")
        this.SearchEdit := this.GuiObj.Add("Edit", "x+5 yp-3 w300")
        this.SearchEdit.OnEvent("Change", (*) => this._OnSearchChange())

        ; Refresh button
        btnColor := Theme.ToBGR(Theme.ACC())
        this.GuiObj.SetFont("s9 bold c0x" . Format("{:06X}", btnColor), "Segoe UI")
        refreshBtn := this.GuiObj.Add("Button", "x+10 yp w80", "Recargar")
        refreshBtn.OnEvent("Click", (*) => this._PopulateListView())

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", Theme.ToBGR(Theme.TXT())), "Segoe UI")

        ; ListView
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xm y+10 w760 r20 Grid -Multi Sort Background0x" .
            Format("{:06X}", Theme.ToBGR(Theme.SURF())) .
            " c0x" . Format("{:06X}", Theme.ToBGR(Theme.TXT())),
            ["ID", "Programa", "Proceso", "Categoria", "Descripcion", "Trigger", "Target", "Modo"])
        this.ShortcutLV.OnEvent("DoubleClick", (*) => this._OnDoubleClick())

        ; Set column widths
        this.ShortcutLV.ModifyCol(1, 0)   ; ID hidden
        this.ShortcutLV.ModifyCol(2, 120)
        this.ShortcutLV.ModifyCol(3, 100)
        this.ShortcutLV.ModifyCol(4, 80)
        this.ShortcutLV.ModifyCol(5, 160)
        this.ShortcutLV.ModifyCol(6, 100)
        this.ShortcutLV.ModifyCol(7, 80)
        this.ShortcutLV.ModifyCol(8, 50)

        ; Action buttons
        btnColor := Theme.ToBGR(Theme.ACC())
        surfColor := Theme.ToBGR(Theme.SURF())

        btnStyle := "w100 h28 Background0x" . Format("{:06X}", surfColor) .
            " c0x" . Format("{:06X}", btnColor)

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", btnColor), "Segoe UI")

        addBtn := this.GuiObj.Add("Button", "xm y+10 " . btnStyle, "Nuevo Atajo")
        addBtn.OnEvent("Click", (*) => this._OnNewShortcut())

        editBtn := this.GuiObj.Add("Button", "x+10 yp " . btnStyle, "Editar")
        editBtn.OnEvent("Click", (*) => this._OnEditShortcut())

        delBtn := this.GuiObj.Add("Button", "x+10 yp " . btnStyle . " c0x" .
            Format("{:06X}", Theme.ToBGR(Theme.GetColor("error"))), "Eliminar")
        delBtn.OnEvent("Click", (*) => this._OnDeleteShortcut())

        exportBtn := this.GuiObj.Add("Button", "x+10 yp " . btnStyle, "Exportar")
        exportBtn.OnEvent("Click", (*) => this._OnExport())
    }

    ; ==========================================================
    ; Tab 2: Shortcut Editor
    ; ==========================================================

    static _CreateEditorTab() {
        this.TabCtrl.UseTab(2)

        txtColor := Theme.ToBGR(Theme.TXT())
        surfColor := Theme.ToBGR(Theme.SURF())
        bdrColor := Theme.ToBGR(Theme.BDR())
        accColor := Theme.ToBGR(Theme.ACC())

        inputStyle := "w350 Background0x" . Format("{:06X}", surfColor) .
            " c0x" . Format("{:06X}", txtColor)

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        ; Program name
        this.GuiObj.Add("Text", "xm y+10 w120", "Programa:")
        this.EdProgram := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)

        ; Process name
        this.GuiObj.Add("Text", "xm y+5 w120", "Proceso (.exe):")
        this.EdProcess := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)

        ; Detect from active window
        detectBtn := this.GuiObj.Add("Button", "x+10 yp-3 w160 h23",
            "Detectar ventana activa")
        detectBtn.OnEvent("Click", (*) => this._DetectActiveWindow())

        ; Category
        this.GuiObj.Add("Text", "xm y+5 w120", "Categoria:")
        this.EdCategory := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)

        ; Description
        this.GuiObj.Add("Text", "xm y+5 w120", "Descripcion:")
        this.EdDescription := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)

        ; Trigger keys
        this.GuiObj.Add("Text", "xm y+5 w120", "Teclas Trigger:")
        this.EdTrigger := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)
        this.GuiObj.Add("Text", "x+10 y+0 w350",
            "Combinacional: Ctrl+S | Secuencial: g d | O usa: ^!+s")

        ; Target keys (AHK Send format)
        this.GuiObj.Add("Text", "xm y+5 w120", "Teclas Target:")
        this.EdTarget := this.GuiObj.Add("Edit", "x+10 yp-3 " . inputStyle)
        this.GuiObj.Add("Text", "x+10 y+0 w350",
            "Formato AHK Send: ^s (Ctrl+S), !f (Alt+F), +{Tab}")

        ; Mode
        this.GuiObj.Add("Text", "xm y+5 w120", "Modo:")
        this.CbMode := this.GuiObj.Add("DropDownList", "x+10 yp-3 w200 Choose1",
            ["remap (ejecuta target)", "cheatsheet (solo mostrar)"])

        ; Action buttons
        this.GuiObj.Add("Text", "xm y+20 w120", "")
        surfColor := Theme.ToBGR(Theme.SURF())
        btnStyle := "w150 h30 Background0x" . Format("{:06X}", surfColor) .
            " c0x" . Format("{:06X}", accColor)

        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")

        saveBtn := this.GuiObj.Add("Button", "x+10 yp-3 " . btnStyle, "Guardar Atajo")
        saveBtn.OnEvent("Click", (*) => this._SaveShortcut())

        cancelBtn := this.GuiObj.Add("Button", "x+10 yp " . btnStyle . " c0x" .
            Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())), "Cancelar")
        cancelBtn.OnEvent("Click", (*) => this._ClearEditor())

        ; Hidden control for editing ID
        this.EdId := this.GuiObj.Add("Edit", "x0 y0 w0 h0 Hidden")
    }

    ; ==========================================================
    ; Tab 3: Settings
    ; ==========================================================

    static _CreateSettingsTab() {
        this.TabCtrl.UseTab(3)

        txtColor := Theme.ToBGR(Theme.TXT())
        surfColor := Theme.ToBGR(Theme.SURF())
        accColor := Theme.ToBGR(Theme.ACC())

        inputStyle := "w300 Background0x" . Format("{:06X}", surfColor) .
            " c0x" . Format("{:06X}", txtColor)

        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        ; ---- Trigger Hotkey ----
        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+10 w200", "Hotkey de Activacion")
        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        this.GuiObj.Add("Text", "xm y+5 w120", "Combinacion:")
        this.SettingsTrigger := this.GuiObj.Add("Hotkey", "x+10 yp-3 " . inputStyle)
        this.SettingsTrigger.Value := HotkeyManager.GetCurrentTrigger()

        applyTriggerBtn := this.GuiObj.Add("Button", "x+10 yp-3 w100 h23",
            "Aplicar")
        applyTriggerBtn.OnEvent("Click", (*) => this._ApplyTrigger())

        ; ---- Default Mode ----
        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+15 w200", "Modo por Defecto")
        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        currentMode := HotkeyManager.GetCurrentMode()
        initialMode := currentMode = "cheatsheet" ? 1 : 2
        this.SettingsMode := this.GuiObj.Add("DropDownList",
            "xm y+5 w300 Choose" . initialMode,
            ["Cheatsheet (ver atajos del programa activo)",
             "Remap (ejecutar atajos directamente)"])

        applyModeBtn := this.GuiObj.Add("Button", "x+10 yp-3 w100 h23", "Aplicar")
        applyModeBtn.OnEvent("Click", (*) => this._ApplyMode())

        ; ---- Theme ----
        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+15 w200", "Tema de Color")
        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        currentTheme := Config.GetTheme()
        themeNames := Theme.GetPresetNames()
        themeInitial := 1
        for i, name in themeNames {
            if (name = currentTheme) {
                themeInitial := i
                break
            }
        }

        this.SettingsTheme := this.GuiObj.Add("DropDownList",
            "xm y+5 w300 Choose" . themeInitial, themeNames)
        this.SettingsTheme.OnEvent("Change", (*) => this._PreviewTheme())

        applyThemeBtn := this.GuiObj.Add("Button", "x+10 yp-3 w100 h23", "Aplicar")
        applyThemeBtn.OnEvent("Click", (*) => this._ApplyTheme())

        ; ---- Theme Preview ----
        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+15 w200", "Vista Previa")
        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        previewW := 400
        previewH := 100
        this.ThemePreview := this.GuiObj.Add("Text",
            "xm y+5 w" . previewW . " h" . previewH .
            " Background0x" . Format("{:06X}", Theme.ToBGR(Theme.BG())), "")

        ; ---- Color Customization ----
        this.GuiObj.SetFont("s10 bold c0x" . Format("{:06X}", accColor), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+20 w300", "Colores Personalizados")
        this.GuiObj.SetFont("s9 c0x" . Format("{:06X}", txtColor), "Segoe UI")

        colorDefs := [
            ["background",  "Fondo principal"],
            ["foreground",  "Texto general"],
            ["accent",      "Color de acento"],
            ["highlight",   "Resaltado"],
            ["border",      "Bordes"],
            ["surface",     "Superficies"],
            ["overlay",     "Fondo overlay"],
            ["text",        "Texto principal"],
            ["textDim",     "Texto secundario"],
            ["textBright",  "Texto brillante"]
        ]

        yPos := 0
        xPos := 0
        this.ColorEdits := Map()

        for i, def in colorDefs {
            key := def[1]
            label := def[2]
            col := i <= 5 ? 0 : 1
            if (col = 0) {
                xPos := 10
                yPos += i = 1 ? 5 : 5
            } else if (i = 6) {
                xPos := 420
                yPos := 5
            }

            this.GuiObj.Add("Text", "xm w110 y+5", label . ":")
            edit := this.GuiObj.Add("Edit",
                "x+5 yp-3 w80 Background0x" . Format("{:06X}", surfColor) .
                " c0x" . Format("{:06X}", txtColor) . " Limit6")
            edit.Value := Config.Get("colors." . key, "FFFFFF")
            this.ColorEdits[key] := edit

            preview := this.GuiObj.Add("Text",
                "x+5 yp w24 h20 Background0x" .
                Format("{:06X}", Theme.ToBGR(Config.Get("colors." . key, "FFFFFF"))))
            this.ColorEdits[key . "_preview"] := preview
        }

        ; Apply colors button
        applyColorsBtn := this.GuiObj.Add("Button",
            "xm y+10 w150 h30 Background0x" . Format("{:06X}", Theme.ToBGR(Theme.SURF())) .
            " c0x" . Format("{:06X}", accColor), "Aplicar Colores")
        applyColorsBtn.OnEvent("Click", (*) => this._ApplyColors())

        resetColorsBtn := this.GuiObj.Add("Button",
            "x+10 yp w150 h30 Background0x" . Format("{:06X}", Theme.ToBGR(Theme.SURF())) .
            " c0x" . Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())), "Restaurar Tema")
        resetColorsBtn.OnEvent("Click", (*) => this._ResetColors())
    }

    ; ==========================================================
    ; Tab 1: ListView Operations
    ; ==========================================================

    static _PopulateListView() {
        this.ShortcutLV.Delete()
        shortcuts := Database.GetAll()

        query := this.SearchEdit.Value
        if (query != "") {
            shortcuts := Database.Search(query)
        }

        for shortcut in shortcuts {
            id := shortcut.Has("id") ? shortcut["id"] : ""
            prog := shortcut.Has("program") ? shortcut["program"] : ""
            proc := shortcut.Has("process") ? shortcut["process"] : ""
            cat := shortcut.Has("category") ? shortcut["category"] : ""
            desc := shortcut.Has("description") ? shortcut["description"] : ""
            trig := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
            targ := shortcut.Has("targetKeys") ? shortcut["targetKeys"] : ""
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"

            this.ShortcutLV.Add(, id, prog, proc, cat, desc, trig, targ, mode)
        }

        this.ShortcutLV.ModifyCol(1, 0)
    }

    static _OnSearchChange() {
        this._PopulateListView()
    }

    static _OnNewShortcut() {
        this._ClearEditor()
        this.TabCtrl.Choose(2)
    }

    static _OnEditShortcut() {
        row := this.ShortcutLV.GetNext()
        if (row = 0) {
            MsgBox("Selecciona un atajo para editar.", "Key Atlas", "Iconi")
            return
        }

        id := this.ShortcutLV.GetText(row, 1)
        shortcut := Database.GetById(id)
        if (shortcut = unset)
            return

        this.EdId.Value := id
        this.EdProgram.Value := shortcut.Has("program") ? shortcut["program"] : ""
        this.EdProcess.Value := shortcut.Has("process") ? shortcut["process"] : ""
        this.EdCategory.Value := shortcut.Has("category") ? shortcut["category"] : ""
        this.EdDescription.Value := shortcut.Has("description") ? shortcut["description"] : ""
        this.EdTrigger.Value := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
        this.EdTarget.Value := shortcut.Has("targetKeys") ? shortcut["targetKeys"] : ""
        this.CbMode.Choose(shortcut.Has("mode") && shortcut["mode"] = "cheatsheet" ? 2 : 1)

        this.TabCtrl.Choose(2)
    }

    static _OnDoubleClick() {
        this._OnEditShortcut()
    }

    static _OnDeleteShortcut() {
        row := this.ShortcutLV.GetNext()
        if (row = 0) {
            MsgBox("Selecciona un atajo para eliminar.", "Key Atlas", "Iconi")
            return
        }

        id := this.ShortcutLV.GetText(row, 1)
        desc := this.ShortcutLV.GetText(row, 5)

        result := MsgBox("Eliminar atajo '" desc "'?", "Key Atlas - Confirmar", "YesNo Icon?")
        if (result = "Yes") {
            Database.Delete(id)
            this._PopulateListView()
        }
    }

    static _OnExport() {
        savePath := FileSelect("S16", A_Desktop . "\keyatlas_export.json",
            "Exportar atajos", "JSON (*.json)")
        if (savePath = "")
            return
        try {
            Json.Save(savePath, Database.ExportAll(), 2)
            MsgBox("Atajos exportados correctamente.", "Key Atlas")
        } catch as err {
            MsgBox("Error al exportar: " . err.Message, "Key Atlas", "IconX")
        }
    }

    ; ==========================================================
    ; Tab 2: Editor Operations
    ; ==========================================================

    static _SaveShortcut() {
        shortcutData := Map()
        shortcutData["program"] := this.EdProgram.Value
        shortcutData["process"] := this.EdProcess.Value
        shortcutData["category"] := this.EdCategory.Value
        shortcutData["description"] := this.EdDescription.Value
        shortcutData["triggerKeys"] := this.EdTrigger.Value
        shortcutData["targetKeys"] := this.EdTarget.Value

        modeIdx := this.CbMode.Value - 1
        shortcutData["mode"] := modeIdx = 0 ? "remap" : "cheatsheet"

        if (shortcutData["description"] = "") {
            MsgBox("La descripcion es obligatoria.", "Key Atlas", "Icon!")
            return
        }

        if (shortcutData["triggerKeys"] = "") {
            MsgBox("Las teclas trigger son obligatorias.", "Key Atlas", "Icon!")
            return
        }

        existingId := this.EdId.Value
        if (existingId != "") {
            Database.Update(existingId, shortcutData)
        } else {
            shortcutData["id"] := ""
            Database.Add(shortcutData)
        }

        this._ClearEditor()
        this.TabCtrl.Choose(1)
        this._PopulateListView()
    }

    static _ClearEditor() {
        this.EdId.Value := ""
        this.EdProgram.Value := ""
        this.EdProcess.Value := ""
        this.EdCategory.Value := ""
        this.EdDescription.Value := ""
        this.EdTrigger.Value := ""
        this.EdTarget.Value := ""
        try this.CbMode.Choose(1)
    }

    static _DetectActiveWindow() {
        this.EdProgram.Value := WinGetTitle("A")
        this.EdProcess.Value := WinGetProcessName("A")
    }

    ; ==========================================================
    ; Tab 3: Settings Operations
    ; ==========================================================

    static _ApplyTrigger() {
        newTrigger := this.SettingsTrigger.Value
        if (newTrigger = "") {
            MsgBox("Presiona una combinacion de teclas valida.", "Key Atlas", "Icon!")
            return
        }
        Config.SetTriggerHotkey(newTrigger)
        Config.Save()
        HotkeyManager.UpdateTrigger()
        MsgBox("Hotkey '" HotkeyManager.FormatForDisplay(newTrigger) . "' activado.",
            "Key Atlas")
    }

    static _ApplyMode() {
        modeIdx := this.SettingsMode.Value - 1
        newMode := modeIdx = 0 ? "cheatsheet" : "remap"
        HotkeyManager.SwitchMode(newMode)
        MsgBox("Modo cambiado a: " . newMode, "Key Atlas")
    }

    static _ApplyTheme() {
        themeName := this.SettingsTheme.Text
        Theme.Apply(themeName)
        MsgBox("Tema '" . themeName . "' aplicado. Reinicia la ventana para ver los cambios.",
            "Key Atlas")
    }

    static _PreviewTheme() {
        themeName := this.SettingsTheme.Text
        preset := Theme.GetPreset(themeName)
        if (preset.Count > 0) {
            this.ThemePreview.Opt("Background0x" .
                Format("{:06X}", Theme.ToBGR(preset["background"])))
            this.ThemePreview.Redraw()
        }
    }

    static _ApplyColors() {
        for key, edit in this.ColorEdits {
            if (InStr(key, "_preview"))
                continue
            colorVal := edit.Value
            if (RegExMatch(colorVal, "i)^[0-9A-Fa-f]{6}$")) {
                Config.Set("colors." . key, StrUpper(colorVal))
            }
        }
        Config.Save()
        MsgBox("Colores personalizados guardados. Reinicia la ventana para ver los cambios.",
            "Key Atlas")
    }

    static _ResetColors() {
        themeName := Config.GetTheme()
        Theme.Apply(themeName)
        this._RefreshColorEdits()
        MsgBox("Colores restaurados al tema '" . themeName . "'.", "Key Atlas")
    }

    static _RefreshColorEdits() {
        for key, edit in this.ColorEdits {
            if (InStr(key, "_preview"))
                continue
            edit.Value := Config.Get("colors." . key, "FFFFFF")
            previewKey := key . "_preview"
            if (this.ColorEdits.Has(previewKey)) {
                this.ColorEdits[previewKey].Opt("Background0x" .
                    Format("{:06X}", Theme.ToBGR(Config.Get("colors." . key, "FFFFFF"))))
                this.ColorEdits[previewKey].Redraw()
            }
        }
    }
}
