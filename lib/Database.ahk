; ============================================================
; Database.ahk - Shortcuts JSON Database CRUD
; ============================================================

class Database {
    static FilePath := ""
    static Data := Map()

    static Init() {
        this.FilePath := A_ScriptDir . "\data\shortcuts.json"
        if (FileExist(this.FilePath)) {
            try {
                this.Data := Json.Load(this.FilePath)
            } catch as err {
                this.Data := Map("shortcuts", Array())
                this.Save()
            }
        } else {
            this.Data := Map("shortcuts", Array())
            this.Save()
        }
        return this
    }

    static Reload() {
        this.Init()
    }

    static Save() {
        Json.Save(this.FilePath, this.Data, 2)
    }

    static GetAll() {
        if (!this.Data.Has("shortcuts"))
            this.Data["shortcuts"] := Array()
        return this.Data["shortcuts"]
    }

    static GetById(id) {
        for shortcut in this.GetAll() {
            if (shortcut.Has("id") && shortcut["id"] = id)
                return shortcut
        }
        return ""
    }

    ; Search shortcuts by program name (exact or partial match)
    static GetByProgram(processName) {
        results := Array()
        processName := StrLower(processName)
        for shortcut in this.GetAll() {
            proc := StrLower(shortcut.Has("process") ? shortcut["process"] : "")
            if (proc = "" || InStr(processName, proc) || InStr(proc, processName))
                results.Push(shortcut)
        }
        return results
    }

    ; Get shortcuts for the current active window
    static GetForActiveWindow() {
        activeProcess := WinGetProcessName("A")
        return this.GetByProgram(activeProcess)
    }

    ; Search by text in description, program name, trigger keys, or category
    static Search(query) {
        results := Array()
        query := StrLower(query)
        if (query = "")
            return this.GetAll()

        for shortcut in this.GetAll() {
            desc := StrLower(shortcut.Has("description") ? shortcut["description"] : "")
            prog := StrLower(shortcut.Has("program") ? shortcut["program"] : "")
            trig := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
            cat := StrLower(shortcut.Has("category") ? shortcut["category"] : "")
            proc := StrLower(shortcut.Has("process") ? shortcut["process"] : "")

            if (InStr(desc, query) || InStr(prog, query) || InStr(trig, query)
                || InStr(cat, query) || InStr(proc, query))
                results.Push(shortcut)
        }
        return results
    }

    ; Search by trigger keys prefix (for which-key style filtering)
    static SearchByTrigger(prefix, programOnly := true) {
        results := Array()
        prefix := StrLower(prefix)

        for shortcut in this.GetAll() {
            trig := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
            if (trig != "" && InStr(trig, prefix) = 1) {
                if (!programOnly || this._MatchesActiveWindow(shortcut))
                    results.Push(shortcut)
            }
        }
        return results
    }

    ; Fuzzy search across all fields
    static FuzzySearch(query, programOnly := true) {
        results := Array()
        if (query = "") {
            if (programOnly)
                return this.GetForActiveWindow()
            return this.GetAll()
        }

        candidates := programOnly ? this.GetForActiveWindow() : this.GetAll()

        for shortcut in candidates {
            trg := StrLower(shortcut.Has("triggerKeys") ? shortcut["triggerKeys"] : "")
            desc := StrLower(shortcut.Has("description") ? shortcut["description"] : "")
            query := StrLower(query)

            if (InStr(trg, query) = 1 || InStr(desc, query) = 1 || InStr(trg, query))
                results.Push(shortcut)
        }
        return results
    }

    static Add(shortcut) {
        if (!shortcut.Has("id") || shortcut["id"] = "")
            shortcut["id"] := this._GenerateId()
        this.GetAll().Push(shortcut)
        this.Save()
        return shortcut["id"]
    }

    static Update(id, updatedData) {
        all := this.GetAll()
        for i, shortcut in all {
            if (shortcut.Has("id") && shortcut["id"] = id) {
                for key, val in updatedData
                    shortcut[key] := val
                this.Save()
                return true
            }
        }
        return false
    }

    static Delete(id) {
        all := this.GetAll()
        for i, shortcut in all {
            if (shortcut.Has("id") && shortcut["id"] = id) {
                all.RemoveAt(i)
                this.Save()
                return true
            }
        }
        return false
    }

    ; Get unique categories from all shortcuts
    static GetCategories() {
        cats := Map()
        for shortcut in this.GetAll() {
            if (shortcut.Has("category") && shortcut["category"] != "") {
                cat := shortcut["category"]
                if (!cats.Has(cat))
                    cats[cat] := true
            }
        }
        result := Array()
        for cat in cats
            result.Push(cat)
        this._SortArray(&result)
        return result
    }

    ; Get unique program names from all shortcuts
    static GetPrograms() {
        progs := Map()
        for shortcut in this.GetAll() {
            if (shortcut.Has("program") && shortcut["program"] != "") {
                prog := shortcut["program"]
                if (!progs.Has(prog))
                    progs[prog] := true
            }
        }
        result := Array()
        for prog in progs
            result.Push(prog)
        this._SortArray(&result)
        return result
    }

    ; Group shortcuts by category for cheatsheet display
    static GroupByCategory(shortcuts) {
        groups := Map()
        for shortcut in shortcuts {
            cat := shortcut.Has("category") ? shortcut["category"] : "General"
            if (cat = "")
                cat := "General"
            if (!groups.Has(cat))
                groups[cat] := Array()
            groups[cat].Push(shortcut)
        }
        return groups
    }

    ; Export all data as plain AHK object for JSON serialization
    static ExportAll() {
        return this.Data
    }

    ; Import and replace all data
    static ImportAll(data) {
        this.Data := data
        this.Save()
    }

    static _GenerateId() {
        return Format("{:016x}{:016x}", A_TickCount, Random(0, 0xFFFFFFFF))
    }

    static _MatchesActiveWindow(shortcut) {
        if (!shortcut.Has("process") || shortcut["process"] = "")
            return false
        activeProcess := StrLower(WinGetProcessName("A"))
        proc := StrLower(shortcut["process"])
        return InStr(activeProcess, proc)
    }

    static _SortArray(&arr) {
        arrLen := arr.Length
        if (arrLen <= 1)
            return
        Loop arrLen - 1 {
            swapped := false
            Loop arrLen - A_Index {
                if (StrLower(arr[A_Index]) > StrLower(arr[A_Index + 1])) {
                    temp := arr[A_Index]
                    arr[A_Index] := arr[A_Index + 1]
                    arr[A_Index + 1] := temp
                    swapped := true
                }
            }
            if (!swapped)
                break
        }
    }
}
