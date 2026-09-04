; ============================================================
; RemapManager.ahk - Remap key pools and sequence assignment
; ============================================================

class RemapManager {
    static ParseKeyPool(value) {
        source := value is Array ? value : StrSplit(StrReplace(value, ",", " "), " ")
        keys := Array()
        seen := Map()

        for rawKey in source {
            key := this.NormalizeKey(rawKey)
            if (key = "" || !this.IsConfigurableKey(key) || seen.Has(key))
                continue
            seen[key] := true
            keys.Push(key)
        }
        return keys
    }

    static ParseSequence(value) {
        source := value is Array ? value : StrSplit(StrReplace(value, ",", " "), " ")
        result := Array()
        for rawKey in source {
            key := this.NormalizeKey(rawKey)
            if (key != "")
                result.Push(key)
        }
        return result
    }

    static NormalizeKey(key) {
        key := StrLower(Trim(String(key)))
        switch key {
            case "escape", "esc", "enter", "return", "backspace", "bs":
                return ""
            case "pgup", "pageup":
                return "pgup"
            case "pgdn", "pagedown":
                return "pgdn"
            case "control", "lcontrol", "rcontrol":
                return "ctrl"
        }
        return key
    }

    static IsConfigurableKey(key) {
        key := this.NormalizeKey(key)
        if (key = "" || key = "ctrl" || key = "alt" || key = "shift"
            || key = "lwin" || key = "rwin" || key = "lshift" || key = "rshift"
            || key = "lalt" || key = "ralt" || key = "lctrl" || key = "rctrl")
            return false
        vk := 0
        sc := 0
        try vk := GetKeyVK(key)
        try sc := GetKeySC(key)
        return vk != 0 || sc != 0
    }

    static FormatSequence(value) {
        sequence := this.ParseSequence(value)
        display := ""
        for key in sequence
            display .= (display = "" ? "" : " ") . key
        return display
    }

    static SequenceKey(value) {
        sequence := this.ParseSequence(value)
        result := ""
        for key in sequence
            result .= (result = "" ? "" : "|") . key
        return result
    }

    static IsSequenceAllowed(sequence, keyPool) {
        allowed := Map()
        for key in this.ParseKeyPool(keyPool)
            allowed[key] := true
        for key in this.ParseSequence(sequence) {
            if (!allowed.Has(key))
                return false
        }
        return this.ParseSequence(sequence).Length > 0
    }

    static FindConflict(processName, sequence, excludeId := "") {
        wanted := this.ParseSequence(sequence)
        processName := StrLower(Trim(processName))
        if (wanted.Length = 0 || processName = "")
            return ""

        for shortcut in Database.GetAll() {
            id := shortcut.Has("id") ? shortcut["id"] : ""
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            if (id != excludeId && process = processName && mode = "remap"
                && shortcut.Has("remapKeys")) {
                existing := this.ParseSequence(shortcut["remapKeys"])
                if (existing.Length = 0)
                    continue
                if (this._IsPrefix(wanted, existing) || this._IsPrefix(existing, wanted))
                    return shortcut
            }
        }
        return ""
    }

    static FindAvailableSequence(processName, keyPool) {
        keys := this.ParseKeyPool(keyPool)
        if (keys.Length < 2)
            return Array()
        existing := Array()
        for shortcut in this.GetForProcess(processName)
            existing.Push(this.ParseSequence(shortcut["remapKeys"]))

        queue := Array()
        for key in keys
            queue.Push([key])
        while (queue.Length > 0) {
            candidate := queue.RemoveAt(1)
            if (this._IsCompatibleSequence(candidate, existing))
                return candidate
            if (candidate.Length < Config.GetRemapMaxKeys()) {
                for key in keys {
                    child := candidate.Clone()
                    child.Push(key)
                    queue.Push(child)
                }
            }
        }
        return Array()
    }

    static _IsCompatibleSequence(candidate, existing) {
        for sequence in existing {
            if (this._IsPrefix(candidate, sequence) || this._IsPrefix(sequence, candidate))
                return false
        }
        return true
    }

    static _IsPrefix(prefix, sequence) {
        if (prefix.Length > sequence.Length)
            return false
        for index, key in prefix {
            if (sequence[index] != key)
                return false
        }
        return true
    }

    static GetForProcess(processName) {
        processName := StrLower(Trim(processName))
        results := Array()
        for shortcut in Database.GetAll() {
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            if (process = processName && mode = "remap" && shortcut.Has("remapKeys")
                && this.ParseSequence(shortcut["remapKeys"]).Length > 0)
                results.Push(shortcut)
        }
        return results
    }

