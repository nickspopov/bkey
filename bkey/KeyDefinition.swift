import Foundation

struct KeyDefinition: Identifiable {
    let id: String
    let label: String
    let keyCode: UInt16
    let character: Character?
    let widthMultiplier: CGFloat
    let finger: FingerZone
    let row: Int

    init(
        id: String,
        label: String,
        keyCode: UInt16,
        character: Character? = nil,
        widthMultiplier: CGFloat = 1.0,
        finger: FingerZone,
        row: Int
    ) {
        self.id = id
        self.label = label
        self.keyCode = keyCode
        self.character = character
        self.widthMultiplier = widthMultiplier
        self.finger = finger
        self.row = row
    }

    // MARK: - Full keyboard layout

    static let fullLayout: [[KeyDefinition]] = [row0, row1, row2, row3, row4]

    // Row 0: Number row
    static let row0: [KeyDefinition] = [
        KeyDefinition(id: "backtick", label: "`", keyCode: 50, character: "`", finger: .leftPinky, row: 0),
        KeyDefinition(id: "1", label: "1", keyCode: 18, character: "1", finger: .leftPinky, row: 0),
        KeyDefinition(id: "2", label: "2", keyCode: 19, character: "2", finger: .leftRing, row: 0),
        KeyDefinition(id: "3", label: "3", keyCode: 20, character: "3", finger: .leftMiddle, row: 0),
        KeyDefinition(id: "4", label: "4", keyCode: 21, character: "4", finger: .leftIndex, row: 0),
        KeyDefinition(id: "5", label: "5", keyCode: 23, character: "5", finger: .leftIndex, row: 0),
        KeyDefinition(id: "6", label: "6", keyCode: 22, character: "6", finger: .rightIndex, row: 0),
        KeyDefinition(id: "7", label: "7", keyCode: 26, character: "7", finger: .rightIndex, row: 0),
        KeyDefinition(id: "8", label: "8", keyCode: 28, character: "8", finger: .rightMiddle, row: 0),
        KeyDefinition(id: "9", label: "9", keyCode: 25, character: "9", finger: .rightRing, row: 0),
        KeyDefinition(id: "0", label: "0", keyCode: 29, character: "0", finger: .rightPinky, row: 0),
        KeyDefinition(id: "minus", label: "-", keyCode: 27, character: "-", finger: .rightPinky, row: 0),
        KeyDefinition(id: "equals", label: "=", keyCode: 24, character: "=", finger: .rightPinky, row: 0),
        KeyDefinition(id: "delete", label: "Delete", keyCode: 51, widthMultiplier: 1.5, finger: .rightPinky, row: 0),
    ]

    // Row 1: QWERTY row
    static let row1: [KeyDefinition] = [
        KeyDefinition(id: "tab", label: "Tab", keyCode: 48, widthMultiplier: 1.5, finger: .leftPinky, row: 1),
        KeyDefinition(id: "q", label: "Q", keyCode: 12, character: "q", finger: .leftPinky, row: 1),
        KeyDefinition(id: "w", label: "W", keyCode: 13, character: "w", finger: .leftRing, row: 1),
        KeyDefinition(id: "e", label: "E", keyCode: 14, character: "e", finger: .leftMiddle, row: 1),
        KeyDefinition(id: "r", label: "R", keyCode: 15, character: "r", finger: .leftIndex, row: 1),
        KeyDefinition(id: "t", label: "T", keyCode: 17, character: "t", finger: .leftIndex, row: 1),
        KeyDefinition(id: "y", label: "Y", keyCode: 16, character: "y", finger: .rightIndex, row: 1),
        KeyDefinition(id: "u", label: "U", keyCode: 32, character: "u", finger: .rightIndex, row: 1),
        KeyDefinition(id: "i", label: "I", keyCode: 34, character: "i", finger: .rightMiddle, row: 1),
        KeyDefinition(id: "o", label: "O", keyCode: 31, character: "o", finger: .rightRing, row: 1),
        KeyDefinition(id: "p", label: "P", keyCode: 35, character: "p", finger: .rightPinky, row: 1),
        KeyDefinition(id: "leftBracket", label: "[", keyCode: 33, character: "[", finger: .rightPinky, row: 1),
        KeyDefinition(id: "rightBracket", label: "]", keyCode: 30, character: "]", finger: .rightPinky, row: 1),
        KeyDefinition(id: "backslash", label: "\\", keyCode: 42, character: "\\", widthMultiplier: 1.5, finger: .rightPinky, row: 1),
    ]

