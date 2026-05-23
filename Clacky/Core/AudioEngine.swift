import Foundation
import AVFoundation
import CoreGraphics

/// Low-latency polyphonic player for Mechvibes sound packs.
///
/// Architecture: one `AVAudioEngine`, a fixed pool of `AVAudioPlayerNode`s that
/// connect directly to the main mixer. Players are started once at engine boot
/// and stay running — `play()` only calls `scheduleBuffer(.interrupts)`, never
/// `stop()`/`play()`, which would otherwise force a stop/restart cycle every
/// keystroke and dominate perceived latency.
///
/// Every buffer is converted at pack-load time to a single canonical format so
/// the audio graph and the buffers we schedule always agree — `AVAudioPlayerNode`
/// raises an ObjC exception (and crashes the app) if you schedule a buffer whose
/// channel count or sample rate doesn't match the player node's output format.
///
/// Pitch jitter (`AVAudioUnitVarispeed`) is intentionally *not* in the chain:
/// the unit adds real buffering latency and we'd rather feel responsive than
/// have per-key pitch variation. Gain jitter is kept since it's free.
final class AudioEngine {
    private struct Voice {
        let player: AVAudioPlayerNode
    }

    /// Canonical format for the audio graph and all loaded buffers. Stereo
    /// Float32 at 44.1 kHz covers every Mechvibes pack we've encountered and
    /// matches macOS' default output format.
    private static let canonicalFormat: AVAudioFormat = {
        AVAudioFormat(commonFormat: .pcmFormatFloat32,
                      sampleRate: 44_100,
                      channels: 2,
                      interleaved: false)!
    }()

    private let engine = AVAudioEngine()
    private var voices: [Voice] = []
    private let voiceCount = 16
    private var nextVoice = 0
    private let voiceQueue = DispatchQueue(label: "com.clacky.AudioEngine", qos: .userInteractive)

    private var keyBuffers: [String: AVAudioPCMBuffer] = [:]
    private var fallbackBuffer: AVAudioPCMBuffer?
    private var spaceBuffer: AVAudioPCMBuffer?

    init() {
        setupVoices()
    }

