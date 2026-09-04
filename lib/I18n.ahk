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
            "menu.open",     "Open Shortcut Library",
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
            "gui.title",          "Key Atlas - Shortcut Library",
            "gui.library",        "Shortcut Library",
            "gui.subtitle",       "Find, organize and launch every command from one place.",
            "toolbar.program",    "Program:",
            "toolbar.search",     "Search:",
            "toolbar.search_hint","Search shortcuts...",
            "toolbar.autoassign", "Assign Keys",
            "toolbar.import",     "Import",
            "toolbar.export",     "Export",
            "toolbar.more",       "More actions",
            "toolbar.settings",   "Settings",

            ; GUI: tree panel
            "tree.title",         "LIBRARY",

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
            "footer.visible",     "visible",
            "footer.total_short", "total",
            "footer.hint",        "Double-click a shortcut to edit",

            ; GUI: editor dialog
            "editor.title_new",   "Key Atlas - New Shortcut",
            "editor.title_edit",  "Key Atlas - Edit Shortcut",
            "editor.heading_new", "Create a shortcut",
            "editor.heading_edit","Edit shortcut",
            "editor.subtitle",    "Define where it is available, how it is triggered and what it does.",
            "editor.section_app", "APPLICATION",
            "editor.section_shortcut", "SHORTCUT DETAILS",
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
            "settings.heading",         "Preferences",
            "settings.subtitle",        "Customize how Key Atlas opens, looks and responds.",
            "settings.section_behavior","BEHAVIOR",
            "settings.section_appearance", "APPEARANCE",
            "settings.section_overlay", "OVERLAY",
            "settings.hotkey",          "Activation Hotkey",
            "settings.combo",           "Combination:",
            "settings.apply",           "Apply",
            "settings.default_mode",    "Default Mode",
            "settings.mode_cheatsheet", "Cheatsheet (view shortcuts)",
            "settings.mode_remap",      "Remap (execute shortcuts)",
            "settings.theme",           "Color Theme",
            "settings.lang",            "Language",
            "settings.lang_en",         "English",
            "settings.lang_es",         "Spanish",
            "settings.close",           "Close",
            "settings.save",            "Save changes",
            "settings.max_items",       "Visible shortcuts:",
            "settings.opacity",         "Overlay opacity:",
            "settings.timeout",         "Remap timeout (sec):",

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
            "msg.target_required",  "Target keys are required for executable shortcuts.",
            "msg.timeout_range",    "Remap timeout must be between 0.5 and 10 seconds.",
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

            ; Import / Export
            "msg.export_ok",        "Shortcuts exported successfully.",
            "msg.export_err",       "Error exporting: ",
            "msg.import_title",     "Import Shortcuts",
            "msg.import_merge",     "Merge (add to existing)",
            "msg.import_replace",   "Replace (clear all first)",
            "msg.import_cancel",    "Cancel",
            "msg.imported_merge",   " imported shortcuts added.",
            "msg.imported_replace", " shortcuts imported (database replaced).",
            "msg.import_err",       "Error importing: ",
            "msg.import_no_valid",  "No valid shortcuts found in the file.",
            "msg.import_found",     " shortcuts found. Choose method:",
            "msg.export_filter",    "JSON (*.json)",

            ; Cheatsheet overlay
            "sheet.header",        "Key Atlas - ",
            "sheet.title",         "Command palette",
            "sheet.context",       "Shortcuts available for ",
            "sheet.search_empty",  "Type to filter shortcuts...",
            "sheet.showing",       "shown of",
            "sheet.reference",     "reference",
            "sheet.reference_notice", "This shortcut is for reference only.",
            "sheet.results",       " results)",
            "sheet.available",     " shortcuts available | Type to filter | Esc to close",
            "sheet.search",        "Search: ",
            "sheet.no_shortcuts",  "No shortcuts found.",
            "sheet.hint",          "Press Ctrl+N to add a shortcut for this program",
            "sheet.footer",        " activate | [↑↓] navigate | [Enter] execute | [Esc] close | [Ctrl+N] new",

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
            "category.general",    "General",

            ; Quick new shortcut from overlays
            "quick.new_title",     "Key Atlas - Quick New Shortcut",
            "quick.keys_captured", "Keys captured: ",
            "quick.target_prompt", "Target keys (AHK format):",
            "quick.cancel",        "Cancel"
        )

        ; ── Spanish ──
        this.Strings["es"] := Map(
            "tray.title",    "Key Atlas - Asistente de Atajos",
            "tray.trigger",  "Trigger: ",
            "tray.mode",     "Modo: ",

            "menu.open",     "Abrir Biblioteca de Atajos",
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

            "gui.title",          "Key Atlas - Biblioteca de Atajos",
            "gui.library",        "Biblioteca de atajos",
            "gui.subtitle",       "Encuentra, organiza y ejecuta todos tus comandos desde un solo lugar.",
            "toolbar.program",    "Programa:",
            "toolbar.search",     "Buscar:",
            "toolbar.search_hint","Buscar atajos...",
            "toolbar.autoassign", "Asignar Teclas",
            "toolbar.import",     "Importar",
            "toolbar.export",     "Exportar",
            "toolbar.more",       "Mas acciones",
            "toolbar.settings",   "Ajustes",

            "tree.title",         "BIBLIOTECA",

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
            "footer.visible",     "visibles",
            "footer.total_short", "total",
            "footer.hint",        "Doble clic para editar un atajo",

            "editor.title_new",   "Key Atlas - Nuevo Atajo",
            "editor.title_edit",  "Key Atlas - Editar Atajo",
            "editor.heading_new", "Crear un atajo",
            "editor.heading_edit","Editar atajo",
            "editor.subtitle",    "Define donde esta disponible, como se activa y que accion realiza.",
            "editor.section_app", "APLICACION",
            "editor.section_shortcut", "DETALLES DEL ATAJO",
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
            "settings.heading",         "Preferencias",
            "settings.subtitle",        "Personaliza como se abre, se ve y responde Key Atlas.",
            "settings.section_behavior","COMPORTAMIENTO",
            "settings.section_appearance", "APARIENCIA",
            "settings.section_overlay", "OVERLAY",
            "settings.hotkey",          "Hotkey de Activacion",
            "settings.combo",           "Combinacion:",
            "settings.apply",           "Aplicar",
            "settings.default_mode",    "Modo por Defecto",
            "settings.mode_cheatsheet", "Cheatsheet (ver atajos)",
            "settings.mode_remap",      "Remap (ejecutar atajos)",
            "settings.theme",           "Tema de Color",
            "settings.lang",            "Idioma",
            "settings.lang_en",         "Ingles",
            "settings.lang_es",         "Espanol",
            "settings.close",           "Cerrar",
            "settings.save",            "Guardar cambios",
            "settings.max_items",       "Atajos visibles:",
            "settings.opacity",         "Opacidad del overlay:",
            "settings.timeout",         "Espera remap (seg):",

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
            "msg.target_required",  "Las teclas destino son obligatorias para atajos ejecutables.",
            "msg.timeout_range",    "La espera de remap debe estar entre 0.5 y 10 segundos.",
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

            "msg.export_ok",        "Atajos exportados correctamente.",
            "msg.export_err",       "Error al exportar: ",
            "msg.import_title",     "Importar Atajos",
            "msg.import_merge",     "Combinar (agregar a existentes)",
            "msg.import_replace",   "Reemplazar (borrar todo primero)",
            "msg.import_cancel",    "Cancelar",
            "msg.imported_merge",   " atajos importados agregados.",
            "msg.imported_replace", " atajos importados (base reemplazada).",
            "msg.import_err",       "Error al importar: ",
            "msg.import_no_valid",  "No se encontraron atajos validos en el archivo.",
            "msg.import_found",     " atajos encontrados. Elige metodo:",
            "msg.export_filter",    "JSON (*.json)",

            "sheet.header",        "Key Atlas - ",
            "sheet.title",         "Paleta de comandos",
            "sheet.context",       "Atajos disponibles para ",
            "sheet.search_empty",  "Escribe para filtrar atajos...",
            "sheet.showing",       "mostrados de",
            "sheet.reference",     "referencia",
            "sheet.reference_notice", "Este atajo es solo de referencia.",
            "sheet.results",       " resultados)",
            "sheet.available",     " atajos disponibles | Escribe para filtrar | Esc para cerrar",
            "sheet.search",        "Buscar: ",
            "sheet.no_shortcuts",  "No se encontraron atajos.",
            "sheet.hint",          "Pulsa Ctrl+N para agregar un atajo a este programa",
            "sheet.footer",        " activar | [↑↓] navegar | [Enter] ejecutar | [Esc] cerrar | [Ctrl+N] nuevo",

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
            "category.general",    "General",

            "quick.new_title",     "Key Atlas - Nuevo Atajo Rapido",
            "quick.keys_captured", "Teclas capturadas: ",
            "quick.target_prompt", "Teclas destino (formato AHK):",
            "quick.cancel",        "Cancelar"
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
