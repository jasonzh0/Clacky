import XCTest
import CoreGraphics
@testable import Clacky

final class KeycodeMapTests: XCTestCase {
    func testCommonLettersMap() {
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x00), "30")  // A
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x0C), "16")  // Q
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x06), "44")  // Z
    }

    func testNumberRow() {
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x12), "2")   // 1
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x1D), "11")  // 0
    }

    func testModifiersAndControls() {
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x35), "1")   // Escape
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x31), "57")  // Space
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x24), "28")  // Return
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x33), "14")  // Backspace
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x38), "42")  // Left Shift
    }

    func testArrowKeysUseExtendedCodes() {
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x7E), "57416")  // Up
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x7B), "57419")  // Left
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x7C), "57421")  // Right
        XCTAssertEqual(KeycodeMap.mechvibesKey(for: 0x7D), "57424")  // Down
    }

    func testUnknownKeyReturnsNil() {
        XCTAssertNil(KeycodeMap.mechvibesKey(for: 0xFF))
    }

    func testNoDuplicateMechvibesValues() {
        let values = KeycodeMap.cgToMechvibes.values
        XCTAssertEqual(values.count, Set(values).count, "Each macOS key should map to a unique Mechvibes code.")
    }
}
