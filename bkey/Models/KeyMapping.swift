struct KeyMapping {
    /// Map from keyCode to FingerZone, built from layout definition
    static let keyCodeToFinger: [UInt16: FingerZone] = {
        var map: [UInt16: FingerZone] = [:]
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                map[key.keyCode] = key.finger
            }
        }
        return map
    }()

    /// Map from lowercase character to its keyCode
    static let characterToKeyCode: [Character: UInt16] = {
        var map: [Character: UInt16] = [:]
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                if key.label.count == 1 {
                    map[Character(key.label.lowercased())] = key.keyCode
                }
            }
        }
        map[" "] = 49 // space
        return map
    }()

    /// Get the finger zone for a character
    static func fingerZone(for character: Character) -> FingerZone? {
        guard let keyCode = characterToKeyCode[character] else { return nil }
        return keyCodeToFinger[keyCode]
    }

    /// Get the keyCode for a character
    static func keyCode(for character: Character) -> UInt16? {
        characterToKeyCode[character]
    }
}
