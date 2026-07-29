; ============================================================
; Json.ahk - Pure AHK v2 JSON Parser and Stringifier
; ============================================================

class Json {
    ; Sentinel value to represent JSON null (unset deletes Map entries)
    class Null {
    }

    ; Parses a JSON string into AHK objects (Map/Array/String/Number)
    static Parse(jsonStr) {
        jsonStr := Trim(jsonStr)
        idx := 1
        result := this._ParseValue(&jsonStr, &idx)
        this._SkipWhitespace(&jsonStr, &idx)
        if (idx <= StrLen(jsonStr))
            throw Error("JSON parse error: unexpected trailing data at position " idx)
        return result
    }

    ; Converts AHK objects to a JSON string
    static Stringify(obj, indent := 0, level := 0) {
        if (obj = Json.Null)
            return "null"
        if (obj is Array)
            return this._StringifyArray(obj, indent, level)
        else if (obj is Map)
            return this._StringifyObject(obj, indent, level)
        else if (obj is String)
            return this._StringifyString(obj)
        else if (obj is Number) {
            if (obj is Integer)
                return String(obj)
            else
                return Format("{:g}", obj)
        } else if (IsObject(obj))
            throw Error("JSON stringify error: unsupported object type " Type(obj))
        else if (Type(obj) = "String")
            return this._StringifyString(obj)
        else if (Type(obj) = "Integer" || Type(obj) = "Float")
            return String(obj)
        else
            return this._StringifyString(String(obj))
    }

    ; ==========================================================
    ; Internal: Parse Methods
    ; ==========================================================

    static _ParseValue(&json, &idx) {
        this._SkipWhitespace(&json, &idx)
        if (idx > StrLen(json))
            throw Error("JSON parse error: unexpected end of input at position " idx)

        char := SubStr(json, idx, 1)

        if (char = "{")
            return this._ParseObject(&json, &idx)
        else if (char = "[")
            return this._ParseArray(&json, &idx)
        else if (char = '"')
            return this._ParseString(&json, &idx)
        else if (char = "t" || char = "f")
            return this._ParseBoolean(&json, &idx)
        else if (char = "n")
            return this._ParseNull(&json, &idx)
        else if (this._IsDigit(char) || char = "-")
            return this._ParseNumber(&json, &idx)
        else
            throw Error("JSON parse error: unexpected character '" char "' at position " idx)
    }

    static _ParseObject(&json, &idx) {
        idx++
        obj := Map()
        this._SkipWhitespace(&json, &idx)

        if (idx > StrLen(json))
            throw Error("JSON parse error: unterminated object")

        if (SubStr(json, idx, 1) = "}") {
            idx++
            return obj
        }

        Loop {
            this._SkipWhitespace(&json, &idx)
            key := this._ParseString(&json, &idx)
            this._SkipWhitespace(&json, &idx)

            if (SubStr(json, idx, 1) != ":")
                throw Error("JSON parse error: expected ':' at position " idx)
            idx++

            value := this._ParseValue(&json, &idx)
            obj[key] := value

            this._SkipWhitespace(&json, &idx)
            if (SubStr(json, idx, 1) = "}") {
                idx++
                return obj
            }
            if (SubStr(json, idx, 1) != ",")
                throw Error("JSON parse error: expected ',' or '}' at position " idx)
            idx++
        }
    }

    static _ParseArray(&json, &idx) {
        idx++
        arr := Array()
        this._SkipWhitespace(&json, &idx)

        if (SubStr(json, idx, 1) = "]") {
            idx++
            return arr
        }

        Loop {
            value := this._ParseValue(&json, &idx)
            arr.Push(value)
            this._SkipWhitespace(&json, &idx)

            if (SubStr(json, idx, 1) = "]") {
                idx++
                return arr
            }
            if (SubStr(json, idx, 1) != ",")
                throw Error("JSON parse error: expected ',' or ']' at position " idx)
            idx++
        }
    }

    static _ParseString(&json, &idx) {
        idx++
        result := ""
        len := StrLen(json)

        Loop {
            if (idx > len)
                throw Error("JSON parse error: unterminated string")

            char := SubStr(json, idx, 1)
            idx++

            if (char = '"')
                return result
            else if (char = "\") {
                if (idx > len)
                    throw Error("JSON parse error: unterminated escape sequence")
                esc := SubStr(json, idx, 1)
                idx++
                switch esc {
                    case '"': result .= '"'
                    case "\": result .= "\"
                    case "/": result .= "/"
                    case "b": result .= Chr(8)
                    case "f": result .= Chr(12)
                    case "n": result .= "`n"
                    case "r": result .= "`r"
                    case "t": result .= "`t"
                    case "u":
                        hex := SubStr(json, idx, 4)
                        idx += 4
                        codepoint := Integer("0x" hex)
                        if (codepoint >= 0xD800 && codepoint <= 0xDBFF) {
                            if (SubStr(json, idx, 2) != "\u") {
                                result .= Chr(0xFFFD)
                                continue
                            }
                            lowHex := SubStr(json, idx + 2, 4)
                            lowCodepoint := Integer("0x" lowHex)
                            if (lowCodepoint >= 0xDC00 && lowCodepoint <= 0xDFFF) {
                                codepoint := 0x10000 + ((codepoint - 0xD800) << 10) + (lowCodepoint - 0xDC00)
                                idx += 6
                                result .= Chr(codepoint)
                            } else {
                                result .= Chr(0xFFFD)
                            }
                        } else {
                            result .= Chr(codepoint)
                        }
                    default: result .= esc
                }
            } else {
                result .= char
            }
        }
    }

