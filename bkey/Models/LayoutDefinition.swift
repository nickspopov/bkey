import Foundation

struct KeyDefinition: Sendable {
    let keyCode: UInt16
    let label: String
    let shiftLabel: String?
    let finger: FingerZone
    let width: CGFloat  // relative to standard key (1.0)
}

struct KeyRow: Sendable {
    let keys: [KeyDefinition]
}

struct LayoutDefinition {
    static let qwertyUS: [KeyRow] = [
        // Row 0: number row
        KeyRow(keys: [
            KeyDefinition(keyCode: 50, label: "`", shiftLabel: "~", finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 18, label: "1", shiftLabel: "!", finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 19, label: "2", shiftLabel: "@", finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 20, label: "3", shiftLabel: "#", finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 21, label: "4", shiftLabel: "$", finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 23, label: "5", shiftLabel: "%", finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 22, label: "6", shiftLabel: "^", finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 26, label: "7", shiftLabel: "&", finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 28, label: "8", shiftLabel: "*", finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 25, label: "9", shiftLabel: "(", finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 29, label: "0", shiftLabel: ")", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 27, label: "-", shiftLabel: "_", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 24, label: "=", shiftLabel: "+", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 51, label: "delete", shiftLabel: nil, finger: .rightPinky, width: 1.5),
        ]),
        // Row 1: QWERTY
        KeyRow(keys: [
            KeyDefinition(keyCode: 48, label: "tab", shiftLabel: nil, finger: .leftPinky, width: 1.5),
            KeyDefinition(keyCode: 12, label: "Q", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 13, label: "W", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 14, label: "E", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 15, label: "R", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 17, label: "T", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 16, label: "Y", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 32, label: "U", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 34, label: "I", shiftLabel: nil, finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 31, label: "O", shiftLabel: nil, finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 35, label: "P", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 33, label: "[", shiftLabel: "{", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 30, label: "]", shiftLabel: "}", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 42, label: "\\", shiftLabel: "|", finger: .rightPinky, width: 1.0),
        ]),
        // Row 2: home row
        KeyRow(keys: [
            KeyDefinition(keyCode: 57, label: "caps lock", shiftLabel: nil, finger: .leftPinky, width: 1.8),
            KeyDefinition(keyCode: 0, label: "A", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 1, label: "S", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 2, label: "D", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 3, label: "F", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 5, label: "G", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 4, label: "H", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 38, label: "J", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 40, label: "K", shiftLabel: nil, finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 37, label: "L", shiftLabel: nil, finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 41, label: ";", shiftLabel: ":", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 39, label: "'", shiftLabel: "\"", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 36, label: "enter", shiftLabel: nil, finger: .rightPinky, width: 1.8),
        ]),
        // Row 3: bottom row
        KeyRow(keys: [
            KeyDefinition(keyCode: 56, label: "shift", shiftLabel: nil, finger: .leftPinky, width: 2.4),
            KeyDefinition(keyCode: 6, label: "Z", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 7, label: "X", shiftLabel: nil, finger: .leftRing, width: 1.0),
            KeyDefinition(keyCode: 8, label: "C", shiftLabel: nil, finger: .leftMiddle, width: 1.0),
            KeyDefinition(keyCode: 9, label: "V", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 11, label: "B", shiftLabel: nil, finger: .leftIndex, width: 1.0),
            KeyDefinition(keyCode: 45, label: "N", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 46, label: "M", shiftLabel: nil, finger: .rightIndex, width: 1.0),
            KeyDefinition(keyCode: 43, label: ",", shiftLabel: "<", finger: .rightMiddle, width: 1.0),
            KeyDefinition(keyCode: 47, label: ".", shiftLabel: ">", finger: .rightRing, width: 1.0),
            KeyDefinition(keyCode: 44, label: "/", shiftLabel: "?", finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 60, label: "shift", shiftLabel: nil, finger: .rightPinky, width: 2.4),
        ]),
        // Row 4: modifier row
        KeyRow(keys: [
            KeyDefinition(keyCode: 179, label: "fn", shiftLabel: nil, finger: .leftPinky, width: 1.0),
            KeyDefinition(keyCode: 59, label: "control", shiftLabel: nil, finger: .leftPinky, width: 1.3),
            KeyDefinition(keyCode: 58, label: "option", shiftLabel: nil, finger: .leftPinky, width: 1.3),
            KeyDefinition(keyCode: 55, label: "command", shiftLabel: nil, finger: .leftPinky, width: 1.5),
            KeyDefinition(keyCode: 49, label: "", shiftLabel: nil, finger: .thumb, width: 6.0),
            KeyDefinition(keyCode: 54, label: "command", shiftLabel: nil, finger: .rightPinky, width: 1.5),
            KeyDefinition(keyCode: 61, label: "option", shiftLabel: nil, finger: .rightPinky, width: 1.3),
            // Arrow keys cluster
            KeyDefinition(keyCode: 123, label: "◀", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 126, label: "▲", shiftLabel: nil, finger: .rightPinky, width: 1.0),
            KeyDefinition(keyCode: 124, label: "▶", shiftLabel: nil, finger: .rightPinky, width: 1.0),
        ]),
    ]
}
