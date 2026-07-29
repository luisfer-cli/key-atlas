; ============================================================
; I18n.ahk - Internationalization (EN / ES)
; ============================================================

class I18n {
    static Strings := Map()
    static Lang := "en"

    static Init() {
        this.Lang := Config.Get("lang", "en")
        if (this.Lang != "en" && this.Lang != "es")
            this.Lang := "en"

        ; ── English ──
        this.Strings["en"] := Map(
            ; System tray
            "tray.title",    "Key Atlas - Keyboard Shortcuts",
            "tray.trigger",  "Trigger: ",
            "tray.mode",     "Mode: ",

            ; Tray menu
            "menu.open",     "Open Settings",
            "menu.cheatsheet", "Cheatsheet Mode",
            "menu.remap",    "Remap Mode",
            "menu.reload_db","Reload Database",
            "menu.reload_cfg","Reload Settings",
            "menu.about",    "About Key Atlas",
            "menu.exit",     "Exit",

            ; Messages
            "msg.mode_changed",    "Mode changed to: ",
            "msg.db_reloaded",     "Database reloaded: ",
            "msg.shortcuts_count", " shortcuts.",
            "msg.cfg_reloaded",    "Settings reloaded.",

            ; About
            "about.title",   "Key Atlas - About",
            "about.body",    "Key Atlas v1.0.0`n`nUniversal keyboard shortcut assistant.`n`nFeatures:`n- Cheatsheet (which-key style)`n- Remap mode for direct execution`n- JSON configurable database`n- Multiple color themes`n- Auto-detect active program",

            ; GUI: toolbar
            "gui.title",          "Key Atlas - Settings",
            "toolbar.program",    "Program:",
            "toolbar.search",     "Search:",
            "toolbar.autoassign", "Assign Keys",
            "toolbar.settings",   "Settings",

            ; GUI: tree panel
            "tree.title",         "Categories by Program",

            ; GUI: shortcut list
            "list.title",         "Shortcuts",
            "col.trigger",        "Trigger",
            "col.desc",           "Description",
            "col.target",         "Target",
            "col.process",        "Process",
            "col.category",       "Category",
            "col.mode",           "Mode",
            "btn.new",            "New Shortcut",
            "btn.edit",           "Edit",
            "btn.delete",         "Delete",
            "footer.dblclick",    "Double-click to edit | ",
            "footer.total",       " shortcuts total",

            ; GUI: editor dialog
            "editor.title_new",   "Key Atlas - New Shortcut",
            "editor.title_edit",  "Key Atlas - Edit Shortcut",
            "editor.program",     "Program:",
            "editor.process",     "Process (.exe):",
            "editor.detect",      "Detect Active Window",
            "editor.category",    "Category:",
            "editor.desc",        "Description:",
            "editor.trigger",     "Trigger Keys:",
            "editor.target",      "Target Keys:",
            "editor.mode",        "Mode:",
            "editor.mode_remap",  "remap (execute shortcut)",
            "editor.mode_sheet",  "cheatsheet (show only)",
            "editor.save",        "Save",
            "editor.cancel",      "Cancel",
            "editor.hint",        "Combo: Ctrl+S | Sequential: g d | AHK: ^s +!f",

            ; GUI: settings dialog
            "settings.title",           "Key Atlas - Settings",
            "settings.hotkey",          "Activation Hotkey",
            "settings.combo",           "Combination:",
            "settings.apply",           "Apply",
            "settings.default_mode",    "Default Mode",
            "settings.mode_cheatsheet", "Cheatsheet (view shortcuts)",
            "settings.mode_remap",      "Remap (execute shortcuts)",
            "settings.theme",           "Color Theme",
            "settings.close",           "Close",

            ; GUI: auto-assign dialog
            "auto.title",              "Key Atlas - Auto-Assign",
            "auto.desc",               "Auto-generate shortcuts from a pool of keys",
            "auto.program",            "Program:",
            "auto.select",             "--- Select ---",
            "auto.category",           "Category:",
            "auto.all",                "--- All ---",
            "auto.keys",               "Available keys:",
            "auto.keys_hint",          "Comma-separated key list. Assigned in order.",
            "auto.prefix",             "Prefix:",
            "auto.cat_prefix",         "Category Prefixes (optional)",
            "auto.cat_prefix_hint",    "letter=category. Used as prefix in trigger keys.",
            "auto.generate",           "Generate Assignments",

            ; GUI: validation messages
            "msg.desc_required",    "Description is required.",
            "msg.trigger_required", "Trigger keys are required.",
            "msg.select_edit",      "Select a shortcut to edit.",
            "msg.select_delete",    "Select a shortcut to delete.",
            "msg.confirm_delete",   "Delete '",
            "msg.apply_hotkey",     "Hotkey updated.",
            "msg.apply_mode",       "Mode: ",
            "msg.apply_theme",      "Theme '",
            "msg.theme_restart",    "' applied. Window will restart.",
            "msg.press_valid",      "Press a valid key combination.",
            "msg.select_program",   "Select a program.",
            "msg.define_key",       "Define at least one available key.",
            "msg.no_shortcuts_for", "No shortcuts found for '",
            "msg.in_db",            "' in the database.",
            "msg.assigned1",        " shortcuts assigned for '",
            "msg.assigned2",        "'`nReview the generated triggers in the list.",

            ; Cheatsheet overlay
            "sheet.header",        "Key Atlas - ",
            "sheet.results",       " results)",
            "sheet.available",     " shortcuts available | Type to filter | Esc to close",
            "sheet.search",        "Search: ",
            "sheet.no_shortcuts",  "No shortcuts found.",
            "sheet.hint",          "Add shortcuts from Settings (right-click tray icon)",
            "sheet.footer",        " activate | [↑↓] navigate | [Enter] execute | [Esc] close",

            ; InputProcessor / Remap overlay
            "remap.title",         "Key Atlas - Remap Mode",
            "remap.waiting",       "Waiting for keys...",
            "remap.hint",          "Type the sequence or key combination",
            "remap.footer",        "[Esc] cancel  |  [trigger] activate again",
            "remap.found",         "Found: ",
            "remap.press_enter",   " [Enter to execute]",
            "remap.partial",       " partial matches...",
            "remap.no_match",      "No matches - [Esc] to cancel",
            "remap.err_target",    "Error: no target keys defined",
            "remap.err_prefix",    "Error: ",
            "remap.executed",      "Executed: ",

            ; General
            "program.all",         "--- All programs ---",
            "program.unnamed",     "Unnamed program",
            "category.general",    "General"
        )

        ; ── Spanish ──
        this.Strings["es"] := Map(
            "tray.title",    "Key Atlas - Asistente de Atajos",
            "tray.trigger",  "Trigger: ",
            "tray.mode",     "Modo: ",

            "menu.open",     "Abrir Configuracion",
            "menu.cheatsheet", "Modo Cheatsheet",
            "menu.remap",    "Modo Remap",
            "menu.reload_db","Recargar Base de Datos",
            "menu.reload_cfg","Recargar Configuracion",
            "menu.about",    "Acerca de Key Atlas",
            "menu.exit",     "Salir",

            "msg.mode_changed",    "Modo cambiado a: ",
            "msg.db_reloaded",     "Base de datos recargada: ",
            "msg.shortcuts_count", " atajos.",
            "msg.cfg_reloaded",    "Configuracion recargada.",

            "about.title",   "Key Atlas - Acerca de",
            "about.body",    "Key Atlas v1.0.0`n`nAsistente de atajos de teclado universal.`n`nFuncionalidades:`n- Cheatsheet estilo which-key`n- Modo remap para ejecutar atajos`n- Base de datos JSON configurable`n- Multiples temas de color`n- Deteccion automatica de programa activo",

            "gui.title",          "Key Atlas - Configuracion",
            "toolbar.program",    "Programa:",
            "toolbar.search",     "Buscar:",
            "toolbar.autoassign", "Asignar Teclas",
            "toolbar.settings",   "Ajustes",

            "tree.title",         "Categorias por Programa",

            "list.title",         "Atajos",
            "col.trigger",        "Trigger",
            "col.desc",           "Descripcion",
            "col.target",         "Target",
            "col.process",        "Proceso",
            "col.category",       "Categoria",
            "col.mode",           "Modo",
            "btn.new",            "Nuevo Atajo",
            "btn.edit",           "Editar",
            "btn.delete",         "Eliminar",
            "footer.dblclick",    "Doble click para editar | ",
            "footer.total",       " atajos en total",

            "editor.title_new",   "Key Atlas - Nuevo Atajo",
            "editor.title_edit",  "Key Atlas - Editar Atajo",
            "editor.program",     "Programa:",
            "editor.process",     "Proceso (.exe):",
            "editor.detect",      "Detectar Ventana Activa",
            "editor.category",    "Categoria:",
            "editor.desc",        "Descripcion:",
            "editor.trigger",     "Teclas Trigger:",
            "editor.target",      "Teclas Target:",
            "editor.mode",        "Modo:",
            "editor.mode_remap",  "remap (ejecuta atajo)",
            "editor.mode_sheet",  "cheatsheet (solo mostrar)",
            "editor.save",        "Guardar",
            "editor.cancel",      "Cancelar",
            "editor.hint",        "Combinacional: Ctrl+S | Secuencial: g d | AHK: ^s +!f",

            "settings.title",           "Key Atlas - Ajustes",
            "settings.hotkey",          "Hotkey de Activacion",
            "settings.combo",           "Combinacion:",
            "settings.apply",           "Aplicar",
            "settings.default_mode",    "Modo por Defecto",
            "settings.mode_cheatsheet", "Cheatsheet (ver atajos)",
            "settings.mode_remap",      "Remap (ejecutar atajos)",
            "settings.theme",           "Tema de Color",
            "settings.close",           "Cerrar",

            "auto.title",              "Key Atlas - Asignacion Automatica",
            "auto.desc",               "Generar atajos automaticamente a partir de un conjunto de teclas",
            "auto.program",            "Programa:",
            "auto.select",             "--- Seleccionar ---",
            "auto.category",           "Categoria:",
            "auto.all",                "--- Todas ---",
            "auto.keys",               "Teclas disponibles:",
            "auto.keys_hint",          "Lista de teclas separadas por coma. Se asignaran en orden.",
            "auto.prefix",             "Prefijo:",
            "auto.cat_prefix",         "Prefijos por Categoria (opcional)",
            "auto.cat_prefix_hint",    "letra=nombre_categoria. Se usara como prefijo en las teclas trigger.",
            "auto.generate",           "Generar Asignaciones",

            "msg.desc_required",    "La descripcion es obligatoria.",
            "msg.trigger_required", "Las teclas trigger son obligatorias.",
            "msg.select_edit",      "Selecciona un atajo para editar.",
            "msg.select_delete",    "Selecciona un atajo para eliminar.",
            "msg.confirm_delete",   "Eliminar '",
            "msg.apply_hotkey",     "Hotkey actualizado.",
            "msg.apply_mode",       "Modo: ",
            "msg.apply_theme",      "Tema '",
            "msg.theme_restart",    "' aplicado. La ventana se reiniciara.",
            "msg.press_valid",      "Presiona una combinacion valida.",
            "msg.select_program",   "Selecciona un programa.",
            "msg.define_key",       "Define al menos una tecla disponible.",
            "msg.no_shortcuts_for", "No hay atajos para '",
            "msg.in_db",            "' en la base de datos.",
            "msg.assigned1",        " atajos asignados para '",
            "msg.assigned2",        "'`nRevisa los triggers generados en la lista.",

            "sheet.header",        "Key Atlas - ",
            "sheet.results",       " resultados)",
            "sheet.available",     " atajos disponibles | Escribe para filtrar | Esc para cerrar",
            "sheet.search",        "Buscar: ",
            "sheet.no_shortcuts",  "No se encontraron atajos.",
            "sheet.hint",          "Agrega atajos desde la configuracion (click derecho en el icono de bandeja)",
            "sheet.footer",        " activar | [↑↓] navegar | [Enter] ejecutar | [Esc] cerrar",

            "remap.title",         "Key Atlas - Modo Remap",
            "remap.waiting",       "Esperando teclas...",
            "remap.hint",          "Escribe la secuencia o combinacion de teclas",
            "remap.footer",        "[Esc] cancelar  |  [trigger] activar de nuevo",
            "remap.found",         "Encontrado: ",
            "remap.press_enter",   " [Enter para ejecutar]",
            "remap.partial",       " coincidencias parciales...",
            "remap.no_match",      "Sin coincidencias - [Esc] para cancelar",
            "remap.err_target",    "Error: sin teclas destino definidas",
            "remap.err_prefix",    "Error: ",
            "remap.executed",      "Ejecutado: ",

            "program.all",         "--- Todos los programas ---",
            "program.unnamed",     "Sin programa",
            "category.general",    "General"
        )
    }

    static t(key) {
        if (this.Strings.Has(this.Lang) && this.Strings[this.Lang].Has(key))
            return this.Strings[this.Lang][key]
        ; fallback to English
        if (this.Strings.Has("en") && this.Strings["en"].Has(key))
            return this.Strings["en"][key]
        return key
    }
}