    static _ParseNumber(&json, &idx) {
        start := idx
        if (SubStr(json, idx, 1) = "-")
            idx++

        if (SubStr(json, idx, 1) = "0") {
            idx++
        } else {
            if (!this._IsDigit(SubStr(json, idx, 1)))
                throw Error("JSON parse error: invalid number at position " idx)
            Loop {
                if (idx > StrLen(json) || !this._IsDigit(SubStr(json, idx, 1)))
                    break
                idx++
            }
        }

        if (SubStr(json, idx, 1) = ".") {
            idx++
            if (!this._IsDigit(SubStr(json, idx, 1)))
                throw Error("JSON parse error: expected digit after decimal at position " idx)
            Loop {
                if (idx > StrLen(json) || !this._IsDigit(SubStr(json, idx, 1)))
                    break
                idx++
            }
        }

        if (SubStr(json, idx, 1) = "e" || SubStr(json, idx, 1) = "E") {
            idx++
            if (SubStr(json, idx, 1) = "+" || SubStr(json, idx, 1) = "-")
                idx++
            if (!this._IsDigit(SubStr(json, idx, 1)))
                throw Error("JSON parse error: expected digit in exponent at position " idx)
            Loop {
                if (idx > StrLen(json) || !this._IsDigit(SubStr(json, idx, 1)))
                    break
                idx++
            }
        }

        numStr := SubStr(json, start, idx - start)
        if (InStr(numStr, ".") || InStr(numStr, "e") || InStr(numStr, "E"))
            return Float(numStr)
        else
            return Integer(numStr)
    }

    static _ParseBoolean(&json, &idx) {
        if (SubStr(json, idx, 4) = "true") {
            idx += 4
            return true
        } else if (SubStr(json, idx, 5) = "false") {
            idx += 5
            return false
        }
        throw Error("JSON parse error: expected boolean at position " idx)
    }

    static _ParseNull(&json, &idx) {
        if (SubStr(json, idx, 4) = "null") {
            idx += 4
            return Json.Null
        }
        throw Error("JSON parse error: expected null at position " idx)
    }

    ; ==========================================================
    ; Internal: Stringify Methods
    ; ==========================================================

    static _StringifyObject(mapObj, indent, level) {
        if (mapObj.Count = 0)
            return "{}"

        pad := this._GetPadding(indent, level)
        innerPad := this._GetPadding(indent, level + 1)
        parts := Array()

        for key, value in mapObj {
            kv := innerPad . this._StringifyString(String(key)) . ":"
            if (indent > 0)
                kv .= " "
            kv .= this.Stringify(value, indent, level + 1)
            parts.Push(kv)
        }

        if (indent > 0)
            return "{" . "`n" . this._JoinParts(parts, "," . "`n") . "`n" . pad . "}"
        else
            return "{" . this._JoinParts(parts, ",") . "}"
    }

    static _StringifyArray(arrObj, indent, level) {
        if (arrObj.Length = 0)
            return "[]"

        pad := this._GetPadding(indent, level)
        innerPad := this._GetPadding(indent, level + 1)
        parts := Array()

        for value in arrObj
            parts.Push(innerPad . this.Stringify(value, indent, level + 1))

        if (indent > 0)
            return "[" . "`n" . this._JoinParts(parts, "," . "`n") . "`n" . pad . "]"
        else
            return "[" . this._JoinParts(parts, ",") . "]"
    }

    static _StringifyString(str) {
        result := '"'
        Loop Parse str {
            char := A_LoopField
            switch char {
                case '"': result .= '\"'
                case "\": result .= "\\"
                case "/": result .= "\/"
                case Chr(8): result .= "\b"
                case Chr(12): result .= "\f"
                case "`n": result .= "\n"
                case "`r": result .= "\r"
                case "`t": result .= "\t"
                default:
                    code := Ord(char)
                    if (code < 32)
                        result .= "\u" Format("{:04x}", code)
                    else
                        result .= char
            }
        }
        return result . '"'
    }

    ; ==========================================================
    ; Internal: Utility Methods
    ; ==========================================================

    static _SkipWhitespace(&json, &idx) {
        len := StrLen(json)
        Loop {
            if (idx > len)
                return
            char := SubStr(json, idx, 1)
            if (char = " " || char = "`t" || char = "`n" || char = "`r") {
                idx++
                continue
            }
            return
        }
    }

    static _IsDigit(char) {
        return char >= "0" && char <= "9"
    }

    static _GetPadding(indent, level) {
        if (indent = 0)
            return ""
        result := ""
        total := indent * level
        Loop total
            result .= " "
        return result
    }

    static _JoinParts(parts, separator) {
        result := ""
        for i, part in parts {
            if (i > 1)
                result .= separator
            result .= part
        }
        return result
    }

    ; Loads JSON from a file and parses it
    static Load(filePath) {
        if (!FileExist(filePath))
            throw Error("JSON file not found: " filePath)
        content := FileRead(filePath, "UTF-8")
        return this.Parse(content)
    }

    ; Converts an AHK object to JSON and writes to a file
    static Save(filePath, obj, indent := 2) {
        jsonStr := this.Stringify(obj, indent)
        FileDelete(filePath)
        FileAppend(jsonStr, filePath, "UTF-8")
    }
}
