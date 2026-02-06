import SwiftUI

enum FingerZone: String, CaseIterable {
    case leftPinky
    case leftRing
    case leftMiddle
    case leftIndex
    case thumb
    case rightIndex
    case rightMiddle
    case rightRing
    case rightPinky

    var color: Color {
        switch self {
        case .leftPinky:   Color(red: 0.90, green: 0.40, blue: 0.40)
        case .leftRing:    Color(red: 0.90, green: 0.65, blue: 0.35)
        case .leftMiddle:  Color(red: 0.90, green: 0.85, blue: 0.35)
        case .leftIndex:   Color(red: 0.45, green: 0.80, blue: 0.45)
        case .thumb:       Color(red: 0.60, green: 0.60, blue: 0.70)
        case .rightIndex:  Color(red: 0.35, green: 0.75, blue: 0.80)
        case .rightMiddle: Color(red: 0.45, green: 0.55, blue: 0.85)
        case .rightRing:   Color(red: 0.70, green: 0.45, blue: 0.85)
        case .rightPinky:  Color(red: 0.85, green: 0.45, blue: 0.70)
        }
    }
}
