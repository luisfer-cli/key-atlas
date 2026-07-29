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
        ; ----- Catppuccin Mocha (default dark) -----
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

        ; ----- Nord Dark -----
        this.Presets["nord"] := Map(
            "background", "2E3440",
            "foreground", "D8DEE9",
            "accent", "88C0D0",
            "highlight", "4C566A",
            "border", "434C5E",
            "surface", "3B4252",
            "overlay", "242933",
            "success", "A3BE8C",
            "warning", "EBCB8B",
            "error", "BF616A",
            "text", "D8DEE9",
            "textDim", "7B88A1",
            "textBright", "ECEFF4"
        )

        ; ----- Gruvbox Dark -----
        this.Presets["gruvbox"] := Map(
            "background", "282828",
            "foreground", "EBDBB2",
            "accent", "83A598",
            "highlight", "504945",
            "border", "665C54",
            "surface", "3C3836",
            "overlay", "1D2021",
            "success", "B8BB26",
            "warning", "FABD2F",
            "error", "FB4934",
            "text", "EBDBB2",
            "textDim", "928374",
            "textBright", "FBF1C7"
        )

        ; ----- Tokyo Night -----
        this.Presets["tokyonight"] := Map(
            "background", "1A1B26",
            "foreground", "C0CAF5",
            "accent", "7AA2F7",
            "highlight", "364A82",
            "border", "565F89",
            "surface", "24283B",
            "overlay", "1A1B26",
            "success", "9ECE6A",
            "warning", "E0AF68",
            "error", "F7768E",
            "text", "C0CAF5",
            "textDim", "565F89",
            "textBright", "FFFFFF"
        )

        ; ----- Catppuccin Latte (light) -----
        this.Presets["light"] := Map(
            "background", "EFF1F5",
            "foreground", "4C4F69",
            "accent", "1E66F5",
            "highlight", "CCD0DA",
            "border", "9CA0B0",
            "surface", "E6E9EF",
            "overlay", "EFF1F5",
            "success", "40A02B",
            "warning", "DF8E1D",
            "error", "D20F39",
            "text", "4C4F69",
            "textDim", "8C8FA1",
            "textBright", "1E1E2E"
        )

        ; ----- Dracula -----
        this.Presets["dracula"] := Map(
            "background", "282A36",
            "foreground", "F8F8F2",
            "accent", "BD93F9",
            "highlight", "44475A",
            "border", "6272A4",
            "surface", "343746",
            "overlay", "21222C",
            "success", "50FA7B",
            "warning", "F1FA8C",
            "error", "FF5555",
            "text", "F8F8F2",
            "textDim", "6272A4",
            "textBright", "FFFFFF"
        )

        ; ----- Solarized Dark -----
        this.Presets["solarized"] := Map(
            "background", "002B36",
            "foreground", "839496",
            "accent", "268BD2",
            "highlight", "073642",
            "border", "586E75",
            "surface", "003847",
            "overlay", "001F28",
            "success", "859900",
            "warning", "B58900",
            "error", "DC322F",
            "text", "839496",
            "textDim", "586E75",
            "textBright", "FDF6E3"
        )
    }
}
