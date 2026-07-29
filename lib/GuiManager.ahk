; ============================================================
; GuiManager.ahk - Main Configuration Window
; Redesigned: TreeView hierarchy, separate dialogs, auto-assign
; ============================================================

class GuiManager {
    static GuiObj := ""
    static IsVisible := false
    static TreeView := ""
    static ShortcutLV := ""
    static ProgramDDL := ""
    static SearchEdit := ""
    static EditingId := ""

    static Show() {
        if (this.IsVisible) {
            this.GuiObj.Show()
            WinActivate(this.GuiObj.Hwnd)
            return
        }
        this._CreateGui()
        this._PopulateTreeView()
        this.GuiObj.Show("w900 h580 Center")
        this.IsVisible := true
    }

    static Hide() {
        if (this.IsVisible)
            this.GuiObj.Hide()
    }

    static Close() {
        this.IsVisible := false
        try this.GuiObj.Destroy()
        this.GuiObj := ""
    }

    ; ==========================================================
    ; Main GUI Creation
    ; ==========================================================

    static _CreateGui() {
        bg := Theme.ToBGR(Theme.BG())
        txt := Theme.ToBGR(Theme.TXT())

        this.GuiObj := Gui("+Resize +MinSize720x420", "Key Atlas - Configuracion")
        this.GuiObj.BackColor := bg
        this.GuiObj.MarginX := 8
        this.GuiObj.MarginY := 8
        this.GuiObj.OnEvent("Close", (*) => this.Close())
        this.GuiObj.OnEvent("Escape", (*) => this.Close())

        ; ---- Toolbar ----
        this._CreateToolbar()

        ; ---- Main content area ----
        ; Left: TreeView (categories)
        ; Right: ListView (shortcuts)

        this._CreateTreePanel()
        this._CreateShortcutPanel()
    }

