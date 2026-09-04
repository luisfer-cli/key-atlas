; ============================================================
; GuiManager.ahk - Main Configuration Window
; ============================================================

class GuiManager {
    static GuiObj := ""
    static IsVisible := false
    static TreeView := ""
    static ShortcutLV := ""
    static SearchEdit := ""
    static HeaderTitle := ""
    static HeaderSubtitle := ""
    static HeaderDivider := ""
    static NavTitle := ""
    static ScopeText := ""
    static StatusText := ""
    static HintText := ""
    static NewBtn := ""
    static EditBtn := ""
    static DeleteBtn := ""
    static AutoBtn := ""
    static ImportBtn := ""
    static ExportBtn := ""
    static SettingsBtn := ""
    static MoreBtn := ""
    static RemapSetupGui := ""
    static RowIds := Array()
    static CurrentProgram := ""
    static CurrentCategory := ""
    static LastActiveTitle := ""
    static LastActiveProcess := ""

    static Show() {
        if (this.IsVisible) {
            this.GuiObj.Show()
            WinActivate(this.GuiObj.Hwnd)
            return
        }
        try this.LastActiveTitle := WinGetTitle("A")
        try this.LastActiveProcess := WinGetProcessName("A")
        this._CreateGui()
        this._PopulateTreeView()
        this._RefreshListView(this._GetFilteredShortcuts())
        this.GuiObj.Show("w1100 h700 Center")
        this._OnResize(0, 1100, 700)
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

    static _CreateGui() {
        this.GuiObj := Gui("+Resize +MinSize860x560", I18n.t("gui.title"))
        this.GuiObj.BackColor := Theme.ToBGR(Theme.BG())
        this.GuiObj.MarginX := 0
        this.GuiObj.MarginY := 0
        this.GuiObj.OnEvent("Close", (*) => this.Close())
        this.GuiObj.OnEvent("Escape", (*) => this.Close())
        this.GuiObj.OnEvent("Size", (_, minMax, width, height) => this._OnResize(minMax, width, height))
        this._CreateToolbar()
        this._CreateTreePanel()
        this._CreateShortcutPanel()
    }

    static _CreateToolbar() {
        txt := Theme.TXT()
        acc := Theme.ACC()
        surfBGR := Theme.ToBGR(Theme.SURF())
        bdrBGR := Theme.ToBGR(Theme.BDR())

        this.GuiObj.SetFont("s19 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        this.HeaderTitle := this.GuiObj.Add("Text", "x24 y16 w430 h32", I18n.t("gui.library"))
        this.GuiObj.SetFont("s9 norm c" Theme.TXTDIM(), "Segoe UI")
        this.HeaderSubtitle := this.GuiObj.Add("Text", "x25 y51 w500 h20", I18n.t("gui.subtitle"))

        this.GuiObj.SetFont("s10 norm c" txt, "Segoe UI")
        this.SearchEdit := this.GuiObj.Add("Edit",
            "x680 y22 w390 h32 Background0x" Format("{:06X}", surfBGR) " c" txt)
        try SendMessage(0x1501, true, StrPtr(I18n.t("toolbar.search_hint")), this.SearchEdit)
        this.SearchEdit.OnEvent("Change", (*) => this._OnSearch())
        this.HeaderDivider := this.GuiObj.Add("Text",
            "x0 y82 w1100 h1 Background0x" Format("{:06X}", bdrBGR))
    }

    static _CreateTreePanel() {
        txt := Theme.TXT()

        this.GuiObj.SetFont("s9 bold c" Theme.TXTDIM(), "Segoe UI")
        this.NavTitle := this.GuiObj.Add("Text", "x24 y104 w230 h22", I18n.t("tree.title"))
        this.GuiObj.SetFont("s9 norm c" txt, "Segoe UI")
        this.TreeView := this.GuiObj.Add("TreeView",
            "x24 y132 w236 h500 -Lines Background0x" Format("{:06X}", Theme.ToBGR(Theme.SURF()))
            " c" txt)
        this.TreeView.OnEvent("ItemSelect", (*) => this._OnTreeSelect())
    }

    static _CreateShortcutPanel() {
        txt := Theme.TXT()
        acc := Theme.ACC()
        surfBGR := Theme.ToBGR(Theme.SURF())
        this.GuiObj.SetFont("s12 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        this.ScopeText := this.GuiObj.Add("Text", "x284 y103 w500 h26", I18n.t("program.all"))

        this.GuiObj.SetFont("s9 c" acc, "Segoe UI")
        btnOpts := "h30 Background0x" Format("{:06X}", surfBGR)
        this.NewBtn := this.GuiObj.Add("Button", "x284 y135 w128 " btnOpts, I18n.t("btn.new"))
        this.NewBtn.OnEvent("Click", (*) => this._ShowEditor())
        this.EditBtn := this.GuiObj.Add("Button", "x418 y135 w82 " btnOpts, I18n.t("btn.edit"))
        this.EditBtn.OnEvent("Click", (*) => this._EditSelected())
        this.DeleteBtn := this.GuiObj.Add("Button", "x506 y135 w82 " btnOpts, I18n.t("btn.delete"))
        this.DeleteBtn.OnEvent("Click", (*) => this._DeleteSelected())
        this.AutoBtn := this.GuiObj.Add("Button", "x600 y135 w120 " btnOpts, I18n.t("toolbar.autoassign"))
        this.AutoBtn.OnEvent("Click", (*) => this.ShowRemapSetup())
        this.ImportBtn := this.GuiObj.Add("Button", "x726 y135 w82 " btnOpts, I18n.t("toolbar.import"))
        this.ImportBtn.OnEvent("Click", (*) => this._ImportShortcuts())
        this.ExportBtn := this.GuiObj.Add("Button", "x814 y135 w82 " btnOpts, I18n.t("toolbar.export"))
        this.ExportBtn.OnEvent("Click", (*) => this._ExportShortcuts())
        this.MoreBtn := this.GuiObj.Add("Button", "x734 y135 w120 Hidden " btnOpts, I18n.t("toolbar.more"))
        this.MoreBtn.OnEvent("Click", (*) => this._ShowMoreMenu())
        this.SettingsBtn := this.GuiObj.Add("Button", "x970 y135 w100 " btnOpts, I18n.t("toolbar.settings"))
        this.SettingsBtn.OnEvent("Click", (*) => this._ShowSettingsDialog())

        this.GuiObj.SetFont("s9 norm c" txt, "Segoe UI")
        this.ShortcutLV := this.GuiObj.Add("ListView",
            "x284 y176 w786 h456 Grid -Multi Background0x" Format("{:06X}", surfBGR)
            " c" txt,
            [I18n.t("col.remap"), I18n.t("col.trigger"), I18n.t("col.desc"),
             I18n.t("col.category"), I18n.t("col.process"), I18n.t("col.mode")])
        this.ShortcutLV.OnEvent("DoubleClick", (*) => this._EditSelected())
        this.ShortcutLV.OnEvent("ItemSelect", (*) => this._UpdateSelectionState())

        this.GuiObj.SetFont("s9 c" Theme.TXTDIM(), "Segoe UI")
        this.StatusText := this.GuiObj.Add("Text", "x284 y648 w400 h22", "")
        this.HintText := this.GuiObj.Add("Text", "x750 y648 w320 h22 Right", I18n.t("footer.hint"))
        this._UpdateSelectionState()
    }

    static _OnResize(minMax, width, height) {
        if (minMax = -1 || this.GuiObj = "")
            return
        navWidth := 236
        contentX := 284
        contentWidth := width - contentX - 24
        listHeight := height - 244

        this.HeaderDivider.Move(,, width)
        this.SearchEdit.Move(width - 414,, 390)
        this.TreeView.Move(,, navWidth, height - 200)
        this.ShortcutLV.Move(,, contentWidth, listHeight)
        this.StatusText.Move(, height - 52, contentWidth - 330)
        this.HintText.Move(width - 344, height - 52, 320)
        this.SettingsBtn.Move(width - 130)
        showTransferActions := width >= 1050
        this.AutoBtn.Visible := showTransferActions
        this.ImportBtn.Visible := showTransferActions
        this.ExportBtn.Visible := showTransferActions
        this.MoreBtn.Visible := !showTransferActions
        this.MoreBtn.Move(width - 266)

        descWidth := Max(170, contentWidth - 570)
        this.ShortcutLV.ModifyCol(1, 100)
        this.ShortcutLV.ModifyCol(2, 110)
        this.ShortcutLV.ModifyCol(3, descWidth)
        this.ShortcutLV.ModifyCol(4, 110)
        this.ShortcutLV.ModifyCol(5, 120)
        this.ShortcutLV.ModifyCol(6, 80)
    }

    static _ShowMoreMenu() {
        moreMenu := Menu()
        moreMenu.Add(I18n.t("toolbar.autoassign"), (*) => this.ShowRemapSetup())
        moreMenu.Add(I18n.t("toolbar.import"), (*) => this._ImportShortcuts())
        moreMenu.Add(I18n.t("toolbar.export"), (*) => this._ExportShortcuts())
        moreMenu.Show()
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

        allID := this.TreeView.Add(I18n.t("program.all"), 0, "Expand")
        selectedID := allID
        for prog in progNames {
            progID := this.TreeView.Add(prog, 0, "Expand")
            if (prog = this.CurrentProgram && this.CurrentCategory = "")
                selectedID := progID
            catNames := Array()
            for cat in allProc[prog]
                catNames.Push(cat)
            Database._SortArray(&catNames)
            for cat in catNames {
                catID := this.TreeView.Add(cat, progID)
                if (prog = this.CurrentProgram && cat = this.CurrentCategory)
                    selectedID := catID
            }
        }

        if (selectedID = allID && this.CurrentProgram != "") {
            this.CurrentProgram := ""
            this.CurrentCategory := ""
            this._UpdateScopeText()
        }
        this.TreeView.Modify(selectedID, "Select")
    }

    static _OnTreeSelect() {
        selItem := this.TreeView.GetSelection()
        if (!selItem)
            return

        parentID := this.TreeView.GetParent(selItem)
        selText := this.TreeView.GetText(selItem)

        if (parentID = 0) {
            this.CurrentProgram := selText = I18n.t("program.all") ? "" : selText
            this.CurrentCategory := ""
        } else {
            this.CurrentProgram := this.TreeView.GetText(parentID)
            this.CurrentCategory := selText
        }
        this._UpdateScopeText()
        this._RefreshListView(this._GetFilteredShortcuts())
    }

    static _OnSearch() {
        this._RefreshListView(this._GetFilteredShortcuts())
    }

    static _GetFilteredShortcuts() {
        results := Array()
        query := this.SearchEdit = "" ? "" : StrLower(Trim(this.SearchEdit.Value))

        for sc in Database.GetAll() {
            program := sc.Has("program") ? sc["program"] : ""
            category := sc.Has("category") && sc["category"] != ""
                ? sc["category"] : I18n.t("category.general")
            if (this.CurrentProgram != "" && program != this.CurrentProgram)
                continue
            if (this.CurrentCategory != "" && category != this.CurrentCategory)
                continue
            if (query != "") {
                haystack := StrLower(program " " category " "
                    (sc.Has("description") ? sc["description"] : "") " "
                    (sc.Has("triggerKeys") ? sc["triggerKeys"] : "") " "
                    (sc.Has("remapKeys") ? RemapManager.FormatSequence(sc["remapKeys"]) : "") " "
                    (sc.Has("process") ? sc["process"] : ""))
                if (!InStr(haystack, query))
                    continue
            }
            results.Push(sc)
        }
        return results
    }

    static _RefreshListView(shortcuts) {
        this.ShortcutLV.Delete()
        this.RowIds := Array()
        for sc in shortcuts {
            trig := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
            remap := sc.Has("remapKeys") ? RemapManager.FormatSequence(sc["remapKeys"]) : "-"
            desc := sc.Has("description") ? sc["description"] : ""
            proc := sc.Has("process") ? sc["process"] : ""
            cat  := sc.Has("category") ? sc["category"] : ""
            mode := sc.Has("mode") ? sc["mode"] : "remap"
            this.ShortcutLV.Add(, remap, trig, desc, cat, proc, mode)
            this.RowIds.Push(sc.Has("id") ? sc["id"] : "")
        }
        this.StatusText.Text := shortcuts.Length " " I18n.t("footer.visible") "  /  "
            Database.GetAll().Length " " I18n.t("footer.total_short")
        this._UpdateSelectionState()
    }

    static _UpdateScopeText() {
        scope := this.CurrentProgram = "" ? I18n.t("program.all") : this.CurrentProgram
        if (this.CurrentCategory != "")
            scope .= "  /  " this.CurrentCategory
        this.ScopeText.Text := scope
    }

    static _UpdateSelectionState() {
        hasSelection := this.ShortcutLV != "" && this.ShortcutLV.GetNext() > 0
        if (this.EditBtn != "")
            this.EditBtn.Enabled := hasSelection
        if (this.DeleteBtn != "")
            this.DeleteBtn.Enabled := hasSelection
    }

    static _GetSelectedShortcut() {
        row := this.ShortcutLV.GetNext()
        if (row = 0 || row > this.RowIds.Length)
            return ""
        return Database.GetById(this.RowIds[row])
    }

    ; ==========================================================
    ; Editor Dialog
    ; ==========================================================

    static _ShowEditor(shortcutData := "") {
        isEditing := shortcutData != "" && shortcutData is Map
        capturedTitle := this.LastActiveTitle
        capturedProcess := this.LastActiveProcess

        editGui := Gui("+Owner" this.GuiObj.Hwnd " +MinSize640x660",
            isEditing ? I18n.t("editor.title_edit") : I18n.t("editor.title_new"))
        editGui.BackColor := Theme.ToBGR(Theme.BG())
        editGui.MarginX := 24
        editGui.MarginY := 20

        txt := Theme.TXT()
        surf := Theme.SURF()
        acc := Theme.ACC()
        dim := Theme.TXTDIM()

        txtHex := Format("{:06X}", Theme.ToBGR(surf))
        inputStyle := "w360 h28 Background0x" txtHex " c" txt

        editGui.SetFont("s18 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        editGui.Add("Text", "xm ym w560 h32", isEditing ? I18n.t("editor.heading_edit") : I18n.t("editor.heading_new"))
        editGui.SetFont("s9 norm c" dim, "Segoe UI")
        editGui.Add("Text", "xm y+2 w560 h36", I18n.t("editor.subtitle"))

        editGui.SetFont("s10 bold c" acc, "Segoe UI")
        editGui.Add("Text", "xm y+14 w560 h24", I18n.t("editor.section_app"))
        editGui.SetFont("s9 norm c" txt, "Segoe UI")
        editGui.Add("Text", "xm y+5 w150", I18n.t("editor.program"))
        edProgram := editGui.Add("Edit", "x+10 yp-4 " inputStyle)
        edProgram.Value := isEditing && shortcutData.Has("program")
            ? shortcutData["program"] : (this.CurrentProgram != "" ? this.CurrentProgram : capturedTitle)

        editGui.Add("Text", "xm y+10 w150", I18n.t("editor.process"))
        edProcess := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edProcess.Value := isEditing && shortcutData.Has("process")
            ? shortcutData["process"] : capturedProcess

        detectBtn := editGui.Add("Button", "xm y+9 w210 h29", I18n.t("editor.detect"))
        detectBtn.OnEvent("Click", (*) => DetectWindow(edProgram, edProcess))

        DetectWindow(edProg, edProc) {
            editGui.Hide()
            this.GuiObj.Hide()
            Sleep(150)
            try capturedTitle := WinGetTitle("A")
            try capturedProcess := WinGetProcessName("A")
            edProg.Value := capturedTitle
            edProc.Value := capturedProcess
            this.GuiObj.Show()
            editGui.Show()
        }

        editGui.SetFont("s10 bold c" acc)
        editGui.Add("Text", "xm y+20 w560 h24", I18n.t("editor.section_shortcut"))
        editGui.SetFont("s9 norm c" txt)
        editGui.Add("Text", "xm y+5 w150", I18n.t("editor.desc"))
        edDesc := editGui.Add("Edit", "x+10 yp-4 " inputStyle)
        edDesc.Value := isEditing && shortcutData.Has("description") ? shortcutData["description"] : ""

        editGui.Add("Text", "xm y+10 w150", I18n.t("editor.category"))
        edCategory := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edCategory.Value := isEditing && shortcutData.Has("category")
            ? shortcutData["category"] : this.CurrentCategory

        editGui.Add("Text", "xm y+10 w150", I18n.t("editor.trigger"))
        edTrigger := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTrigger.Value := isEditing && shortcutData.Has("triggerKeys") ? shortcutData["triggerKeys"] : ""
        editGui.SetFont("s8 c" dim)
        editGui.Add("Text", "x184 y+3 w360", I18n.t("editor.hint"))

        editGui.SetFont("s9 c" txt)
        editGui.Add("Text", "xm y+12 w150", I18n.t("editor.remap"))
        edRemap := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edRemap.Value := isEditing && shortcutData.Has("remapKeys")
            ? RemapManager.FormatSequence(shortcutData["remapKeys"]) : ""
        editGui.SetFont("s8 c" dim)
        editGui.Add("Text", "x184 y+3 w360", I18n.t("editor.remap_hint"))

        editGui.SetFont("s9 c" txt)
        editGui.Add("Text", "xm y+12 w150", I18n.t("editor.target"))
        edTarget := editGui.Add("Edit", "x+10 yp-3 " inputStyle)
        edTarget.Value := isEditing && shortcutData.Has("targetKeys") ? shortcutData["targetKeys"] : ""

        editGui.Add("Text", "xm y+10 w150", I18n.t("editor.mode"))
        cbMode := editGui.Add("DropDownList", "x+10 yp-3 w360 Choose1",
            [I18n.t("editor.mode_remap"), I18n.t("editor.mode_sheet")])
        if (isEditing && shortcutData.Has("mode") && shortcutData["mode"] = "cheatsheet")
            cbMode.Choose(2)

        editGui.SetFont("s10 bold c" acc)
        saveBtn := editGui.Add("Button",
            "xm y+24 w170 h36 Default Background0x" txtHex, I18n.t("editor.save"))
        saveBtn.OnEvent("Click", (*) => SaveShortcut(editGui))

        cancelBtn := editGui.Add("Button",
            "x+10 yp w130 h36 Background0x" txtHex " c" dim, I18n.t("editor.cancel"))
        cancelBtn.OnEvent("Click", (*) => editGui.Destroy())

        editGui.OnEvent("Escape", (*) => editGui.Destroy())
        editGui.OnEvent("Close", (*) => editGui.Destroy())

        SaveShortcut(gui) {
            needsRebalance := false
            data := Map()
            data["program"] := edProgram.Value
            data["process"] := edProcess.Value
            data["category"] := edCategory.Value
            data["description"] := edDesc.Value
            data["triggerKeys"] := edTrigger.Value
            data["remapKeys"] := RemapManager.ParseSequence(edRemap.Value)
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
            if (data["mode"] = "remap" && Trim(data["process"]) = "") {
                MsgBox(I18n.t("msg.process_required"), "Key Atlas", "Icon!")
                return
            }
            if (data["mode"] = "remap" && data["targetKeys"] = "") {
                MsgBox(I18n.t("msg.target_required"), "Key Atlas", "Icon!")
                return
            }
            if (data["mode"] = "remap" && data["remapKeys"].Length = 0
                && Config.GetDefaultMode() = "remap") {
                data["remapKeys"] := RemapManager.FindAvailableSequence(
                    data["process"], Config.GetRemapKeys())
                if (data["remapKeys"].Length = 0) {
                    existingIsSameRemap := isEditing
                        && (!shortcutData.Has("mode") || shortcutData["mode"] = "remap")
                        && shortcutData.Has("process")
                        && StrLower(Trim(shortcutData["process"])) = StrLower(Trim(data["process"]))
                    additionalCount := existingIsSameRemap ? 0 : 1
                    if (!RemapManager.CanAssignProcess(data["process"],
                        Config.GetRemapKeys(), additionalCount)) {
                        MsgBox(I18n.t("msg.remap_no_sequence_available"), "Key Atlas", "Icon!")
                        return
                    }
                    needsRebalance := true
                }
            }
            if (data["remapKeys"].Length > 0) {
                keyPool := Config.GetRemapKeys()
                if (keyPool.Length < 2 || !RemapManager.IsSequenceAllowed(data["remapKeys"], keyPool)) {
                    MsgBox(I18n.t("msg.remap_keys_invalid"), "Key Atlas", "Icon!")
                    return
                }
                if (data["remapKeys"].Length > Config.GetRemapMaxKeys()) {
                    MsgBox(I18n.t("msg.remap_sequence_too_long"), "Key Atlas", "Icon!")
                    return
                }
                excludeId := isEditing && shortcutData.Has("id") ? shortcutData["id"] : ""
                conflict := RemapManager.FindConflict(data["process"], data["remapKeys"], excludeId)
                if (conflict != "") {
                    conflictDesc := conflict.Has("description") ? conflict["description"] : ""
                    MsgBox(I18n.t("msg.remap_conflict") conflictDesc, "Key Atlas", "Icon!")
                    return
                }
            }

            if (isEditing && shortcutData.Has("id"))
                Database.Update(shortcutData["id"], data)
            else {
                data["id"] := ""
                Database.Add(data)
            }
            if (needsRebalance
                && RemapManager.AssignProcess(data["process"], Config.GetRemapKeys()) < 0) {
                MsgBox(I18n.t("msg.remap_no_sequence_available"), "Key Atlas", "Icon!")
                return
            }

            gui.Destroy()
            this._RefreshView()
        }

        editGui.Show("AutoSize Center")
    }

    static _EditSelected() {
        shortcut := this._GetSelectedShortcut()
        if (shortcut = "") {
            MsgBox(I18n.t("msg.select_edit"), "Key Atlas", "Iconi")
            return
        }
        this._ShowEditor(shortcut)
    }

    static _DeleteSelected() {
        shortcut := this._GetSelectedShortcut()
        if (shortcut = "") {
            MsgBox(I18n.t("msg.select_delete"), "Key Atlas", "Iconi")
            return
        }
        desc := shortcut.Has("description") ? shortcut["description"] : ""
        trigger := shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : ""
        result := MsgBox(I18n.t("msg.confirm_delete") desc "' [" trigger "]?",
            "Key Atlas", "YesNo Icon?")
        if (result = "Yes") {
            Database.Delete(shortcut["id"])
            this._RefreshView()
        }
    }

    static _RefreshView() {
        this._PopulateTreeView()
        this._RefreshListView(this._GetFilteredShortcuts())
    }

    ; ==========================================================
    ; Quick Add
    ; ==========================================================

    static QuickAdd(program, process, triggerKeys) {
        qGui := Gui("+Owner +ToolWindow", I18n.t("quick.new_title"))
        qGui.BackColor := Theme.ToBGR(Theme.BG())
        qGui.SetFont("s9", "Segoe UI")

        txt := Theme.TXT()
        surf := Theme.SURF()
        acc := Theme.ACC()
        dim := Theme.TXTDIM()
        surfBGR := Theme.ToBGR(surf)

        surfHex := Format("{:06X}", surfBGR)
        inputStyle := "w320 Background0x" surfHex " c" txt

        qGui.SetFont("s10 bold c" acc)
        qGui.Add("Text", "xm y+10 w380", program)

        qGui.SetFont("s9 c" txt)
        qGui.Add("Text", "xm y+5 w380", I18n.t("quick.keys_captured") triggerKeys)

        qGui.Add("Text", "xm y+8 w100", I18n.t("editor.desc"))
        edDesc := qGui.Add("Edit", "x+10 yp-3 " inputStyle)

        qGui.Add("Text", "xm y+5 w100", I18n.t("quick.target_prompt"))
        edTarget := qGui.Add("Edit", "x+10 yp-3 " inputStyle)

        qGui.Add("Text", "xm y+5 w100", I18n.t("editor.category"))
        edCat := qGui.Add("Edit", "x+10 yp-3 w200 Background0x" surfHex " c" txt)

        qGui.Add("Text", "xm y+12 w100", "")
        qGui.SetFont("s10 bold c" acc)
        saveBtn := qGui.Add("Button", "x+10 yp w120 h30 Default Background0x" surfHex, I18n.t("editor.save"))
        saveBtn.OnEvent("Click", (*) => SaveQuick(qGui))

        cancelBtn := qGui.Add("Button",
            "x+10 yp w120 h30 Background0x" surfHex " c" dim, I18n.t("quick.cancel"))
        cancelBtn.OnEvent("Click", (*) => qGui.Destroy())
        qGui.OnEvent("Escape", (*) => qGui.Destroy())
        qGui.OnEvent("Close", (*) => qGui.Destroy())

        SaveQuick(gui) {
            if (edDesc.Value = "") {
                MsgBox(I18n.t("msg.desc_required"), "Key Atlas", "Icon!")
                return
            }
            if (edTarget.Value = "") {
                MsgBox(I18n.t("msg.target_required"), "Key Atlas", "Icon!")
                return
            }
            data := Map()
            data["id"] := ""
            data["program"] := program
            data["process"] := process
            data["category"] := edCat.Value
            data["description"] := edDesc.Value
            data["triggerKeys"] := triggerKeys
            data["targetKeys"] := edTarget.Value
            data["mode"] := "remap"
            suggestedRemap := RemapManager.FindAvailableSequence(process, Config.GetRemapKeys())
            needsRebalance := false
            if (suggestedRemap.Length > 0) {
                data["remapKeys"] := suggestedRemap
            } else if (Config.GetDefaultMode() = "remap") {
                if (!RemapManager.CanAssignProcess(process, Config.GetRemapKeys(), 1)) {
                    MsgBox(I18n.t("msg.remap_no_sequence_available"), "Key Atlas", "Icon!")
                    return
                }
                needsRebalance := true
            }
            Database.Add(data)
            if (needsRebalance)
                RemapManager.AssignProcess(process, Config.GetRemapKeys())
            gui.Destroy()
            if (this.IsVisible)
                this._RefreshView()
        }

        qGui.Show("AutoSize Center")
    }

    ; ==========================================================
    ; Settings Dialog
    ; ==========================================================

    static ShowRemapSetup() {
        if (this.RemapSetupGui != "") {
            try {
                this.RemapSetupGui.Show()
                WinActivate(this.RemapSetupGui.Hwnd)
                return
            }
            this.RemapSetupGui := ""
        }
        ownerOptions := this.IsVisible ? "+Owner" this.GuiObj.Hwnd : "+AlwaysOnTop"
        setupGui := Gui(ownerOptions, I18n.t("remap.setup_title"))
        this.RemapSetupGui := setupGui
        setupGui.BackColor := Theme.ToBGR(Theme.BG())
        setupGui.MarginX := 24
        setupGui.MarginY := 20
        txt := Theme.TXT()
        dim := Theme.TXTDIM()
        accent := Theme.ACC()
        surfHex := Format("{:06X}", Theme.ToBGR(Theme.SURF()))

        setupGui.SetFont("s18 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        setupGui.Add("Text", "xm ym w520 h32", I18n.t("remap.setup_heading"))
        setupGui.SetFont("s9 norm c" dim)
        setupGui.Add("Text", "xm y+4 w520 h52", I18n.t("remap.setup_desc"))
        setupGui.SetFont("s10 bold c" accent)
        setupGui.Add("Text", "xm y+16 w520 h24", I18n.t("remap.setup_keys"))
        setupGui.SetFont("s11 norm c" txt, "Consolas")
        currentKeys := RemapManager.FormatSequence(Config.GetRemapKeys())
        if (currentKeys = "")
            currentKeys := "a,s,d,f,j,k,l"
        keysEdit := setupGui.Add("Edit", "xm y+5 w520 h34 Background0x" surfHex " c" txt,
            currentKeys)
        setupGui.SetFont("s9 norm c" dim, "Segoe UI")
        setupGui.Add("Text", "xm y+6 w520 h42", I18n.t("remap.setup_hint"))

        setupGui.SetFont("s10 bold c" accent)
        saveBtn := setupGui.Add("Button", "xm y+18 w190 h38 Default Background0x" surfHex,
            I18n.t("remap.setup_generate"))
        saveBtn.OnEvent("Click", (*) => SaveSetup())
        cancelBtn := setupGui.Add("Button", "x+10 yp w120 h38 Background0x" surfHex " c" dim,
            I18n.t("editor.cancel"))
        cancelBtn.OnEvent("Click", (*) => this._CloseRemapSetup())
        setupGui.OnEvent("Escape", (*) => this._CloseRemapSetup())
        setupGui.OnEvent("Close", (*) => this._CloseRemapSetup())

        SaveSetup() {
            keys := RemapManager.ParseKeyPool(keysEdit.Value)
            if (keys.Length < 2) {
                MsgBox(I18n.t("msg.remap_pool_required"), "Key Atlas", "Icon!")
                return
            }
            if (!RemapManager.CanAssignAll(keys)) {
                MsgBox(I18n.t("msg.remap_pool_capacity"), "Key Atlas", "Icon!")
                return
            }
            Config.SetRemapKeys(keys)
            Config.SetDefaultMode("remap")
            Config.Save()
            assigned := RemapManager.AssignAll(keys)
            HotkeyManager.UpdateTrigger()
            try SetupTray()
            this._CloseRemapSetup()
            if (this.IsVisible)
                this._RefreshView()
            TrayTip(assigned . I18n.t("remap.setup_done"), "Key Atlas", "Iconi")
        }

        setupGui.Show("w570 h350 Center")
    }

    static _CloseRemapSetup() {
        if (this.RemapSetupGui != "")
            try this.RemapSetupGui.Destroy()
        this.RemapSetupGui := ""
    }

    static _ShowSettingsDialog() {
        setGui := Gui("+Owner" this.GuiObj.Hwnd, I18n.t("settings.title"))
        setGui.BackColor := Theme.ToBGR(Theme.BG())
        setGui.MarginX := 24
        setGui.MarginY := 20

        txt := Theme.TXT()
        acc := Theme.ACC()
        dim := Theme.TXTDIM()
        surfHex := Format("{:06X}", Theme.ToBGR(Theme.SURF()))

        setGui.SetFont("s18 bold c" Theme.TXTBRIGHT(), "Segoe UI")
        setGui.Add("Text", "xm ym w540 h32", I18n.t("settings.heading"))
        setGui.SetFont("s9 norm c" dim)
        setGui.Add("Text", "xm y+2 w540 h34", I18n.t("settings.subtitle"))

        setGui.SetFont("s10 bold c" acc)
        setGui.Add("Text", "xm y+15 w540 h24", I18n.t("settings.section_behavior"))
        setGui.SetFont("s9 norm c" txt)
        setGui.Add("Text", "xm y+6 w170", I18n.t("settings.combo"))
        triggerCtrl := setGui.Add("Hotkey", "x+10 yp-4 w330 h28 c" txt)
        triggerCtrl.Value := HotkeyManager.GetCurrentTrigger()

        setGui.Add("Text", "xm y+12 w170", I18n.t("settings.default_mode"))
        modeInitial := Config.GetDefaultMode() = "remap" ? 2 : 1
        modeDDL := setGui.Add("DropDownList", "x+10 yp-4 w330 Choose" modeInitial,
            [I18n.t("settings.mode_cheatsheet"), I18n.t("settings.mode_remap")])

        setGui.SetFont("s10 bold c" acc)
        setGui.Add("Text", "xm y+20 w540 h24", I18n.t("settings.section_remap"))
        setGui.SetFont("s9 norm c" txt)
        setGui.Add("Text", "xm y+6 w170", I18n.t("settings.remap_keys"))
        remapKeysEdit := setGui.Add("Edit", "x+10 yp-4 w330 h28 Background0x" surfHex " c" txt,
            RemapManager.FormatSequence(Config.GetRemapKeys()))
        setGui.SetFont("s8 norm c" dim)
        setGui.Add("Text", "x204 y+4 w330 h34", I18n.t("settings.remap_keys_hint"))

        setGui.SetFont("s10 bold c" acc)
        setGui.Add("Text", "xm y+20 w540 h24", I18n.t("settings.section_appearance"))
        setGui.SetFont("s9 norm c" txt)
        themeNames := Theme.GetPresetNames()
        currentTheme := Config.GetTheme()
        themeIdx := 1
        for i, name in themeNames {
            if (name = currentTheme) {
                themeIdx := i
                break
            }
        }
        setGui.Add("Text", "xm y+6 w170", I18n.t("settings.theme"))
        themeDDL := setGui.Add("DropDownList", "x+10 yp-4 w330 Choose" themeIdx, themeNames)

        currentLang := Config.Get("lang", "en")
        langInitial := currentLang = "es" ? 2 : 1
        setGui.Add("Text", "xm y+12 w170", I18n.t("settings.lang"))
        langDDL := setGui.Add("DropDownList", "x+10 yp-4 w330 Choose" langInitial,
            [I18n.t("settings.lang_en"), I18n.t("settings.lang_es")])

        setGui.SetFont("s10 bold c" acc)
        setGui.Add("Text", "xm y+20 w540 h24", I18n.t("settings.section_overlay"))
        setGui.SetFont("s9 norm c" txt)
        setGui.Add("Text", "xm y+6 w170", I18n.t("settings.max_items"))
        maxItemsEdit := setGui.Add("Edit", "x+10 yp-4 w90 h28 Number Background0x" surfHex " c" txt,
            Config.GetCheatsheetMaxItems())
        maxItemsEdit.OnEvent("Change", (*) => ValidateNumber(maxItemsEdit, 5, 50))

        setGui.Add("Text", "xm y+12 w170", I18n.t("settings.opacity"))
        opacitySlider := setGui.Add("Slider", "x+10 yp-5 w330 Range120-255 ToolTip")
        opacitySlider.Value := Config.GetCheatsheetOpacity()

        setGui.Add("Text", "xm y+12 w170", I18n.t("settings.timeout"))
        timeoutEdit := setGui.Add("Edit", "x+10 yp-4 w90 h28 Background0x" surfHex " c" txt,
            Config.Get("remap.timeout", 2.0))

        setGui.SetFont("s10 bold c" acc)
        saveBtn := setGui.Add("Button", "xm y+24 w160 h36 Default Background0x" surfHex,
            I18n.t("settings.save"))
        saveBtn.OnEvent("Click", (*) => SaveSettings(setGui))
        cancelBtn := setGui.Add("Button", "x+10 yp w130 h36 Background0x" surfHex " c" dim,
            I18n.t("editor.cancel"))
        cancelBtn.OnEvent("Click", (*) => setGui.Destroy())
        setGui.OnEvent("Escape", (*) => setGui.Destroy())
        setGui.OnEvent("Close", (*) => setGui.Destroy())

        ValidateNumber(ctrl, minimum, maximum) {
            if (ctrl.Value = "")
                return
            value := Integer(ctrl.Value)
            if (value < minimum)
                ctrl.Value := minimum
            else if (value > maximum)
                ctrl.Value := maximum
        }

        SaveSettings(gui) {
            if (triggerCtrl.Value = "") {
                MsgBox(I18n.t("msg.press_valid"), "Key Atlas", "Icon!")
                return
            }
            if (maxItemsEdit.Value = "")
                maxItemsEdit.Value := 12
            if (!IsNumber(timeoutEdit.Value)) {
                MsgBox(I18n.t("msg.timeout_range"), "Key Atlas", "Icon!")
                return
            }
            timeout := timeoutEdit.Value + 0
            if (timeout < 0.5 || timeout > 10) {
                MsgBox(I18n.t("msg.timeout_range"), "Key Atlas", "Icon!")
                return
            }

            newMode := modeDDL.Value = 2 ? "remap" : "cheatsheet"
            oldKeys := Config.GetRemapKeys()
            remapKeys := RemapManager.ParseKeyPool(remapKeysEdit.Value)
            if (newMode = "remap" && remapKeys.Length < 2) {
                MsgBox(I18n.t("msg.remap_pool_required"), "Key Atlas", "Icon!")
                return
            }
            if (remapKeys.Length >= 2 && !RemapManager.CanAssignAll(remapKeys)) {
                MsgBox(I18n.t("msg.remap_pool_capacity"), "Key Atlas", "Icon!")
                return
            }
            keysChanged := RemapManager.SequenceKey(oldKeys) != RemapManager.SequenceKey(remapKeys)

            Config.SetTriggerHotkey(triggerCtrl.Value)
            Config.SetDefaultMode(newMode)
            Config.SetRemapKeys(remapKeys)
            Config.Set("cheatsheet.maxItems", Integer(maxItemsEdit.Value))
            Config.Set("cheatsheet.overlayOpacity", opacitySlider.Value)
            Config.Set("remap.timeout", timeout)
            newLang := langDDL.Value = 1 ? "en" : "es"
            Config.Set("lang", newLang)
            Theme.Apply(themeDDL.Text)
            Config.Save()
            if (keysChanged || (newMode = "remap" && !RemapManager.HasAssignments()))
                RemapManager.AssignAll(remapKeys)
            I18n.Init()
            HotkeyManager.UpdateTrigger()
            try SetupTray()
            gui.Destroy()
            this.Close()
            this.Show()
        }

        setGui.Show("w590 h720 Center")
    }

    ; ==========================================================
    ; Auto-Assign Dialog
    ; ==========================================================

    static _ShowAutoAssign() {
        agui := Gui("+Owner" this.GuiObj.Hwnd, I18n.t("auto.title"))
        agui.BackColor := Theme.ToBGR(Theme.BG())
        agui.SetFont("s9", "Segoe UI")

        txt := Theme.TXT()
        surf := Theme.SURF()
        acc := Theme.ACC()
        dim := Theme.TXTDIM()
        surfBGR := Theme.ToBGR(surf)

        surfHex := Format("{:06X}", surfBGR)
        inputStyle := "w320 Background0x" surfHex " c" txt

        agui.SetFont("s10 bold c" acc)
        agui.Add("Text", "xm y+10 w500", I18n.t("auto.desc"))

        agui.SetFont("s9 c" txt)
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
        agui.SetFont("s8 c" dim)
        agui.Add("Text", "x+10 y+1 w320", I18n.t("auto.keys_hint"))

        agui.SetFont("s9 c" txt)
        agui.Add("Text", "xm y+5 w100", I18n.t("auto.prefix"))
        aaPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "")

        agui.SetFont("s10 bold c" acc)
        agui.Add("Text", "xm y+10 w500", I18n.t("auto.cat_prefix"))
        agui.SetFont("s9 c" txt)
        agui.Add("Text", "xm y+2 w100", "Format:")
        aaCatPrefix := agui.Add("Edit", "x+10 yp-3 " inputStyle,
            "f=Search, e=Edit, n=Navigate, v=View")
        agui.SetFont("s8 c" dim)
        agui.Add("Text", "x+10 y+1 w320", I18n.t("auto.cat_prefix_hint"))

        agui.Add("Text", "xm y+15 w100", "")
        agui.SetFont("s10 bold c" acc)
        genBtn := agui.Add("Button", "x+10 yp-3 w180 h32 Background0x" surfHex,
            I18n.t("auto.generate"))
        genBtn.OnEvent("Click", (*) => GenerateAssignments(agui))

        cancelBtn := agui.Add("Button",
            "x+10 yp w120 h32 Background0x" surfHex " c" dim, I18n.t("editor.cancel"))
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

                trigger := Trim(aaPrefix.Value) . catLetter . key
                sc["triggerKeys"] := trigger
                Database.Update(sc["id"], sc)
                poolIdx++
                assigned++
            }

            Database.Save()
            remapKeys := Config.GetRemapKeys()
            if (remapKeys.Length >= 2)
                RemapManager.AssignAll(remapKeys)
            gui.Destroy()
            this._RefreshView()
            MsgBox(assigned I18n.t("msg.assigned1") prog I18n.t("msg.assigned2"), "Key Atlas")
        }

        agui.Show("AutoSize Center")
    }

    ; ==========================================================
    ; Import / Export
    ; ==========================================================

    static _ExportShortcuts() {
        savePath := FileSelect("S16", A_Desktop . "\keyatlas_shortcuts.json",
            I18n.t("msg.export_filter"))
        if (savePath = "")
            return
        try {
            Json.Save(savePath, Database.ExportAll(), 2)
            MsgBox(I18n.t("msg.export_ok"), "Key Atlas")
        } catch as err {
            MsgBox(I18n.t("msg.export_err") err.Message, "Key Atlas", "IconX")
        }
    }

    static _ImportShortcuts() {
        filePath := FileSelect(1, A_Desktop, I18n.t("msg.import_title"),
            I18n.t("msg.export_filter"))
        if (filePath = "")
            return

        data := ""
        try {
            data := Json.Load(filePath)
        } catch as err {
            MsgBox(I18n.t("msg.import_err") err.Message, "Key Atlas", "IconX")
            return
        }

        imported := Array()
        if (data is Map && data.Has("shortcuts"))
            imported := data["shortcuts"]
        else if (data is Array)
            imported := data
        else {
            MsgBox(I18n.t("msg.import_no_valid"), "Key Atlas", "Icon!")
            return
        }

        if (imported.Length = 0) {
            MsgBox(I18n.t("msg.import_no_valid"), "Key Atlas", "Icon!")
            return
        }

        ; Ask merge or replace
        choiceGui := Gui("+Owner" this.GuiObj.Hwnd, I18n.t("msg.import_title"))
        choiceGui.BackColor := Theme.ToBGR(Theme.BG())
        choiceGui.SetFont("s10", "Segoe UI")

        txt := Theme.TXT()
        acc := Theme.ACC()
        surfHex := Format("{:06X}", Theme.ToBGR(Theme.SURF()))

        choiceGui.SetFont("s10 c" txt)
        choiceGui.Add("Text", "xm y+15 w350 Center",
            imported.Length I18n.t("msg.import_found"))

        choiceGui.SetFont("s10 bold c" acc)
        mergeBtn := choiceGui.Add("Button",
            "xm y+15 w150 h35 Background0x" surfHex, I18n.t("msg.import_merge"))
        replaceBtn := choiceGui.Add("Button",
            "x+10 yp w150 h35 Background0x" surfHex, I18n.t("msg.import_replace"))
        cancelBtn := choiceGui.Add("Button",
            "x+10 yp w100 h35 Background0x" surfHex " c" Theme.TXTDIM(),
            I18n.t("msg.import_cancel"))

        mergeBtn.OnEvent("Click", (*) => DoImport(choiceGui, false))
        replaceBtn.OnEvent("Click", (*) => DoImport(choiceGui, true))
        cancelBtn.OnEvent("Click", (*) => choiceGui.Destroy())
        choiceGui.OnEvent("Escape", (*) => choiceGui.Destroy())

        DoImport(gui, replace) {
            if (replace)
                Database.ImportAll(Map("shortcuts", Array()))

            existing := Database.GetAll()
            existingKeys := Map()
            for sc in existing {
                trig := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
                prog := sc.Has("program") ? sc["program"] : ""
                key := trig "|" prog
                existingKeys[key] := true
            }

            count := 0
            for sc in imported {
                trig := sc.Has("triggerKeys") ? sc["triggerKeys"] : ""
                prog := sc.Has("program") ? sc["program"] : ""
                key := trig "|" prog
                if (!existingKeys.Has(key)) {
                    sc["id"] := ""
                    Database.Add(sc)
                    existingKeys[key] := true
                    count++
                }
            }

            Database.Save()
            configuredRemapKeys := Config.GetRemapKeys()
            if (configuredRemapKeys.Length >= 2
                && RemapManager.AssignAll(configuredRemapKeys) < 0) {
                RemapManager.ClearAssignments()
                gui.Destroy()
                this._RefreshView()
                MsgBox(I18n.t("msg.remap_pool_capacity"), "Key Atlas", "Icon!")
                this.ShowRemapSetup()
                return
            }
            gui.Destroy()
            this._RefreshView()

            if (replace)
                MsgBox(imported.Length I18n.t("msg.imported_replace"), "Key Atlas")
            else
                MsgBox(count I18n.t("msg.imported_merge"), "Key Atlas")
        }

        choiceGui.Show("AutoSize Center")
    }
}
