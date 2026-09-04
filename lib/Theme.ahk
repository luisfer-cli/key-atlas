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
                "accent", "0078D4",
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

    static _RegisterPresets() {
        this.Presets["dark"] := Map(
            "background", "1F1F1F",
            "foreground", "CCCCCC",
            "accent", "0078D4",
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

        this.Presets["light"] := Map(
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

        this.Presets["Midnight Orchid"] := Map(
            "background", "11101A",
            "foreground", "D9D5E8",
            "accent", "A78BFA",
            "highlight", "3B2E5A",
            "border", "332D45",
            "surface", "1C1928",
            "overlay", "0C0B12",
            "success", "6EE7B7",
            "warning", "FCD34D",
            "error", "FB7185",
            "text", "D9D5E8",
            "textDim", "8E87A3",
            "textBright", "F8F7FF"
        )

        this.Presets["Aurora Borealis"] := Map(
            "background", "081411",
            "foreground", "C9E7DC",
            "accent", "2DD4BF",
            "highlight", "164E4A",
            "border", "285A52",
            "surface", "10241F",
            "overlay", "06100E",
            "success", "86EFAC",
            "warning", "FDE68A",
            "error", "FDA4AF",
            "text", "C9E7DC",
            "textDim", "72A397",
            "textBright", "ECFDF5"
        )

        this.Presets["Rose Quartz"] := Map(
            "background", "1A1116",
            "foreground", "F0D9E3",
            "accent", "F472B6",
            "highlight", "5B2945",
            "border", "533342",
            "surface", "2A1922",
            "overlay", "120B0F",
            "success", "A7F3D0",
            "warning", "FCD34D",
            "error", "FB7185",
            "text", "F0D9E3",
            "textDim", "A77D90",
            "textBright", "FFF5F9"
        )

        this.Presets["Solar Ember"] := Map(
            "background", "17120D",
            "foreground", "EADBC8",
            "accent", "F59E0B",
            "highlight", "5A3714",
            "border", "4D3825",
            "surface", "261C13",
            "overlay", "100C09",
            "success", "84CC16",
            "warning", "FBBF24",
            "error", "F87171",
            "text", "EADBC8",
            "textDim", "A28C73",
            "textBright", "FFF8ED"
        )

        this.Presets["Deep Ocean"] := Map(
            "background", "07131F",
            "foreground", "C9E5F2",
            "accent", "38BDF8",
            "highlight", "164E63",
            "border", "244A5D",
            "surface", "0E2233",
            "overlay", "050D15",
            "success", "5EEAD4",
            "warning", "FACC15",
            "error", "FB7185",
            "text", "C9E5F2",
            "textDim", "6F9BAE",
            "textBright", "F0F9FF"
        )
    }
}
