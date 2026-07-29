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

        this.GuiObj := Gui("+Resize +MinSize720x420", I18n.t("gui.title"))
        this.GuiObj.BackColor := bg
        this.GuiObj.MarginX := 8
        this.GuiObj.MarginY := 8
        this.GuiObj.OnEvent("Close", (*) => this.Close())
        this.GuiObj.OnEvent("Escape", (*) => this.Close())

        this._CreateToolbar()
        this._CreateTreePanel()
        this._CreateShortcutPanel()
    }

    static _CreateToolbar() {
        txt := Theme.ToBGR(Theme.TXT())
        acc := Theme.ToBGR(Theme.ACC())
        surf := Theme.ToBGR(Theme.SURF())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", txt), "Segoe UI")

        this.GuiObj.Add("Text", "xm y+2 w70", I18n.t("toolbar.program"))
        this.ProgramDDL := this.GuiObj.Add("DropDownList",
            "x+2 yp-2 w200 Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt))
        this.ProgramDDL.OnEvent("Change", (*) => this._OnProgramChange())

        this.GuiObj.Add("Text", "x+15 yp+2 w50", I18n.t("toolbar.search"))
        this.SearchEdit := this.GuiObj.Add("Edit",
            "x+2 yp-2 w200 Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt))
        this.SearchEdit.OnEvent("Change", (*) => this._OnSearch())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", acc), "Segoe UI")
        autoBtn := this.GuiObj.Add("Button",
            "x+15 yp-2 w130 Background0x" Format("{:06X}", surf),
            I18n.t("toolbar.autoassign"))
        autoBtn.OnEvent("Click", (*) => this._ShowAutoAssign())

        configBtn := this.GuiObj.Add("Button",
            "x+5 yp w80 Background0x" Format("{:06X}", surf),
            I18n.t("toolbar.settings"))
        configBtn.OnEvent("Click", (*) => this._ShowSettingsDialog())

        this.GuiObj.Add("Text",
            "xm y+8 w880 h1 Background0x" Format("{:06X}", Theme.ToBGR(Theme.BDR())))
    }

    static _CreateTreePanel() {
        surf := Theme.ToBGR(Theme.SURF())
        txt := Theme.ToBGR(Theme.TXT())

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", txt), "Segoe UI")
        this.GuiObj.Add("Text", "xm y+8 w190 Section", I18n.t("tree.title"))
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

        this.GuiObj.Add("Text", "xs+210 ys w400 Section", I18n.t("list.title"))
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "xs y+2 w650 h340 Grid -Multi Background0x" Format("{:06X}", surf) .
            " c0x" Format("{:06X}", txt),
            [I18n.t("col.trigger"), I18n.t("col.desc"), I18n.t("col.target"),
             I18n.t("col.process"), I18n.t("col.category"), I18n.t("col.mode")])
        this.ShortcutLV.OnEvent("DoubleClick", (*) => this._EditSelected())

        this.ShortcutLV.ModifyCol(1, 120)
        this.ShortcutLV.ModifyCol(2, 220)
        this.ShortcutLV.ModifyCol(3, 100)
        this.ShortcutLV.ModifyCol(4, 100)
        this.ShortcutLV.ModifyCol(5, 80)
        this.ShortcutLV.ModifyCol(6, 50)

        this.GuiObj.SetFont("s9 c0x" Format("{:06X}", acc), "Segoe UI")
        btnOpts := "w120 h28 Background0x" Format("{:06X}", surf)

        addBtn := this.GuiObj.Add("Button", "xs y+5 " btnOpts, I18n.t("btn.new"))
        addBtn.OnEvent("Click", (*) => this._ShowEditor())

        editBtn := this.GuiObj.Add("Button", "x+5 yp " btnOpts, I18n.t("btn.edit"))
        editBtn.OnEvent("Click", (*) => this._EditSelected())

        delBtn := this.GuiObj.Add("Button",
            "x+5 yp " btnOpts " c0x" Format("{:06X}", Theme.ToBGR(Theme.GetColor("error"))),
            I18n.t("btn.delete"))
        delBtn.OnEvent("Click", (*) => this._DeleteSelected())

        this.GuiObj.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())), "Segoe UI")
        this.GuiObj.Add("Text", "xs y+5 w650",
            I18n.t("footer.dblclick") Database.GetAll().Length I18n.t("footer.total"))
    }

    ; ==========================================================
    ; TreeView: Programs > Categories
    ; ==========================================================

    static _PopulateTreeView() {
        this.TreeView.Delete()

        allProc := Map()
        for shortcut in Database.GetAll() {
            prog := shortcut.Has("program") ? shortcut["program"] : I18n.t("program.unnamed")
            cat := shortcut.Has("category") ? shortcut["category"] : I18n.t("category.general")
            if (cat = "")
                cat := I18n.t("category.general")

            if (!allProc.Has(prog))
                allProc[prog] := Map()
            if (!allProc[prog].Has(cat))
                allProc[prog][cat] := true
        }

        progNames := Array()
        for prog in allProc
            progNames.Push(prog)
        Database._SortArray(&progNames)

        ddlItems := Array()
        ddlItems.Push(I18n.t("program.all"))
        for prog in progNames {
            ddlItems.Push(prog)
            progID := this.TreeView.Add(prog, 0, "Expand")
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
        if (sel = I18n.t("program.all")) {
            this._RefreshListView(Database.GetAll())
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
    }

    static _OnTreeSelect() {
        selItem := this.TreeView.GetSelection()
        if (!selItem)
            return

        parentID := this.TreeView.GetParent(selItem)
        selText := this.TreeView.GetText(selItem)

        if (parentID = 0) {
            try this.ProgramDDL.Choose(selText)
            this._RefreshListView(this._GetShortcutsByProgram(selText))
        } else {
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
            c := sc.Has("category") ? sc["category"] : I18n.t("category.general")
            if (c = "")
                c := I18n.t("category.general")
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
            isEditing ? I18n.t("editor.title_edit") : I18n.t("editor.title_new"))
        editGui.BackColor := Theme.ToBGR(Theme.BG())
        editGui.SetFont("s9", "Segoe UI")

        txt := Theme.ToBGR(Theme.TXT())
        surf := Theme.ToBGR(Theme.SURF())
        acc := Theme.ToBGR(Theme.ACC())

        txtColor := Format("{:06X}", txt)
        surfColor := Format("{:06X}", surf)
        accColor := Format("{:06X}", acc)
        inputStyle := "w350 Background0x" surfColor " c0x" txtColor

        editGui.SetFont("s9 c0x" txtColor)

        editGui.Add("Text", "xm y+10 w100", I18n.t("editor.program"))
        edProgram := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edProgram.Value := isEditing && shortcutData.Has("program") ? shortcutData["program"] : ""

        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.process"))
        edProcess := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edProcess.Value := isEditing && shortcutData.Has("process") ? shortcutData["process"] : ""

        detectBtn := editGui.Add("Button", "x+10 yp w160 h23", I18n.t("editor.detect"))
        detectBtn.OnEvent("Click", (*) => DetectWindow(edProgram, edProcess))

        DetectWindow(edProg, edProc) {
            edProg.Value := WinGetTitle("A")
            edProc.Value := WinGetProcessName("A")
        }

        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.category"))
        edCategory := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edCategory.Value := isEditing && shortcutData.Has("category") ? shortcutData["category"] : ""

        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.desc"))
        edDesc := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edDesc.Value := isEditing && shortcutData.Has("description") ? shortcutData["description"] : ""

        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.trigger"))
        edTrigger := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTrigger.Value := isEditing && shortcutData.Has("triggerKeys") ? shortcutData["triggerKeys"] : ""
        editGui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        editGui.Add("Text", "x+10 y+1 w350", I18n.t("editor.hint"))

        editGui.SetFont("s9 c0x" txtColor)
        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.target"))
        edTarget := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTarget.Value := isEditing && shortcutData.Has("targetKeys") ? shortcutData["targetKeys"] : ""

        editGui.Add("Text", "xm y+5 w100", I18n.t("editor.mode"))
        cbMode := editGui.Add("DropDownList", "x+10 yp-3 w200 Choose1",
            [I18n.t("editor.mode_remap"), I18n.t("editor.mode_sheet")])
        if (isEditing && shortcutData.Has("mode") && shortcutData["mode"] = "cheatsheet")
            cbMode.Choose(2)

        editGui.Add("Text", "xm y+15 w100", "")
        editGui.SetFont("s10 bold c0x" accColor)

        saveBtn := editGui.Add("Button",
            "x+10 yp-3 w150 h32 Background0x" surfColor, I18n.t("editor.save"))
        saveBtn.OnEvent("Click", (*) => SaveShortcut(editGui))

        cancelBtn := editGui.Add("Button",
            "x+10 yp w150 h32 Background0x" surfColor .
            " c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())),
            I18n.t("editor.cancel"))
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
                MsgBox(I18n.t("msg.desc_required"), "Key Atlas", "Icon!")
                return
            }
            if (data["triggerKeys"] = "") {
                MsgBox(I18n.t("msg.trigger_required"), "Key Atlas", "Icon!")
                return
            }

            if (isEditing && shortcutData.Has("id"))
                Database.Update(shortcutData["id"], data)
            else {
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
            MsgBox(I18n.t("msg.select_edit"), "Key Atlas", "Iconi")
            return
        }

        trig := this.ShortcutLV.GetText(row, 1)
        desc := this.ShortcutLV.GetText(row, 2)
        for sc in Database.GetAll() {
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
            MsgBox(I18n.t("msg.select_delete"), "Key Atlas", "Iconi")
            return
        }

        trig := this.ShortcutLV.GetText(row, 1)
        desc := this.ShortcutLV.GetText(row, 2)
        for sc in Database.GetAll() {
            t := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
            d := sc.Has("description") ? sc["description"] : ""
            if (t = trig && d = desc) {
                id := sc.Has("id") ? sc["id"] : ""
                result := MsgBox(I18n.t("msg.confirm_delete") desc "'?",
                    "Key Atlas", "YesNo Icon?")
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
        setGui := Gui("+Owner" this.GuiObj.Hwnd, I18n.t("settings.title"))
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
        setGui.Add("Text", "xm y+10 w400", I18n.t("settings.hotkey"))
        setGui.SetFont("s9 c0x" txtHex)
        setGui.Add("Text", "xm y+5 w120", I18n.t("settings.combo"))
        triggerCtrl := setGui.Add("Hotkey", "x+10 yp-3 w280 c0x" txtHex)
        triggerCtrl.Value := HotkeyManager.GetCurrentTrigger()

        applyTriggerBtn := setGui.Add("Button", "x+10 yp w100 h23", I18n.t("settings.apply"))
        applyTriggerBtn.OnEvent("Click", (*) => ApplyTrigger(triggerCtrl))

        setGui.SetFont("s10 bold c0x" accHex)
        setGui.Add("Text", "xm y+15 w400", I18n.t("settings.default_mode"))
        setGui.SetFont("s9 c0x" txtHex)
        currentMode := HotkeyManager.GetCurrentMode()
        modeInitial := currentMode = "cheatsheet" ? 1 : 2
        modeDDL := setGui.Add("DropDownList", "xm y+5 w280 Choose" modeInitial,
            [I18n.t("settings.mode_cheatsheet"), I18n.t("settings.mode_remap")])

        applyModeBtn := setGui.Add("Button", "x+10 yp w100 h23", I18n.t("settings.apply"))
        applyModeBtn.OnEvent("Click", (*) => ApplyMode(modeDDL))

        setGui.SetFont("s10 bold c0x" accHex)
        setGui.Add("Text", "xm y+15 w400", I18n.t("settings.theme"))
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

        applyThemeBtn := setGui.Add("Button", "x+10 yp w100 h23", I18n.t("settings.apply"))
        applyThemeBtn.OnEvent("Click", (*) => ApplyTheme(setGui, themeDDL))

        setGui.Add("Text", "xm y+15 h40 w420 Background0x" Format("{:06X}", Theme.ToBGR(Theme.BG())))

        setGui.SetFont("s9 c0x" accHex)
        closeBtn := setGui.Add("Button", "xm y+15 w120 h30 Background0x" surfHex, I18n.t("settings.close"))
        closeBtn.OnEvent("Click", (*) => setGui.Destroy())
        setGui.OnEvent("Escape", (*) => setGui.Destroy())

        ApplyTrigger(ctrl) {
            val := ctrl.Value
            if (val = "") {
                MsgBox(I18n.t("msg.press_valid"), "Key Atlas", "Icon!")
                return
            }
            Config.SetTriggerHotkey(val)
            Config.Save()
            HotkeyManager.UpdateTrigger()
            MsgBox(I18n.t("msg.apply_hotkey"), "Key Atlas")
        }

        ApplyMode(ddl) {
            newMode := ddl.Value = 1 ? "cheatsheet" : "remap"
            HotkeyManager.SwitchMode(newMode)
            MsgBox(I18n.t("msg.apply_mode") newMode, "Key Atlas")
        }

        ApplyTheme(parentGui, ddl) {
            name := ddl.Text
            Theme.Apply(name)
            MsgBox(I18n.t("msg.apply_theme") name I18n.t("msg.theme_restart"), "Key Atlas")
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
        agui := Gui("+Owner" this.GuiObj.Hwnd, I18n.t("auto.title"))
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
        agui.Add("Text", "xm y+10 w500", I18n.t("auto.desc"))

        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+10 w100", I18n.t("auto.program"))
        progNames := Database.GetPrograms()
        progItems := Array()
        progItems.Push(I18n.t("auto.select"))
        for p in progNames
            progItems.Push(p)
        aaProgDDL := agui.Add("DropDownList", "x+10 yp-3 w320 Choose1", progItems)

        agui.Add("Text", "xm y+5 w100", I18n.t("auto.category"))
        catNames := Database.GetCategories()
        catItems := Array()
        catItems.Push(I18n.t("auto.all"))
        for c in catNames
            catItems.Push(c)
        aaCatDDL := agui.Add("DropDownList", "x+10 yp-3 w320 Choose1", catItems)

        agui.Add("Text", "xm y+5 w100", I18n.t("auto.keys"))
        aaKeyPool := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z")
        agui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        agui.Add("Text", "x+10 y+1 w320", I18n.t("auto.keys_hint"))

        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+5 w100", I18n.t("auto.prefix"))
        aaPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            HotkeyManager.FormatForDisplay(HotkeyManager.GetCurrentTrigger()))

        agui.SetFont("s10 bold c0x" accHex)
        agui.Add("Text", "xm y+10 w500", I18n.t("auto.cat_prefix"))
        agui.SetFont("s9 c0x" txtHex)
        agui.Add("Text", "xm y+2 w100", "Format:")
        aaCatPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "f=Search, e=Edit, n=Navigate, v=View")
        agui.SetFont("s8 c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())))
        agui.Add("Text", "x+10 y+1 w320", I18n.t("auto.cat_prefix_hint"))

        agui.Add("Text", "xm y+15 w100", "")
        agui.SetFont("s10 bold c0x" accHex)
        genBtn := agui.Add("Button", "x+10 yp-3 w180 h32 Background0x" surfHex,
            I18n.t("auto.generate"))
        genBtn.OnEvent("Click", (*) => GenerateAssignments(agui))

        cancelBtn := agui.Add("Button",
            "x+10 yp w120 h32 Background0x" surfHex .
            " c0x" Format("{:06X}", Theme.ToBGR(Theme.TXTDIM())),
            I18n.t("editor.cancel"))
        cancelBtn.OnEvent("Click", (*) => agui.Destroy())
        agui.OnEvent("Escape", (*) => agui.Destroy())

        GenerateAssignments(gui) {
            prog := aaProgDDL.Text
            selText := I18n.t("auto.select")
            if (prog = selText) {
                MsgBox(I18n.t("msg.select_program"), "Key Atlas", "Icon!")
                return
            }

            catFilter := aaCatDDL.Text
            if (catFilter = I18n.t("auto.all"))
                catFilter := ""

            pool := Array()
            for part in StrSplit(aaKeyPool.Value, ",") {
                key := Trim(part)
                if (key != "")
                    pool.Push(key)
            }

            if (pool.Length = 0) {
                MsgBox(I18n.t("msg.define_key"), "Key Atlas", "Icon!")
                return
            }

            catPrefixMap := Map()
            for part in StrSplit(aaCatPrefix.Value, ",") {
                part := Trim(part)
                parts := StrSplit(part, "=")
                if (parts.Length = 2)
                    catPrefixMap[Trim(parts[1])] := Trim(parts[2])
            }

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
                MsgBox(I18n.t("msg.no_shortcuts_for") prog I18n.t("msg.in_db"), "Key Atlas", "Icon!")
                return
            }

            poolIdx := 1
            assigned := 0
            for sc in candidates {
                if (poolIdx > pool.Length)
                    break

                key := pool[poolIdx]
                cat := sc.Has("category") ? sc["category"] : I18n.t("category.general")

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
            MsgBox(assigned I18n.t("msg.assigned1") prog I18n.t("msg.assigned2"), "Key Atlas")
        }

        agui.Show("AutoSize Center")
    }
}