    static HasAssignments() {
        for shortcut in Database.GetAll() {
            if (shortcut.Has("remapKeys") && this.ParseSequence(shortcut["remapKeys"]).Length > 0)
                return true
        }
        return false
    }

    static AssignmentsAreComplete(keyPool) {
        keys := this.ParseKeyPool(keyPool)
        if (keys.Length < 2)
            return false
        byProcess := Map()
        for shortcut in Database.GetAll() {
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            if (mode != "remap" || process = "")
                continue
            if (!shortcut.Has("remapKeys"))
                return false
            sequence := this.ParseSequence(shortcut["remapKeys"])
            if (sequence.Length = 0 || sequence.Length > Config.GetRemapMaxKeys()
                || !this.IsSequenceAllowed(sequence, keys))
                return false
            if (!byProcess.Has(process))
                byProcess[process] := Array()
            for existing in byProcess[process] {
                if (this._IsPrefix(sequence, existing) || this._IsPrefix(existing, sequence))
                    return false
            }
            byProcess[process].Push(sequence)
        }
        return true
    }

    static AssignAll(keyPool) {
        keys := this.ParseKeyPool(keyPool)
        if (keys.Length < 2) {
            this.ClearAssignments()
            return 0
        }
        if (!this.CanAssignAll(keys))
            return -1

        groups := Map()
        for shortcut in Database.GetAll() {
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            if (mode != "remap" || process = "")
                continue
            if (!groups.Has(process))
                groups[process] := Array()
            groups[process].Push(shortcut)
        }

        assigned := 0
        for _, shortcuts in groups {
            sequences := this._GeneratePrefixFreeSequences(shortcuts.Length, keys)
            for index, shortcut in shortcuts {
                shortcut["remapKeys"] := sequences[index]
                assigned++
            }
        }
        Database.Save()
        return assigned
    }

    static CanAssignProcess(processName, keyPool, additionalCount := 0) {
        keys := this.ParseKeyPool(keyPool)
        if (keys.Length < 2)
            return false
        capacity := 1
        loop Config.GetRemapMaxKeys()
            capacity *= keys.Length

        processName := StrLower(Trim(processName))
        count := additionalCount
        for shortcut in Database.GetAll() {
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            if (process = processName && mode = "remap")
                count++
        }
        return count <= capacity
    }

    static AssignProcess(processName, keyPool) {
        keys := this.ParseKeyPool(keyPool)
        if (!this.CanAssignProcess(processName, keys))
            return -1
        processName := StrLower(Trim(processName))
        shortcuts := Array()
        for shortcut in Database.GetAll() {
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            if (process = processName && mode = "remap")
                shortcuts.Push(shortcut)
        }
        sequences := this._GeneratePrefixFreeSequences(shortcuts.Length, keys)
        for index, shortcut in shortcuts
            shortcut["remapKeys"] := sequences[index]
        Database.Save()
        return shortcuts.Length
    }

    static ClearAssignments() {
        changed := false
        for shortcut in Database.GetAll() {
            if (shortcut.Has("remapKeys")) {
                shortcut["remapKeys"] := Array()
                changed := true
            }
        }
        if (changed)
            Database.Save()
    }

    static CanAssignAll(keyPool) {
        keys := this.ParseKeyPool(keyPool)
        if (keys.Length < 2)
            return false
        capacity := 1
        loop Config.GetRemapMaxKeys()
            capacity *= keys.Length

        groups := Map()
        for shortcut in Database.GetAll() {
            mode := shortcut.Has("mode") ? shortcut["mode"] : "remap"
            process := StrLower(Trim(shortcut.Has("process") ? shortcut["process"] : ""))
            if (mode != "remap" || process = "")
                continue
            groups[process] := groups.Has(process) ? groups[process] + 1 : 1
            if (groups[process] > capacity)
                return false
        }
        return true
    }

    static _GeneratePrefixFreeSequences(count, keys) {
        leaves := Array()
        for key in keys
            leaves.Push([key])

        while (leaves.Length < count) {
            prefix := leaves.RemoveAt(1)
            if (prefix.Length >= Config.GetRemapMaxKeys())
                return Array()
            for key in keys {
                child := prefix.Clone()
                child.Push(key)
                leaves.Push(child)
            }
        }
        return leaves
    }
}
