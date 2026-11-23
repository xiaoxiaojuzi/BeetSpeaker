import Foundation

/// 10 ms 一帧。iPhone 的 Taptic Engine 不能播放任意正弦，只能用强度、尖锐度和音高周期驱动 Core Haptics。
struct VoiceFrame {
    var time: TimeInterval
    var duration: TimeInterval
    var intensity: Float
    var sharpness: Float
    /// 浊音基频；清音为 nil。
    var pitch: Float?
}

enum SpeechToHaptic {
    static let frameSeconds = 0.010

    /// 100 Hz → 250 Hz 的扫频，落在 Taptic 听得见的谐振附近。
    static func sweep(from startHz: Float = 80, to endHz: Float = 280, seconds: Double = 4) -> [VoiceFrame] {
        let hop = frameSeconds
        let n = max(1, Int(seconds / hop))
        return (0..<n).map { i in
            let t = Double(i) / Double(n - 1)
            let hz = startHz * pow(endHz / startHz, Float(t))
            return VoiceFrame(
                time: Double(i) * hop,
                duration: hop,
                intensity: 0.85,
                sharpness: min(1, max(0, (hz - 80) / 200)),
                pitch: hz
            )
        }
    }

    /// 小星星，从低音 Do 起，最高音 La 约 220 Hz。
    static func twinkle() -> [VoiceFrame] {
        let q = 0.36
        let h = q * 2
        let c: Float = 130.81
        let d: Float = 146.83
        let e: Float = 164.81
        let f: Float = 174.61
        let g: Float = 196
        let a: Float = 220
        return tune([
            (c, q), (c, q), (g, q), (g, q), (a, q), (a, q), (g, h),
            (f, q), (f, q), (e, q), (e, q), (d, q), (d, q), (c, h),
            (g, q), (g, q), (f, q), (f, q), (e, q), (e, q), (d, h),
            (g, q), (g, q), (f, q), (f, q), (e, q), (e, q), (d, h),
            (c, q), (c, q), (g, q), (g, q), (a, q), (a, q), (g, h),
            (f, q), (f, q), (e, q), (e, q), (d, q), (d, q), (c, h)
        ])
    }

    /// 两只老虎，同一调，最高音 La 约 220 Hz。
    static func twoTigers() -> [VoiceFrame] {
        let q = 0.34
        let e8 = q / 2
        let c: Float = 130.81
        let d: Float = 146.83
        let e: Float = 164.81
        let f: Float = 174.61
        let g: Float = 196
        let a: Float = 220
        let g2: Float = 98
        return tune([
            (c, q), (d, q), (e, q), (c, q),
            (c, q), (d, q), (e, q), (c, q),
            (e, q), (f, q), (g, q * 2),
            (e, q), (f, q), (g, q * 2),
            (g, e8), (a, e8), (g, e8), (f, e8), (e, q), (c, q),
            (g, e8), (a, e8), (g, e8), (f, e8), (e, q), (c, q),
            (c, q), (g2, q), (c, q * 2),
            (c, q), (g2, q), (c, q * 2)
        ])
    }

    /// 每个音后面留一点空隙，避免两颗音粘成一段嗡鸣。音高为 nil 时是休止。
    private static func tune(_ notes: [(Float?, Double)]) -> [VoiceFrame] {
        let hop = frameSeconds
        let gap = 0.04
        var frames: [VoiceFrame] = []
        var time = 0.0
        for (pitch, duration) in notes {
            var elapsed = 0.0
            while elapsed < duration - 0.0001 {
                let sounding = pitch != nil && elapsed < max(hop, duration - gap)
                frames.append(VoiceFrame(
                    time: time,
                    duration: hop,
                    intensity: sounding ? 1 : 0,
                    sharpness: 0.28,
                    pitch: sounding ? pitch : nil
                ))
                elapsed += hop
                time += hop
            }
        }
        return frames
    }

    /// 静息心跳大约每分钟 64 下：较重的「lub」隔一小段再来较轻的「dub」。
    static func heartbeat(seconds: Double = 8) -> [VoiceFrame] {
        let hop = frameSeconds
        let beat = 60.0 / 64.0
        var frames: [VoiceFrame] = []
        var time = 0.0
        while time < seconds {
            let phase = time.truncatingRemainder(dividingBy: beat)
            let (intensity, sharpness): (Float, Float)
            if phase < 0.09 {
                (intensity, sharpness) = (1, 0.12)
            } else if phase >= 0.20 && phase < 0.27 {
                (intensity, sharpness) = (0.7, 0.22)
            } else {
                (intensity, sharpness) = (0, 0)
            }
            frames.append(VoiceFrame(
                time: time,
                duration: hop,
                intensity: intensity,
                sharpness: sharpness,
                pitch: nil
            ))
            time += hop
        }
        return frames
    }
}