    func setMasterVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = max(0, min(1, volume))
    }

    func loadPack(_ pack: SoundPack) {
        keyBuffers.removeAll(keepingCapacity: true)
        fallbackBuffer = nil
        spaceBuffer = nil

        switch pack.kind {
        case .single(let soundFile, let slices):
            guard let master = decode(url: soundFile) else {
                NSLog("Clacky: failed to decode pack sound file at \(soundFile.path)")
                return
            }
            // Convert master once into canonical format, then slice in canonical
            // — avoids re-running the converter per key.
            guard let canonicalMaster = convertToCanonical(master) else {
                NSLog("Clacky: failed to convert master sprite to canonical format")
                return
            }
            for (key, slice) in slices {
                if let buffer = sliceBuffer(canonicalMaster,
                                            startMs: slice.startMs,
                                            durationMs: slice.durationMs) {
                    keyBuffers[key] = buffer
                }
            }
        case .multi(let files):
            for (key, url) in files {
                if let buffer = decode(url: url),
                   let canonical = convertToCanonical(buffer) {
                    keyBuffers[key] = canonical
                }
            }
        }

        fallbackBuffer = keyBuffers["any"]
            ?? keyBuffers["30"]
            ?? keyBuffers.values.first
        spaceBuffer = keyBuffers["57"]

        if !engine.isRunning {
            startEngine()
        }
    }

    func play(keyCode: CGKeyCode, pitchJitter: Float, gainJitter: Float) {
        let mechKey = KeycodeMap.mechvibesKey(for: keyCode)
        let buffer: AVAudioPCMBuffer?
        if mechKey == "57", let space = spaceBuffer {
            buffer = space
        } else if let key = mechKey, let mapped = keyBuffers[key] {
            buffer = mapped
        } else {
            buffer = fallbackBuffer
        }
        guard let buffer else { return }

        // Defensive double-check: never schedule a buffer whose format doesn't
        // match the player nodes. A mismatch raises an uncaught ObjC exception.
        guard buffer.format.channelCount == Self.canonicalFormat.channelCount,
              buffer.format.sampleRate == Self.canonicalFormat.sampleRate else {
            return
        }

        // pitchJitter is intentionally unused — varispeed is no longer in the
        // audio graph for latency reasons (see class doc).
        _ = pitchJitter

        voiceQueue.async { [weak self] in
            guard let self else { return }
            let voice = self.voices[self.nextVoice]
            self.nextVoice = (self.nextVoice + 1) % self.voices.count

            let jitterGain = 1.0 + Float.random(in: -gainJitter...gainJitter)
            voice.player.volume = max(0, min(1.2, jitterGain))

            // No stop()/play() cycle — players are kept running. `.interrupts`
            // cancels any in-flight buffer on this voice and starts the new one
            // at the next render quantum.
            voice.player.scheduleBuffer(buffer, at: nil, options: [.interrupts]) { }
        }
    }

    private func setupVoices() {
        let format = Self.canonicalFormat
        for _ in 0..<voiceCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            voices.append(Voice(player: player))
        }
    }

    private func startEngine() {
        // Hint that we'd like the engine to process in small chunks. macOS
        // ultimately picks the hardware IO buffer size, but this nudges the
        // engine's graph processing toward lower-latency callbacks. Safe even
        // if the engine ignores it.
        try? engine.outputNode.auAudioUnit.allocateRenderResources()
        engine.outputNode.auAudioUnit.maximumFramesToRender = 256

        do {
            try engine.start()
            for voice in voices { voice.player.play() }
        } catch {
            NSLog("Clacky: AVAudioEngine failed to start: \(error.localizedDescription)")
        }
    }

    private func decode(url: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames) else {
            return nil
        }
        do {
            try file.read(into: buffer)
        } catch {
            return nil
        }
        return buffer
    }

    /// Convert a freshly-decoded buffer (which may be mono/stereo, int/float, any
    /// sample rate) into the engine's canonical format. Returns the input
    /// unchanged if it already matches.
    private func convertToCanonical(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let target = Self.canonicalFormat
        let src = buffer.format
        if src.sampleRate == target.sampleRate
            && src.channelCount == target.channelCount
            && src.commonFormat == target.commonFormat
            && src.isInterleaved == target.isInterleaved {
            return buffer
        }
        guard let converter = AVAudioConverter(from: src, to: target) else { return nil }

        let ratio = target.sampleRate / src.sampleRate
        let outFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: outFrames) else { return nil }

        var supplied = false
        var convertError: NSError?
        let status = converter.convert(to: output, error: &convertError) { _, status in
            if supplied {
                status.pointee = .endOfStream
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }

        if status == .error || convertError != nil {
            NSLog("Clacky: audio conversion failed: \(convertError?.localizedDescription ?? "unknown")")
            return nil
        }
        return output
    }

    /// Copy `[startMs, startMs+durationMs)` out of a canonical-format master
    /// sprite buffer into a standalone canonical buffer.
    private func sliceBuffer(_ source: AVAudioPCMBuffer, startMs: Double, durationMs: Double) -> AVAudioPCMBuffer? {
        let format = source.format
        let sampleRate = format.sampleRate
        let startFrame = Int(startMs * sampleRate / 1000.0)
        let frameCount = Int(durationMs * sampleRate / 1000.0)
        guard frameCount > 0, startFrame >= 0,
              startFrame + frameCount <= Int(source.frameLength) else { return nil }

        guard let dest = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        dest.frameLength = AVAudioFrameCount(frameCount)

        let channels = Int(format.channelCount)
        // canonicalFormat is always Float32 non-interleaved — but stay generic.
        if let srcF = source.floatChannelData, let dstF = dest.floatChannelData {
            for ch in 0..<channels {
                memcpy(dstF[ch], srcF[ch] + startFrame, frameCount * MemoryLayout<Float>.size)
            }
        } else if let srcI = source.int16ChannelData, let dstI = dest.int16ChannelData {
            for ch in 0..<channels {
                memcpy(dstI[ch], srcI[ch] + startFrame, frameCount * MemoryLayout<Int16>.size)
            }
        } else if let srcI = source.int32ChannelData, let dstI = dest.int32ChannelData {
            for ch in 0..<channels {
                memcpy(dstI[ch], srcI[ch] + startFrame, frameCount * MemoryLayout<Int32>.size)
            }
        } else {
            return nil
        }
        return dest
    }
}
