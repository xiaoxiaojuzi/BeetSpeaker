import CoreHaptics
import Foundation

enum HapticSpeakerError: LocalizedError {
    case unsupported
    case engineUnavailable

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "这台设备没有 Taptic Engine（模拟器也不行）。请用真机。"
        case .engineUnavailable:
            return "触觉引擎没有启动。"
        }
    }
}

/// 把一串帧变成触觉事件：有音高就按周期打点，没有音高就用短连续震动。
final class HapticSpeaker {
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    var isPlaying: Bool { player != nil }

    static var hardwareSupportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func prepare() throws {
        guard Self.hardwareSupportsHaptics else { throw HapticSpeakerError.unsupported }
        if engine != nil { return }
        let engine = try CHHapticEngine()
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = true
        engine.stoppedHandler = { [weak self] _ in
            self?.player = nil
        }
        engine.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        self.engine = engine
        try engine.start()
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop()
        engine = nil
    }

    func play(frames: [VoiceFrame]) throws {
        guard !frames.isEmpty else { return }
        try prepare()
        guard let engine else { throw HapticSpeakerError.engineUnavailable }
        try? player?.stop(atTime: CHHapticTimeImmediate)

        let events = events(from: frames)
        guard !events.isEmpty else { return }
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        self.player = player
        try engine.start()
        try player.start(atTime: CHHapticTimeImmediate)
    }

    /// 浊音：每个基频周期一个 transient。清音：10 ms 的高尖锐度连续震动。
    /// 单次 pattern 的事件太多时 Core Haptics 会拒绝，所以超过约 2 秒会由调用方分段。
    private func events(from frames: [VoiceFrame]) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var nextPulse = frames.first?.time ?? 0

        for frame in frames where frame.intensity > 0.02 {
            // 连续满幅震动负责响度。Taptic 在偏低尖锐度时带动的机身振幅更大。
            let bodySharpness = min(0.55, max(0.2, frame.sharpness * 0.45))
            events.append(continuous(
                at: frame.time,
                duration: frame.duration,
                intensity: 1,
                sharpness: bodySharpness
            ))
            if let pitch = frame.pitch, pitch >= 18, pitch <= 220 {
                let period = 1.0 / Double(pitch)
                var t = max(frame.time, nextPulse)
                let end = frame.time + frame.duration
                while t < end - 0.0005 {
                    events.append(transient(at: t, intensity: 1, sharpness: 0.35))
                    t += period
                }
                nextPulse = t
            } else {
                nextPulse = frame.time + frame.duration
            }
        }
        return events
    }

    private func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: clamp(sharpness))
            ],
            relativeTime: time
        )
    }

    private func continuous(at time: TimeInterval, duration: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamp(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: clamp(sharpness))
            ],
            relativeTime: time,
            duration: max(0.008, duration)
        )
    }

    private func clamp(_ value: Float) -> Float {
        min(1, max(0, value))
    }
}
