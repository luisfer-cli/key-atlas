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

        themeColors := this.Presets[themeName]
        for key, val in themeColors
            Config.Set("colors." . key, val)

        Config.SetTheme(themeName)
        Config.Save()
        return true
    }

    static GetCurrent() {
        if (Config.GetTheme() = "system")
            return this._ReadSystemColors()
        return Config.GetColors()
    }

    static GetPreset(name) {
        if (name = "system")
            return this._ReadSystemColors()
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

    ; Convert hex color to BGR for AHK Gui (0xBBGGRR)
    static ToBGR(hexColor) {
        hexColor := StrReplace(hexColor, "#", "")
        if (StrLen(hexColor) = 6)
            return Integer("0x" SubStr(hexColor, 5, 2) . SubStr(hexColor, 3, 2) . SubStr(hexColor, 1, 2))
        return 0x000000
    }

    ; ==========================================================
    ; System color detection (reads live Windows colors)
    ; ==========================================================

    static _ReadSystemColors() {
        ; OS color indices via SysGet:
        ;  5 = COLOR_WINDOW          (window background)
        ;  8 = COLOR_WINDOWTEXT      (window text)
        ; 13 = COLOR_HIGHLIGHT       (selected item bg)
        ; 14 = COLOR_HIGHLIGHTTEXT   (selected item text)
        ; 15 = COLOR_3DFACE          (button face / dialog bg)
        ; 16 = COLOR_3DSHADOW        (shadow / border)
        ; 17 = COLOR_GRAYTEXT        (dimmed text)

        bg := Format("{:06X}", SysGet(15))        ; button face = dialog bg
        fg := Format("{:06X}", SysGet(8))         ; window text
        hl := Format("{:06X}", SysGet(13))        ; highlight
        hlText := Format("{:06X}", SysGet(14))    ; highlight text
        shadow := Format("{:06X}", SysGet(16))    ; border/shadow
        window := Format("{:06X}", SysGet(5))     ; window bg (whiter)
        dim := Format("{:06X}", SysGet(17))       ; gray text

        ; Detect dark mode from registry for accent choice
        isLight := true
        try {
            appsLight := RegRead(
                "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                "AppsUseLightTheme")
            isLight := appsLight != 0
        }

        accent := isLight ? "005FB8" : "60CDFF"
        overlay := bg  ; overlay matches dialog bg

        return Map(
            "background",  bg,
            "foreground",  fg,
            "accent",      accent,
            "highlight",   hl,
            "border",      shadow,
            "surface",     window,
            "overlay",     overlay,
            "success",     isLight ? "0F7B0F" : "3BDA3B",
            "warning",     isLight ? "D83B01" : "FF9100",
            "error",       isLight ? "C50500" : "FF5252",
            "text",        fg,
            "textDim",     dim,
            "textBright",  hlText
        )
    }

    ; ==========================================================
    ; Presets
    ; ==========================================================

    static _RegisterPresets() {
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
