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
        if (!this.Presets.Has(themeName))
            return false

        themeColors := this.Presets[themeName]
        for key, val in themeColors
            Config.Set("colors." . key, val)

        Config.SetTheme(themeName)
        Config.Save()
        return true
    }

    static GetCurrent() {
        return Config.GetColors()
    }

    static GetPreset(name) {
        if (this.Presets.Has(name))
            return this.Presets[name]
        return Map()
    }

    static GetPresetNames() {
        names := Array()
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

    ; Convert hex color to BGR for AHK Gui (0xBBGGRR)
    static ToBGR(hexColor) {
        hexColor := StrReplace(hexColor, "#", "")
        if (StrLen(hexColor) = 6)
            return Integer("0x" SubStr(hexColor, 5, 2) . SubStr(hexColor, 3, 2) . SubStr(hexColor, 1, 2))
        return 0x000000
    }

    static _RegisterPresets() {
        ; ----- Catppuccin Mocha -----
        this.Presets["dark"] := Map(
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

        ; ----- Nord -----
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

        ; ----- Catppuccin Latte -----
        this.Presets["light"] := Map(
            "background", "EFF1F5",
            "foreground", "4C4F69",
            "accent", "1E66F5",
            "highlight", "CCD0DA",
            "border", "BCC0CC",
            "surface", "E6E9EF",
            "overlay", "DCE0E8",
            "success", "40A02B",
            "warning", "DF8E1D",
            "error", "D20F39",
            "text", "4C4F69",
            "textDim", "6C6F85",
            "textBright", "1E1E2E"
        )
    }
}
