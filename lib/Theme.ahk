; ============================================================
; Theme.ahk - Theme Management with Presets
; ============================================================

class Theme {
    static Presets := Map()

    static Init() {
        this._RegisterPresets()
        return this
    }

    static Apply(themeName) {
        if (themeName = "system") {
            Config.SetTheme("system")
            Config.Save()
            return true
        }
        if (!this.Presets.Has(themeName))
            return false

        colors := this.Presets[themeName]
        for key, val in colors
            Config.Set("colors." . key, val)

        Config.SetTheme(themeName)
        Config.Save()
        return true
    }

    static GetCurrent() {
        if (Config.GetTheme() = "system")
            return this._GetSystemColors()
        return Config.GetColors()
    }

    static GetPreset(name) {
        if (name = "system")
            return this._GetSystemColors()
        if (this.Presets.Has(name))
            return this.Presets[name]
        return Map()
    }

    static GetPresetNames() {
        names := Array()
        names.Push("system")
        for name in this.Presets
            names.Push(name)
        return names
    }

    static GetColor(name) {
        current := this.GetCurrent()
        if (current.Has(name))
            return current[name]
        return "FFFFFF"
    }

    static BG() => this.GetColor("background")
    static FG() => this.GetColor("foreground")
    static ACC() => this.GetColor("accent")
    static HL() => this.GetColor("highlight")
    static BDR() => this.GetColor("border")
    static SURF() => this.GetColor("surface")
    static OVERLAY() => this.GetColor("overlay")
    static TXT() => this.GetColor("text")
    static TXTDIM() => this.GetColor("textDim")
    static TXTBRIGHT() => this.GetColor("textBright")

    static ToBGR(hexColor) {
        hexColor := StrReplace(hexColor, "#", "")
        if (StrLen(hexColor) = 6)
            return Integer("0x" SubStr(hexColor, 5, 2) . SubStr(hexColor, 3, 2) . SubStr(hexColor, 1, 2))
        return 0x000000
    }

    ; ==========================================================
    ; System color detection
    ; ==========================================================

    static _GetSystemColors() {
        dark := false
        try {
            val := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                "AppsUseLightTheme")
            dark := val = 0
        }

        if (dark) {
            return Map(
                "background", "1F1F1F",
                "foreground", "CCCCCC",
                "accent", "4F9BD8",
                "highlight", "264F78",
                "border", "3C3C3C",
                "surface", "2A2A2A",
                "overlay", "1F1F1F",
                "success", "4EC94E",
                "warning", "CCA700",
                "error", "F44747",
                "text", "CCCCCC",
                "textDim", "6A6A6A",
                "textBright", "FFFFFF"
            )
        }

        return Map(
            "background", "F0F0F0",
            "foreground", "000000",
            "accent", "005FB8",
            "highlight", "0078D4",
            "border", "B0B0B0",
            "surface", "FFFFFF",
            "overlay", "F0F0F0",
            "success", "0F7B0F",
            "warning", "D83B01",
            "error", "C50500",
            "text", "000000",
            "textDim", "6B6B6B",
            "textBright", "000000"
        )
    }

    ; ==========================================================
    ; Presets
    ; ==========================================================

    static _RegisterPresets() {
        this.Presets["dark"] := Map(
            "background", "1F1F1F",
            "foreground", "CCCCCC",
            "accent", "4F9BD8",
            "highlight", "264F78",
            "border", "3C3C3C",
            "surface", "2A2A2A",
            "overlay", "1F1F1F",
            "success", "4EC94E",
            "warning", "CCA700",
            "error", "F44747",
            "text", "CCCCCC",
            "textDim", "6A6A6A",
            "textBright", "FFFFFF"
        )

        this.Presets["nord"] := Map(
            "background", "2E3440",
            "foreground", "D8DEE9",
            "accent", "88C0D0",
            "highlight", "4C566A",
            "border", "434C5E",
            "surface", "3B4252",
            "overlay", "2E3440",
            "success", "A3BE8C",
            "warning", "EBCB8B",
            "error", "BF616A",
            "text", "D8DEE9",
            "textDim", "81A1C1",
            "textBright", "ECEFF4"
        )

        this.Presets["light"] := Map(
            "background", "F0F0F0",
            "foreground", "1F1F1F",
            "accent", "005FB8",
            "highlight", "0078D4",
            "border", "B0B0B0",
            "surface", "FFFFFF",
            "overlay", "F0F0F0",
            "success", "0F7B0F",
            "warning", "D83B01",
            "error", "C50500",
            "text", "1F1F1F",
            "textDim", "6B6B6B",
            "textBright", "000000"
        )
    }
}
