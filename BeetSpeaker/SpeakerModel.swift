import Foundation

@MainActor
final class SpeakerModel: ObservableObject {
    @Published var status = "把手机放在桌上，耳朵靠近，系统音量可以调到零。"
    @Published var busy = false

    private let speaker = HapticSpeaker()
    private var playbackTask: Task<Void, Never>?

    func heartbeat() {
        playPattern(SpeechToHaptic.heartbeat(), status: "心跳：每分钟大约 64 下，先重后轻。")
    }

    func twinkle() {
        playPattern(SpeechToHaptic.twinkle(), status: "小星星。旋律在 131–220 Hz。")
    }

    func twoTigers() {
        playPattern(SpeechToHaptic.twoTigers(), status: "两只老虎。旋律在 98–220 Hz。")
    }

    func sweep() {
        stop()
        busy = true
        status = "扫频：80 Hz 到 280 Hz。贴着桌面更能听见。"
        let frames = SpeechToHaptic.sweep()
        playbackTask = Task { [weak self] in
            await self?.play(frames: frames)
        }
    }

    private func playPattern(_ frames: [VoiceFrame], status: String) {
        stop()
        busy = true
        self.status = status
        playbackTask = Task { [weak self] in
            await self?.play(frames: frames)
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        speaker.stop()
        busy = false
    }

    /// Core Haptics 对超长 pattern 不稳定，按大约 1.5 秒切段接着放。
    private func play(frames: [VoiceFrame]) async {
        let slice = 1.5
        var index = 0
        do {
            while index < frames.count {
                if Task.isCancelled { break }
                let start = frames[index].time
                var end = index
                while end < frames.count, frames[end].time - start < slice {
                    end += 1
                }
                let chunk = frames[index..<end].map { frame in
                    VoiceFrame(
                        time: frame.time - start,
                        duration: frame.duration,
                        intensity: frame.intensity,
                        sharpness: frame.sharpness,
                        pitch: frame.pitch
                    )
                }
                try speaker.play(frames: Array(chunk))
                let wait = chunk.last.map { $0.time + $0.duration } ?? 0
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                index = end
            }
            if !Task.isCancelled {
                status = "放完了。"
            }
        } catch {
            status = error.localizedDescription
        }
        busy = false
        speaker.stop()
    }
}
