; ============================================================
; Config.ahk - Configuration Management
; ============================================================

class Config {
    static FilePath := ""
    static Data := Map()

    static Init() {
        this.FilePath := A_ScriptDir . "\config\settings.json"
        if (FileExist(this.FilePath)) {
            try {
                this.Data := Json.Load(this.FilePath)
            } catch as err {
                this._CreateDefault()
            }
        } else {
            this._CreateDefault()
        }
        return this
    }

    static Reload() {
        this.Init()
    }

    static Save() {
        Json.Save(this.FilePath, this.Data, 2)
    }

    ; Get a value with dot-notation: "colors.background", "theme"
    static Get(path, defaultVal := "") {
        parts := StrSplit(path, ".")
        current := this.Data
        for part in parts {
            if (current is Map && current.Has(part))
                current := current[part]
            else
                return defaultVal
        }
        return current
    }

    ; Set a value with dot-notation
    static Set(path, value) {
        parts := StrSplit(path, ".")
        current := this.Data
        for i, part in parts {
            if (i = parts.Length) {
                current[part] := value
                break
            }
            if (!current.Has(part) || !(current[part] is Map))
                current[part] := Map()
            current := current[part]
        }
    }

    ; Get all colors as a flat map
    static GetColors() {
        colors := this.Get("colors", Map())
        result := Map()
        if (colors is Map) {
            for key, val in colors
                result[key] := val
        }
        return result
    }

    ; Set all colors from a flat map
    static SetColors(colorMap) {
        for key, val in colorMap
            this.Set("colors." . key, val)
    }

    static GetTriggerHotkey() {
        return this.Get("triggerHotkey", "^+Space")
    }

    static SetTriggerHotkey(hotkey) {
        this.Set("triggerHotkey", hotkey)
    }

    static GetDefaultMode() {
        return this.Get("defaultMode", "cheatsheet")
    }

    static SetDefaultMode(mode) {
        this.Set("defaultMode", mode)
    }

    static GetTheme() {
        return this.Get("theme", "dark")
    }

    static SetTheme(theme) {
        this.Set("theme", theme)
    }

    static GetCheatsheetMaxItems() {
        return this.Get("cheatsheet.maxItems", 12)
    }

    static GetCheatsheetOpacity() {
        return this.Get("cheatsheet.overlayOpacity", 220)
    }

    static _CreateDefault() {
        this.Data := Map()
        this.Data["triggerHotkey"] := "^+Space"
        this.Data["defaultMode"] := "cheatsheet"
        this.Data["theme"] := "dark"
        this.Data["cheatsheet"] := Map(
            "maxItems", 12,
            "overlayOpacity", 220,
            "autoDetectProgram", true,
            "showCategories", true,
            "fontSize", 10
        )
        this.Data["remap"] := Map(
            "timeout", 2.0,
            "maxKeys", 6
        )
        this.Data["colors"] := Map(
            "background", "1E1E2E",
            "foreground", "CDD6F4",
            "accent", "89B4FA",
            "highlight", "45475A",
            "border", "585B70",
            "surface", "313244",
            "overlay", "11111B",
            "success", "A6E3A1",
            "warning", "F9E2AF",
            "error", "F38BA8",
            "text", "CDD6F4",
            "textDim", "6C7086",
            "textBright", "FFFFFF"
        )
        this.Save()
    }
}
