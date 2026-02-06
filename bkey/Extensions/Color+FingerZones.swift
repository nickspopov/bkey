import SwiftUI

enum FingerZone: String, CaseIterable, Sendable {
    case leftPinky, leftRing, leftMiddle, leftIndex
    case rightIndex, rightMiddle, rightRing, rightPinky
    case thumb

    var color: Color {
        switch self {
        case .leftPinky:  Color(red: 246/255, green: 135/255, blue: 179/255) // #F687B3
        case .leftRing:   Color(red: 237/255, green: 137/255, blue: 54/255)  // #ED8936
        case .leftMiddle: Color(red: 236/255, green: 201/255, blue: 75/255)  // #ECC94B
        case .leftIndex:  Color(red: 104/255, green: 211/255, blue: 145/255) // #68D391
        case .rightIndex: Color(red: 79/255, green: 209/255, blue: 197/255)  // #4FD1C5
        case .rightMiddle:Color(red: 99/255, green: 179/255, blue: 237/255)  // #63B3ED
        case .rightRing:  Color(red: 127/255, green: 156/255, blue: 245/255) // #7F9CF5
        case .rightPinky: Color(red: 183/255, green: 148/255, blue: 244/255) // #B794F4
        case .thumb:      Color(red: 113/255, green: 128/255, blue: 150/255) // #718096
        }
    }

    var label: String {
        switch self {
        case .leftPinky:  "L4"
        case .leftRing:   "L3"
        case .leftMiddle: "L2"
        case .leftIndex:  "L1"
        case .rightIndex: "R1"
        case .rightMiddle:"R2"
        case .rightRing:  "R3"
        case .rightPinky: "R4"
        case .thumb:      "Th"
        }
    }
}