    // Row 2: Home row
    static let row2: [KeyDefinition] = [
        KeyDefinition(id: "caps", label: "Caps", keyCode: 57, widthMultiplier: 1.75, finger: .leftPinky, row: 2),
        KeyDefinition(id: "a", label: "A", keyCode: 0, character: "a", finger: .leftPinky, row: 2),
        KeyDefinition(id: "s", label: "S", keyCode: 1, character: "s", finger: .leftRing, row: 2),
        KeyDefinition(id: "d", label: "D", keyCode: 2, character: "d", finger: .leftMiddle, row: 2),
        KeyDefinition(id: "f", label: "F", keyCode: 3, character: "f", finger: .leftIndex, row: 2),
        KeyDefinition(id: "g", label: "G", keyCode: 5, character: "g", finger: .leftIndex, row: 2),
        KeyDefinition(id: "h", label: "H", keyCode: 4, character: "h", finger: .rightIndex, row: 2),
        KeyDefinition(id: "j", label: "J", keyCode: 38, character: "j", finger: .rightIndex, row: 2),
        KeyDefinition(id: "k", label: "K", keyCode: 40, character: "k", finger: .rightMiddle, row: 2),
        KeyDefinition(id: "l", label: "L", keyCode: 37, character: "l", finger: .rightRing, row: 2),
        KeyDefinition(id: "semicolon", label: ";", keyCode: 41, character: ";", finger: .rightPinky, row: 2),
        KeyDefinition(id: "quote", label: "'", keyCode: 39, character: "'", finger: .rightPinky, row: 2),
        KeyDefinition(id: "return", label: "Return", keyCode: 36, widthMultiplier: 1.75, finger: .rightPinky, row: 2),
    ]

    // Row 3: Shift row
    static let row3: [KeyDefinition] = [
        KeyDefinition(id: "lshift", label: "Shift", keyCode: 56, widthMultiplier: 2.25, finger: .leftPinky, row: 3),
        KeyDefinition(id: "z", label: "Z", keyCode: 6, character: "z", finger: .leftPinky, row: 3),
        KeyDefinition(id: "x", label: "X", keyCode: 7, character: "x", finger: .leftRing, row: 3),
        KeyDefinition(id: "c", label: "C", keyCode: 8, character: "c", finger: .leftMiddle, row: 3),
        KeyDefinition(id: "v", label: "V", keyCode: 9, character: "v", finger: .leftIndex, row: 3),
        KeyDefinition(id: "b", label: "B", keyCode: 11, character: "b", finger: .leftIndex, row: 3),
        KeyDefinition(id: "n", label: "N", keyCode: 45, character: "n", finger: .rightIndex, row: 3),
        KeyDefinition(id: "m", label: "M", keyCode: 46, character: "m", finger: .rightIndex, row: 3),
        KeyDefinition(id: "comma", label: ",", keyCode: 43, character: ",", finger: .rightMiddle, row: 3),
        KeyDefinition(id: "period", label: ".", keyCode: 47, character: ".", finger: .rightRing, row: 3),
        KeyDefinition(id: "slash", label: "/", keyCode: 44, character: "/", finger: .rightPinky, row: 3),
        KeyDefinition(id: "rshift", label: "Shift", keyCode: 60, widthMultiplier: 2.75, finger: .rightPinky, row: 3),
    ]

    // Row 4: Bottom row
    static let row4: [KeyDefinition] = [
        KeyDefinition(id: "fn", label: "Fn", keyCode: 63, finger: .leftPinky, row: 4),
        KeyDefinition(id: "ctrl", label: "Ctrl", keyCode: 59, finger: .leftPinky, row: 4),
        KeyDefinition(id: "lopt", label: "Opt", keyCode: 58, finger: .leftPinky, row: 4),
        KeyDefinition(id: "lcmd", label: "Cmd", keyCode: 55, widthMultiplier: 1.25, finger: .thumb, row: 4),
        KeyDefinition(id: "space", label: "", keyCode: 49, character: " ", widthMultiplier: 6.25, finger: .thumb, row: 4),
        KeyDefinition(id: "rcmd", label: "Cmd", keyCode: 54, widthMultiplier: 1.25, finger: .thumb, row: 4),
        KeyDefinition(id: "ropt", label: "Opt", keyCode: 61, finger: .rightPinky, row: 4),
    ]

    // MARK: - Key lookup

    /// Maps a character to the set of keyCodes needed to type it (including Shift if uppercase/symbol).
    static func keyCodes(for character: Character) -> Set<UInt16> {
        let shiftedCharMap: [Character: Character] = [
            "~": "`", "!": "1", "@": "2", "#": "3", "$": "4", "%": "5",
            "^": "6", "&": "7", "*": "8", "(": "9", ")": "0", "_": "-",
            "+": "=", "{": "[", "}": "]", "|": "\\", ":": ";", "\"": "'",
            "<": ",", ">": ".", "?": "/",
        ]

        let lowerChar = Character(String(character).lowercased())
        let isUppercase = character.isUppercase || shiftedCharMap.keys.contains(character)

        let baseChar: Character
        if let mapped = shiftedCharMap[character] {
            baseChar = mapped
        } else {
            baseChar = lowerChar
        }

        let allKeys = fullLayout.flatMap { $0 }
        guard let keyDef = allKeys.first(where: { $0.character == baseChar }) else {
            return []
        }

        var codes: Set<UInt16> = [keyDef.keyCode]
        if isUppercase {
            // Add left shift by default (keyCode 56)
            codes.insert(56)
        }
        return codes
    }
}
