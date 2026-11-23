import SwiftUI

struct ContentView: View {
    @StateObject private var model = SpeakerModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("声音来自 Taptic Engine 敲击机身，不走扬声器。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("心跳") {
                            model.heartbeat()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.busy)

                        Button("小星星") {
                            model.twinkle()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.busy)

                        Button("两只老虎") {
                            model.twoTigers()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.busy)
                    }

                    HStack {
                        Button("扫频") {
                            model.sweep()
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.busy)

                        Button("停止") {
                            model.stop()
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(model.status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("和 Mac 触控板的差别")
                            .font(.headline)
                        Text("Mac 版用私有接口把触控板马达驱动到大约 4 kHz。iOS 只能控制震动的强度和尖锐度，听得见的范围大约是几十到三百赫兹。")
                        Text("摘掉保护壳，屏幕朝下平放在硬桌面上，耳朵贴着桌面，会比握在手里响得多。")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("无扬声器")
        }
    }
}
