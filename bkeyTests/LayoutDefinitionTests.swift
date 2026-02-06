import Testing
import Foundation
@testable import bkey

struct LayoutDefinitionTests {
    @Test func allKeysHaveUniqueKeyCodes() {
        var seenCodes: Set<UInt16> = []
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                #expect(!seenCodes.contains(key.keyCode), "Duplicate keyCode: \(key.keyCode) for key '\(key.label)'")
                seenCodes.insert(key.keyCode)
            }
        }
    }

    @Test func eachRowHasCorrectKeyCount() {
        let expected = [14, 14, 13, 12, 10]
        for (i, row) in LayoutDefinition.qwertyUS.enumerated() {
            #expect(row.keys.count == expected[i], "Row \(i) has \(row.keys.count) keys, expected \(expected[i])")
        }
    }

    @Test func totalKeyCount() {
        let total = LayoutDefinition.qwertyUS.reduce(0) { $0 + $1.keys.count }
        #expect(total == 63)
    }

    @Test func spaceBarHasCorrectWidth() {
        let spaceKey = LayoutDefinition.qwertyUS[4].keys.first { $0.keyCode == 49 }
        #expect(spaceKey != nil)
        #expect(spaceKey!.width == 6.0)
    }

    @Test func standardKeysHaveWidth1() {
        // Letter keys should all be width 1.0
        let letterKeys = LayoutDefinition.qwertyUS[1].keys.filter { $0.label.count == 1 }
        for key in letterKeys {
            #expect(key.width == 1.0, "Key '\(key.label)' has width \(key.width), expected 1.0")
        }
    }

    @Test func allKeysHaveFingerZoneAssigned() {
        for row in LayoutDefinition.qwertyUS {
            for key in row.keys {
                // FingerZone is non-optional, so this verifies it's a valid case
                #expect(FingerZone.allCases.contains(key.finger), "Key '\(key.label)' has invalid finger zone")
            }
        }
    }
}

struct FingerZoneTests {
    @Test func fingerZoneHasNineCases() {
        #expect(FingerZone.allCases.count == 9)
    }

    @Test func fingerZoneLabelsAreUnique() {
        let labels = FingerZone.allCases.map(\.label)
        #expect(Set(labels).count == labels.count)
    }

    @Test func fingerZoneLabelsMatchExpected() {
        let expected = ["L4", "L3", "L2", "L1", "R1", "R2", "R3", "R4", "Th"]
        let actual = FingerZone.allCases.map(\.label)
        #expect(actual == expected)
    }
}
