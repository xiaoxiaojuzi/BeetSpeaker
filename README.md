# 无扬声器

把 [nospeaker](https://github.com/os6/nospeaker) 的想法搬到 iPhone：不走扬声器，用 Taptic Engine 播放低频节奏和旋律。

## 播放

心跳，两只老虎，小星星

## 和 Mac 版的差别

Mac 触控板通过私有的 `MultitouchSupport` 接受任意频率的正弦，大约 100 Hz 到 4 kHz，所以能用两个共振峰合成语音。

iOS 公开接口只有 Core Haptics 的强度和尖锐度。Taptic Engine 是谐振马达，听得见的范围大致在几十到三百赫兹。App 用这个范围播放心跳、小星星、两只老虎和一段扫频，`playsHapticsOnly` 让扬声器保持安静。

手机平放在硬桌面上、耳朵贴着桌面，会清楚一些。模拟器没有马达。

最低系统是 iOS 17，在 iOS 26 / 27 上用的是同一套 Core Haptics。

## 打开

安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 后：

```sh
xcodegen generate
open BeetSpeaker.xcodeproj
```

选一台真机，运行。系统音量可以调到零。
