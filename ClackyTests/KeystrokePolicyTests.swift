import XCTest
@testable import Clacky

final class KeystrokePolicyTests: XCTestCase {
    func testIgnoresAutorepeatWhenAsked() {
        XCTAssertFalse(
            KeystrokePolicy.shouldPlay(
                isDown: true,
                isRepeat: true,
                ignoreKeyRepeat: true,
                playOnKeyUp: false
            )
        )
    }

    func testPlaysInitialKeyDown() {
        XCTAssertTrue(
            KeystrokePolicy.shouldPlay(
                isDown: true,
                isRepeat: false,
                ignoreKeyRepeat: true,
                playOnKeyUp: false
            )
        )
    }

    func testCanPlayAutorepeatWhenDisabled() {
        XCTAssertTrue(
            KeystrokePolicy.shouldPlay(
                isDown: true,
                isRepeat: true,
                ignoreKeyRepeat: false,
                playOnKeyUp: false
            )
        )
    }

    func testSkipsKeyUpUnlessEnabled() {
        XCTAssertFalse(
            KeystrokePolicy.shouldPlay(
                isDown: false,
                isRepeat: false,
                ignoreKeyRepeat: true,
                playOnKeyUp: false
            )
        )
        XCTAssertTrue(
            KeystrokePolicy.shouldPlay(
                isDown: false,
                isRepeat: false,
                ignoreKeyRepeat: true,
                playOnKeyUp: true
            )
        )
    }
}
