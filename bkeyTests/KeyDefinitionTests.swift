import Testing
@testable import bkey

struct KeyDefinitionTests {

    @Test func layoutHasFiveRows() {
        #expect(KeyDefinition.fullLayout.count == 5)
    }

    @Test func allKeysHaveUniqueIds() {
        let allKeys = KeyDefinition.fullLayout.flatMap { $0 }
        let ids = allKeys.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "Duplicate key IDs found")
    }

    @Test func allKeysHaveUniqueKeyCodes() {
        let allKeys = KeyDefinition.fullLayout.flatMap { $0 }
        let codes = allKeys.map(\.keyCode)
        let uniqueCodes = Set(codes)
        #expect(codes.count == uniqueCodes.count, "Duplicate keyCodes found")
    }

    @Test func allKeysHaveValidFingerZones() {
        let allKeys = KeyDefinition.fullLayout.flatMap { $0 }
        let validZones = Set(FingerZone.allCases)
        for key in allKeys {
            #expect(validZones.contains(key.finger),
                    "Key \(key.id) has invalid finger zone: \(key.finger)")
        }
    }

    @Test func keyCodesForLowercaseLetter() {
        let codes = KeyDefinition.keyCodes(for: "a")
        #expect(codes.contains(0)) // keyCode for 'a'
        #expect(!codes.contains(56)) // no shift needed
    }

    @Test func keyCodesForUppercaseLetter() {
        let codes = KeyDefinition.keyCodes(for: "A")
        #expect(codes.contains(0)) // keyCode for 'a'
        #expect(codes.contains(56)) // shift needed
    }

    @Test func keyCodesForSpace() {
        let codes = KeyDefinition.keyCodes(for: " ")
        #expect(codes.contains(49)) // space keyCode
    }

    @Test func keyCodesForShiftedSymbol() {
        let codes = KeyDefinition.keyCodes(for: "!")
        #expect(codes.contains(18)) // keyCode for '1'
        #expect(codes.contains(56)) // shift needed
    }

    @Test func keyCodesForUnknownCharReturnsEmpty() {
        let codes = KeyDefinition.keyCodes(for: "€")
        #expect(codes.isEmpty)
    }

    @Test func rowAssignmentsAreCorrect() {
        for (rowIndex, row) in KeyDefinition.fullLayout.enumerated() {
            for key in row {
                #expect(key.row == rowIndex,
                        "Key \(key.id) in row \(rowIndex) has row=\(key.row)")
            }
        }
    }
}
