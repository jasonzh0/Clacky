import XCTest
@testable import Clacky

final class SoundPackLoaderTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClackyPackTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testParseMultiPack() throws {
        let packDir = tempDir.appendingPathComponent("test-multi")
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        let config = """
        {
          "id": "test-multi",
          "name": "Test Multi",
          "key_define_type": "multi",
          "includes_numpad": true,
          "defines": {
            "30": "a.wav",
            "31": "s.wav"
          }
        }
        """
        try config.write(to: packDir.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)

        let pack = try XCTUnwrap(SoundPackLoader.load(from: packDir))
        XCTAssertEqual(pack.id, "test-multi")
        XCTAssertEqual(pack.name, "Test Multi")
        guard case .multi(let files) = pack.kind else {
            return XCTFail("Expected multi pack kind")
        }
        XCTAssertEqual(files["30"]?.lastPathComponent, "a.wav")
        XCTAssertEqual(files["31"]?.lastPathComponent, "s.wav")
    }

    func testParseSinglePack() throws {
        let packDir = tempDir.appendingPathComponent("test-single")
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        let config = """
        {
          "id": "test-single",
          "name": "Test Single",
          "key_define_type": "single",
          "sound": "all.ogg",
          "includes_numpad": false,
          "defines": {
            "30": [100, 250],
            "31": [400, 250]
          }
        }
        """
        try config.write(to: packDir.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)

        let pack = try XCTUnwrap(SoundPackLoader.load(from: packDir))
        XCTAssertFalse(pack.includesNumpad)
        guard case .single(let soundFile, let slices) = pack.kind else {
            return XCTFail("Expected single pack kind")
        }
        XCTAssertEqual(soundFile.lastPathComponent, "all.ogg")
        XCTAssertEqual(slices["30"]?.startMs, 100)
        XCTAssertEqual(slices["30"]?.durationMs, 250)
        XCTAssertEqual(slices["31"]?.startMs, 400)
    }

    func testMissingConfigReturnsNil() {
        let packDir = tempDir.appendingPathComponent("empty")
        try? FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        XCTAssertNil(SoundPackLoader.load(from: packDir))
    }

    func testMalformedConfigReturnsNil() throws {
        let packDir = tempDir.appendingPathComponent("bad")
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        try "{ not json".write(to: packDir.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)
        XCTAssertNil(SoundPackLoader.load(from: packDir))
    }

    func testIDFallsBackToDirectoryName() throws {
        let packDir = tempDir.appendingPathComponent("no-id-pack")
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        let config = """
        {
          "name": "No ID",
          "key_define_type": "multi",
          "defines": { "30": "a.wav" }
        }
        """
        try config.write(to: packDir.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)
        let pack = try XCTUnwrap(SoundPackLoader.load(from: packDir))
        XCTAssertEqual(pack.id, "no-id-pack")
    }
}
