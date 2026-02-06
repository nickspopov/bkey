import Testing
@testable import bkey

struct KeyMappingTests {
    @Test func fingerZoneForHomeRowKeys() {
        #expect(KeyMapping.fingerZone(for: "a") == .leftPinky)
        #expect(KeyMapping.fingerZone(for: "s") == .leftRing)
        #expect(KeyMapping.fingerZone(for: "d") == .leftMiddle)
        #expect(KeyMapping.fingerZone(for: "f") == .leftIndex)
        #expect(KeyMapping.fingerZone(for: "j") == .rightIndex)
        #expect(KeyMapping.fingerZone(for: "k") == .rightMiddle)
        #expect(KeyMapping.fingerZone(for: "l") == .rightRing)
        #expect(KeyMapping.fingerZone(for: ";") == .rightPinky)
    }

    @Test func fingerZoneForSpace() {
        #expect(KeyMapping.fingerZone(for: " ") == .thumb)
    }

    @Test func keyCodeMappingRoundTrip() {
        let code = KeyMapping.keyCode(for: "f")
        #expect(code == 3)
        #expect(KeyMapping.keyCodeToFinger[3] == .leftIndex)
    }

    @Test func allLettersHaveMapping() {
        for char in "abcdefghijklmnopqrstuvwxyz" {
            #expect(KeyMapping.fingerZone(for: char) != nil, "Missing mapping for '\(char)'")
        }
    }

    @Test func layoutHasFiveRows() {
        #expect(LayoutDefinition.qwertyUS.count == 5)
    }
}
