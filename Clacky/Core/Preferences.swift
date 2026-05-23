import Foundation
import Observation

@Observable
final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    var volume: Double {
        didSet { defaults.set(volume, forKey: Keys.volume) }
    }

    var selectedPackID: String {
        didSet { defaults.set(selectedPackID, forKey: Keys.selectedPackID) }
    }

    var pitchVariation: Double {
        didSet { defaults.set(pitchVariation, forKey: Keys.pitchVariation) }
    }

    var gainVariation: Double {
        didSet { defaults.set(gainVariation, forKey: Keys.gainVariation) }
    }

    var playOnKeyUp: Bool {
        didSet { defaults.set(playOnKeyUp, forKey: Keys.playOnKeyUp) }
    }

    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    private init() {
        defaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.volume: 0.7,
            Keys.selectedPackID: "cherrymx-blue-pbt",
            Keys.pitchVariation: 0.02,
            Keys.gainVariation: 0.06,
            Keys.playOnKeyUp: false,
            Keys.launchAtLogin: false
        ])
        isEnabled = defaults.bool(forKey: Keys.isEnabled)
        volume = defaults.double(forKey: Keys.volume)
        selectedPackID = defaults.string(forKey: Keys.selectedPackID) ?? "cherrymx-blue-pbt"
        pitchVariation = defaults.double(forKey: Keys.pitchVariation)
        gainVariation = defaults.double(forKey: Keys.gainVariation)
        playOnKeyUp = defaults.bool(forKey: Keys.playOnKeyUp)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
    }

    private enum Keys {
        static let isEnabled = "clacky.isEnabled"
        static let volume = "clacky.volume"
        static let selectedPackID = "clacky.selectedPackID"
        static let pitchVariation = "clacky.pitchVariation"
        static let gainVariation = "clacky.gainVariation"
        static let playOnKeyUp = "clacky.playOnKeyUp"
        static let launchAtLogin = "clacky.launchAtLogin"
    }
}