    static _CreateToolbar() {
        txt := Theme.ToBGR(Theme.TXT())
        acc := Theme.ToBGR(Theme.ACC())
        surf := Theme.ToBGR(Theme.SURF())
        dim := Theme.ToBGR(Theme.TXTDIM())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", txt), "Segoe UI")

        this.GuiObj.Add("Text", "xm y+2 w70", "Programa:")
        this.ProgramDDL := this.GuiObj.Add("DropDownList",
            "x+2 yp-2 w200 Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt))
        this.ProgramDDL.OnEvent("Change", (*) => this._OnProgramChange())

        this.GuiObj.Add("Text", "x+15 yp+2 w50", "Buscar:")
        this.SearchEdit := this.GuiObj.Add("Edit",
            "x+2 yp-2 w200 Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt))
        this.SearchEdit.OnEvent("Change", (*) => this._OnSearch())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", acc), "Segoe UI")
        autoBtn := this.GuiObj.Add("Button",
            "x+15 yp-2 w130 Background0x" Format("{:06X}", surf),
            "Asignar Teclas")
        autoBtn.OnEvent("Click", (*) => this._ShowAutoAssign())

        configBtn := this.GuiObj.Add("Button",
            "x+5 yp w80 Background0x" Format("{:06X}", surf),
            "Ajustes")
        configBtn.OnEvent("Click", (*) => this._ShowSettingsDialog())

        ; Separator line
        this.GuiObj.Add("Text",
            "xm y+8 w880 h1 Background0x" Format("{:06X}", Theme.ToBGR(Theme.BDR())))
    }

    static _CreateTreePanel() {
        surf := Theme.ToBGR(Theme.SURF())
        txt := Theme.ToBGR(Theme.TXT())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", txt), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+8 w190 Section", "Categorias por Programa")
        this.TreeView := this.GuiObj.Add("TreeView",
            "xs y+2 w190 h400 Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt))
        this.TreeView.OnEvent("ItemSelect", (*) => this._OnTreeSelect())
    }

    static _CreateShortcutPanel() {
        txt := Theme.ToBGR(Theme.TXT())
        surf := Theme.ToBGR(Theme.SURF())
        acc := Theme.ToBGR(Theme.ACC())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", txt), "Segoe UI")

        this.GuiObj.Add("Text", "xs+210 ys w400 Section", "Atajos")
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xs y+2 w650 h340 Grid -Multi Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt),
            ["Trigger", "Descripcion", "Target", "Proceso", "Categoria", "Modo"])
        this.ShortcutLV.OnEvent("DoubleClick", (*) => this._EditSelected())

        this.ShortcutLV.ModifyCol(1, 120)
        this.ShortcutLV.ModifyCol(2, 220)
        this.ShortcutLV.ModifyCol(3, 100)
        this.ShortcutLV.ModifyCol(4, 100)
        this.ShortcutLV.ModifyCol(5, 80)
        this.ShortcutLV.ModifyCol(6, 50)

        ; Action buttons
        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", acc), "Segoe UI")
        btnOpts := "w120 h28 Background0x" Format("{:06X}", surf)

        addBtn := this.GuiObj.Add("Button", "xs y+5 " btnOpts, "Nuevo Atajo")
        addBtn.OnEvent("Click", (*) => this._ShowEditor())

        editBtn := this.GuiObj.Add("Button", "x+5 yp " btnOpts, "Editar")
        editBtn.OnEvent("Click", (*) => this._EditSelected())

        delBtn := this.GuiObj.Add("Button",
            "x+5 yp " btnOpts " c0x" Format("{:06X}", Theme.ToBGR(Theme.GetColor("error"))),
            "Eliminar")
        delBtn.OnEvent("Click", (*) => this._DeleteSelected())

        ; Quick info at bottom
        this.GuiObj.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())), "Segoe UI")
        this.GuiObj.Add("Text", "xs y+5 w650",
            "Doble click para editar | " .
            Database.GetAll().Length " atajos en total")
    }

    ; ==========================================================
    ; TreeView: Programs > Categories
    ; ==========================================================

    static _PopulateTreeView() {
        this.TreeView.Delete()

        allProc := Map()
        for shortcut in Database.GetAll() {
            prog := shortcut.Has("program") ? shortcut["program"] : "Sin programa"
            cat := shortcut.Has("category") ? shortcut["category"] : "General"
            if (cat = "")
                cat := "General"

            if (!allProc.Has(prog))
                allProc[prog] := Map()
            if (!allProc[prog].Has(cat))
                allProc[prog][cat] := true
        }

        ; Sort programs
        progNames := Array()
        for prog in allProc
            progNames.Push(prog)
        Database._SortArray(&progNames)

        ; Update program dropdown
        ddlItems := Array()
        ddlItems.Push("--- Todos los programas ---")
        for prog in progNames {
            ddlItems.Push(prog)
            ; Add program node
            progID := this.TreeView.Add(prog, 0, "Expand")
            ; Sort categories and add them
            catNames := Array()
            for cat in allProc[prog]
                catNames.Push(cat)
            Database._SortArray(&catNames)
            for cat in catNames
                this.TreeView.Add(cat, progID)
        }

        this.ProgramDDL.Delete()
        this.ProgramDDL.Add(ddlItems)
        this.ProgramDDL.Choose(1)
    }

    static _OnProgramChange() {
        sel := this.ProgramDDL.Text
        if (sel = "--- Todos los programas ---") {
            this._RefreshListView(Database.GetAll())
            this._SelectFirstTreeItem()
            return
        }

        all := Database.GetAll()
        filtered := Array()
        for sc in all {
            prog := sc.Has("program") ? sc["program"] : ""
            if (prog = sel)
                filtered.Push(sc)
        }
        this._RefreshListView(filtered)

        ; Select first tree item matching this program
        this._SelectFirstTreeItem()
    }

    static _OnTreeSelect() {
        selItem := this.TreeView.GetSelection()
        if (!selItem)
            return

        parentID := this.TreeView.GetParent(selItem)
        selText := this.TreeView.GetText(selItem)

        if (parentID = 0) {
            ; Program node selected
            try this.ProgramDDL.Choose(selText)
            this._RefreshListView(this._GetShortcutsByProgram(selText))
        } else {
            ; Category node selected
            progName := this.TreeView.GetText(parentID)
            try this.ProgramDDL.Choose(progName)
            this._RefreshListView(this._GetShortcutsByCategory(progName, selText))
        }
    }

    static _OnSearch() {
        query := this.SearchEdit.Value
        if (query = "") {
            this._OnProgramChange()
            return
        }
        results := Database.Search(query)
        this._RefreshListView(results)
    }

    static _RefreshListView(shortcuts) {
        this.ShortcutLV.Delete()
        for sc in shortcuts {
            trig := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
            desc := sc.Has("description") ? sc["description"] : ""
            targ := sc.Has("targetKeys") ? sc["targetKeys"] : ""
            proc := sc.Has("process") ? sc["process"] : ""
            cat  := sc.Has("category") ? sc["category"] : ""
            mode := sc.Has("mode") ? sc["mode"] : "remap"
            this.ShortcutLV.Add(, trig, desc, targ, proc, cat, mode)
        }
        this.ShortcutLV.ModifyCol(1, 120)
        this.ShortcutLV.ModifyCol(2, 220)
    }

    static _GetShortcutsByProgram(progName) {
        results := Array()
        for sc in Database.GetAll() {
            p := sc.Has("program") ? sc["program"] : ""
            if (p = progName)
                results.Push(sc)
        }
        return results
    }

    static _GetShortcutsByCategory(progName, catName) {
        results := Array()
        for sc in Database.GetAll() {
            p := sc.Has("program") ? sc["program"] : ""
            c := sc.Has("category") ? sc["category"] : "General"
            if (c = "")
                c := "General"
            if (p = progName && c = catName)
                results.Push(sc)
        }
        return results
    }

    static _SelectFirstTreeItem() {
        firstItem := this.TreeView.GetNext()
        if (firstItem)
            this.TreeView.Modify(firstItem, "Select VisFirst")
    }

    ; ==========================================================
    ; Shortcut Editor Dialog
    ; ==========================================================

    static _ShowEditor(shortcutData := "") {
        isEditing := shortcutData != "" && shortcutData is Map

        editGui := Gui("+Owner" this.GuiObj.Hwnd,
            isEditing ? "Key Atlas - Editar Atajo" : "Key Atlas - Nuevo Atajo")
        editGui.BackColor := Theme.ToBGR(Theme.BG())
        editGui.SetFont("s9", "Segoe UI")

        txt := Theme.ToBGR(Theme.TXT())
        surf := Theme.ToBGR(Theme.SURF())
        acc := Theme.ToBGR(Theme.ACC())
        bdr := Theme.ToBGR(Theme.BDR())

        txtColor := Format("{:06X}", txt)
        surfColor := Format("{:06X}", surf)
        accColor := Format("{:06X}", acc)
        inputStyle := "w350 Background0x" surfColor " c0x" txtColor

        editGui.SetFont("s9 c0x" txtColor)

        ; Program
        editGui.Add("Text", "xm y+10 w100", "Programa:")
        edProgram := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edProgram.Value := isEditing && shortcutData.Has("program") ? shortcutData["program"] : ""

        ; Process
        editGui.Add("Text", "xm y+5 w100", "Proceso (.exe):")
        edProcess := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edProcess.Value := isEditing && shortcutData.Has("process") ? shortcutData["process"] : ""

        detectBtn := editGui.Add("Button", "x+10 yp w160 h23", "Detectar Ventana Activa")
        detectBtn.OnEvent("Click", (*) => DetectWindow(edProgram, edProcess))

        DetectWindow(edProg, edProc) {
            edProg.Value := WinGetTitle("A")
            edProc.Value := WinGetProcessName("A")
        }

        ; Category
        editGui.Add("Text", "xm y+5 w100", "Categoria:")
        edCategory := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edCategory.Value := isEditing && shortcutData.Has("category") ? shortcutData["category"] : ""

        ; Description
        editGui.Add("Text", "xm y+5 w100", "Descripcion:")
        edDesc := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edDesc.Value := isEditing && shortcutData.Has("description") ? shortcutData["description"] : ""

        ; Trigger Keys
        editGui.Add("Text", "xm y+5 w100", "Teclas Trigger:")
        edTrigger := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTrigger.Value := isEditing && shortcutData.Has("triggerKeys") ? shortcutData["triggerKeys"] : ""
        editGui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        editGui.Add("Text", "x+10 y+1 w350",
            "Combinacional: Ctrl+S | Secuencial: g d | AHK: ^s +!f")

        ; Target Keys
        editGui.SetFont("s9 c0x" txtColor)
        editGui.Add("Text", "xm y+5 w100", "Teclas Target:")
        edTarget := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTarget.Value := isEditing && shortcutData.Has("targetKeys") ? shortcutData["targetKeys"] : ""

        ; Mode
        editGui.Add("Text", "xm y+5 w100", "Modo:")
        cbMode := editGui.Add("DropDownList", "x+10 yp-3 w200 Choose1",
            ["remap (ejecuta atajo)", "cheatsheet (solo mostrar)"])
        if (isEditing && shortcutData.Has("mode") && shortcutData["mode"] = "cheatsheet")
            cbMode.Choose(2)

        ; Action buttons
        editGui.Add("Text", "xm y+15 w100", "")
        editGui.SetFont("s10 bold c0x" accColor)

        saveBtn := editGui.Add("Button",
            "x+10 yp-3 w150 h32 Background0x" surfColor, "Guardar")
        saveBtn.OnEvent("Click", (*) => SaveShortcut(editGui))

        cancelBtn := editGui.Add("Button",
            "x+10 yp w150 h32 Background0x" surfColor .
            " c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())),
            "Cancelar")
        cancelBtn.OnEvent("Click", (*) => editGui.Destroy())

        editGui.OnEvent("Escape", (*) => editGui.Destroy())

        SaveShortcut(gui) {
            data := Map()
            data["program"] := edProgram.Value
            data["process"] := edProcess.Value
            data["category"] := edCategory.Value
            data["description"] := edDesc.Value
            data["triggerKeys"] := edTrigger.Value
            data["targetKeys"] := edTarget.Value
            data["mode"] := cbMode.Value = 2 ? "cheatsheet" : "remap"

            if (data["description"] = "") {
                MsgBox("La descripcion es obligatoria.", "Key Atlas", "Icon!")
                return
            }
            if (data["triggerKeys"] = "") {
                MsgBox("Las teclas trigger son obligatorias.", "Key Atlas", "Icon!")
                return
            }

            if (isEditing && shortcutData.Has("id")) {
                Database.Update(shortcutData["id"], data)
            } else {
                data["id"] := ""
                Database.Add(data)
            }

            gui.Destroy()
            this._RefreshView()
        }

        editGui.Show("AutoSize Center")
    }

    static _EditSelected() {
        row := this.ShortcutLV.GetNext()
        if (row = 0) {
            MsgBox("Selecciona un atajo para editar.", "Key Atlas", "Iconi")
            return
        }

        ; Find the shortcut by matching trigger and description
        trig := this.ShortcutLV.GetText(row, 1)
        desc := this.ShortcutLV.GetText(row, 2)
        all := Database.GetAll()
        for sc in all {
            t := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
            d := sc.Has("description") ? sc["description"] : ""
            if (t = trig && d = desc) {
                this._ShowEditor(sc)
                return
            }
        }
    }

    static _DeleteSelected() {
        row := this.ShortcutLV.GetNext()
        if (row = 0) {
            MsgBox("Selecciona un atajo para eliminar.", "Key Atlas", "Iconi")
            return
        }

        trig := this.ShortcutLV.GetText(row, 1)
        desc := this.ShortcutLV.GetText(row, 2)
        all := Database.GetAll()

        for sc in all {
            t := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
            d := sc.Has("description") ? sc["description"] : ""
            if (t = trig && d = desc) {
                id := sc.Has("id") ? sc["id"] : ""
                result := MsgBox("Eliminar '" desc "'?", "Key Atlas - Confirmar", "YesNo Icon?")
                if (result = "Yes") {
                    Database.Delete(id)
                    this._RefreshView()
                }
                return
            }
        }
    }

    static _RefreshView() {
        this._PopulateTreeView()
        this._OnProgramChange()
    }

    ; ==========================================================
    ; Settings Dialog
    ; ==========================================================

    static _ShowSettingsDialog() {
        setGui := Gui("+Owner" this.GuiObj.Hwnd, "Key Atlas - Ajustes")
        setGui.BackColor := Theme.ToBGR(Theme.BG())
        setGui.SetFont("s9", "Segoe UI")

        txt := Theme.ToBGR(Theme.TXT())
        surf := Theme.ToBGR(Theme.SURF())
        acc := Theme.ToBGR(Theme.ACC())
        surfHex := Format("{:06X}", surf)
        txtHex := Format("{:06X}", txt)
        accHex := Format("{:06X}", acc)
        inputStyle := "w280 Background0x" surfHex " c0x" txtHex

        setGui.SetFont("s10 bold c0x" accHex)
        setGui.Add("Text", "xm y+10 w400", "Hotkey de Activacion")
        setGui.SetFont("s9 c0x" txtHex)
        setGui.Add("Text", "xm y+5 w120", "Combinacion:")
        inputStyleNoBg := "w280 c0x" txtHex
        triggerCtrl := setGui.Add("Hotkey", "x+10 yp-3 " inputStyleNoBg)
        triggerCtrl.Value := HotkeyManager.GetCurrentTrigger()

        applyTriggerBtn := setGui.Add("Button", "x+10 yp w100 h23", "Aplicar")
        applyTriggerBtn.OnEvent("Click", (*) => ApplyTrigger(triggerCtrl))

        ; Default mode
        setGui.SetFont("s10 bold c0x" accHex)
        setGui.Add("Text", "xm y+15 w400", "Modo por Defecto")
        setGui.SetFont("s9 c0x" txtHex)
        currentMode := HotkeyManager.GetCurrentMode()
        modeInitial := currentMode = "cheatsheet" ? 1 : 2
        modeDDL := setGui.Add("DropDownList", "xm y+5 w280 Choose" modeInitial,
            ["Cheatsheet (ver atajos)", "Remap (ejecutar atajos)"])

        applyModeBtn := setGui.Add("Button", "x+10 yp w100 h23", "Aplicar")
        applyModeBtn.OnEvent("Click", (*) => ApplyMode(modeDDL))

        ; Theme
        setGui.SetFont("s10 bold c0x" accHex)
        setGui.Add("Text", "xm y+15 w400", "Tema de Color")
        setGui.SetFont("s9 c0x" txtHex)
        themeNames := Theme.GetPresetNames()
        currentTheme := Config.GetTheme()
        themeIdx := 1
        for i, name in themeNames {
            if (name = currentTheme) {
                themeIdx := i
                break
            }
        }
        themeDDL := setGui.Add("DropDownList", "xm y+5 w280 Choose" themeIdx, themeNames)

        applyThemeBtn := setGui.Add("Button", "x+10 yp w100 h23", "Aplicar")
        applyThemeBtn.OnEvent("Click", (*) => ApplyTheme(setGui, themeDDL))

        ; Preview
        setGui.Add("Text", "xm y+15 h40 w420 Background0x" Format("{:06X}", Theme.ToBGR(Theme.BG())))

        ; Close button
        setGui.SetFont("s9 c0x" accHex)
        closeBtn := setGui.Add("Button", "xm y+15 w120 h30 Background0x" surfHex, "Cerrar")
        closeBtn.OnEvent("Click", (*) => setGui.Destroy())
        setGui.OnEvent("Escape", (*) => setGui.Destroy())

        ApplyTrigger(ctrl) {
            val := ctrl.Value
            if (val = "") {
                MsgBox("Presiona una combinacion valida.", "Key Atlas", "Icon!")
                return
            }
            Config.SetTriggerHotkey(val)
            Config.Save()
            HotkeyManager.UpdateTrigger()
            MsgBox("Hotkey actualizado.", "Key Atlas")
        }

        ApplyMode(ddl) {
            newMode := ddl.Value = 1 ? "cheatsheet" : "remap"
            HotkeyManager.SwitchMode(newMode)
            MsgBox("Modo: " newMode, "Key Atlas")
        }

        ApplyTheme(parentGui, ddl) {
            name := ddl.Text
            Theme.Apply(name)
            MsgBox("Tema '" name "' aplicado. La ventana se reiniciara.", "Key Atlas")
            parentGui.Destroy()
            this.Close()
            this.Show()
        }

        setGui.Show("AutoSize Center")
    }

    ; ==========================================================
    ; Auto-Assign Keys Dialog
    ; ==========================================================

    static _ShowAutoAssign() {
        agui := Gui("+Owner" this.GuiObj.Hwnd, "Key Atlas - Asignacion Automatica")
        agui.BackColor := Theme.ToBGR(Theme.BG())
        agui.SetFont("s9", "Segoe UI")

        txt := Theme.ToBGR(Theme.TXT())
        surf := Theme.ToBGR(Theme.SURF())
        acc := Theme.ToBGR(Theme.ACC())
        surfHex := Format("{:06X}", surf)
        txtHex := Format("{:06X}", txt)
        accHex := Format("{:06X}", acc)
        inputStyle := "w320 Background0x" surfHex " c0x" txtHex

        agui.SetFont("s10 bold c0x" accHex)
        agui.Add("Text", "xm y+10 w500",
            "Generar atajos automaticamente a partir de un conjunto de teclas")

        ; Program selector
        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+10 w100", "Programa:")
        progNames := Database.GetPrograms()
        progItems := Array()
        progItems.Push("--- Seleccionar ---")
        for p in progNames
            progItems.Push(p)
        aaProgDDL := agui.Add("DropDownList", "x+10 yp-3 w320 Choose1", progItems)

        agui.Add("Text", "xm y+5 w100", "Categoria:")
        catNames := Database.GetCategories()
        catItems := Array()
        catItems.Push("--- Todas ---")
        for c in catNames
            catItems.Push(c)
        aaCatDDL := agui.Add("DropDownList", "x+10 yp-3 w320 Choose1", catItems)

        ; Key pool
        agui.Add("Text", "xm y+5 w100", "Teclas disponibles:")
        aaKeyPool := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z")
        agui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        agui.Add("Text", "x+10 y+1 w320",
            "Lista de teclas separadas por coma. Se asignaran en orden.")

        ; Prefix
        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+5 w100", "Prefijo:")
        aaPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()))

        ; Category prefix mapping
        agui.SetFont("s10 bold c0x" accHex)
        agui.Add("Text", "xm y+10 w500", "Prefijos por Categoria (opcional)")
        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+2 w100", "Formato:")
        aaCatPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "f=Buscar, e=Editar, n=Navegar, v=Ver")
        agui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        agui.Add("Text", "x+10 y+1 w320",
            "letra=nombre_categoria. Se usara como prefijo en las teclas trigger.")

        ; Generate button
        agui.Add("Text", "xm y+15 w100", "")
        agui.SetFont("s10 bold c0x" accHex)
        genBtn := agui.Add("Button", "x+10 yp-3 w180 h32 Background0x" surfHex,
            "Generar Asignaciones")
        genBtn.OnEvent("Click", (*) => GenerateAssignments(agui))

        cancelBtn := agui.Add("Button",
            "x+10 yp w120 h32 Background0x" surfHex .
            " c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())),
            "Cancelar")
        cancelBtn.OnEvent("Click", (*) => agui.Destroy())
        agui.OnEvent("Escape", (*) => agui.Destroy())

        GenerateAssignments(gui) {
            prog := aaProgDDL.Text
            if (prog = "--- Seleccionar ---") {
                MsgBox("Selecciona un programa.", "Key Atlas", "Icon!")
                return
            }

            catFilter := aaCatDDL.Text
            if (catFilter = "--- Todas ---")
                catFilter := ""

            ; Parse key pool
            poolRaw := aaKeyPool.Value
            pool := Array()
            for part in StrSplit(poolRaw, ",") {
                key := Trim(part)
                if (key != "")
                    pool.Push(key)
            }

            if (pool.Length = 0) {
                MsgBox("Define al menos una tecla disponible.", "Key Atlas", "Icon!")
                return
            }

            ; Parse category prefixes
            catPrefixMap := Map()
            cpRaw := aaCatPrefix.Value
            for part in StrSplit(cpRaw, ",") {
                part := Trim(part)
                parts := StrSplit(part, "=")
                if (parts.Length = 2)
                    catPrefixMap[Trim(parts[1])] := Trim(parts[2])
            }

            ; Get shortcuts for this program/category
            candidates := Array()
            for sc in Database.GetAll() {
                p := sc.Has("program") ? sc["program"] : ""
                if (p != prog)
                    continue
                if (catFilter != "" && sc.Has("category") && sc["category"] != catFilter)
                    continue
                candidates.Push(sc)
            }

            if (candidates.Length = 0) {
                MsgBox("No hay atajos para '" prog "' en la base de datos.", "Key Atlas", "Icon!")
                return
            }

            ; Assign keys
            poolIdx := 1
            assigned := 0
            for sc in candidates {
                if (poolIdx > pool.Length)
                    break

                key := pool[poolIdx]
                cat := sc.Has("category") ? sc["category"] : "General"

                ; Build trigger: optional category prefix + key
                catLetter := ""
                for letter, catName in catPrefixMap {
                    if (catName = cat) {
                        catLetter := letter
                        break
                    }
                }

                trigger := catLetter . key
                sc["triggerKeys"] := trigger
                Database.Update(sc["id"], sc)
                poolIdx++
                assigned++
            }

            Database.Save()
            gui.Destroy()
            this._RefreshView()
            MsgBox(assigned " atajos asignados para '" prog "'`n" .
                "Revisa los triggers generados en la lista.", "Key Atlas")
        }

        agui.Show("AutoSize Center")
    }
}
