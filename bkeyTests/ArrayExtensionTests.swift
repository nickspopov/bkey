import Testing
@testable import bkey

struct ArrayExtensionTests {
    @Test func safeSubscriptInBoundsReturnsElement() {
        let arr = [10, 20, 30]
        #expect(arr[safe: 0] == 10)
        #expect(arr[safe: 1] == 20)
        #expect(arr[safe: 2] == 30)
    }

    @Test func safeSubscriptOutOfBoundsReturnsNil() {
        let arr = [10, 20, 30]
        #expect(arr[safe: 3] == nil)
        #expect(arr[safe: 100] == nil)
    }

    @Test func safeSubscriptNegativeIndexReturnsNil() {
        let arr = [10, 20, 30]
        #expect(arr[safe: -1] == nil)
        #expect(arr[safe: -10] == nil)
    }
}
