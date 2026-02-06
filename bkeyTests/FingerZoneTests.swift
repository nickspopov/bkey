import Testing
import SwiftUI
@testable import bkey

struct FingerZoneTests {

    @Test func allZonesHaveDistinctColors() {
        let zones = FingerZone.allCases
        var seen: Set<String> = []
        for zone in zones {
            let desc = zone.color.description
            #expect(!seen.contains(desc), "Duplicate color for \(zone)")
            seen.insert(desc)
        }
    }

    @Test func nineFingerZonesExist() {
        #expect(FingerZone.allCases.count == 9)
    }

    @Test func spacebarIsMappedToThumb() {
        let allKeys = KeyDefinition.fullLayout.flatMap { $0 }
        let spaceKey = allKeys.first { $0.id == "space" }
        #expect(spaceKey != nil)
        #expect(spaceKey?.finger == .thumb)
    }

    @Test func homeRowLetterFingerAssignments() {
        let allKeys = KeyDefinition.fullLayout.flatMap { $0 }
        let aKey = allKeys.first { $0.id == "a" }
        let fKey = allKeys.first { $0.id == "f" }
        let jKey = allKeys.first { $0.id == "j" }
        let semicolonKey = allKeys.first { $0.id == "semicolon" }

        #expect(aKey?.finger == .leftPinky)
        #expect(fKey?.finger == .leftIndex)
        #expect(jKey?.finger == .rightIndex)
        #expect(semicolonKey?.finger == .rightPinky)
    }
}
