import SwiftUI
import NotchNotification
import LaunchAtLogin

struct SettingsView: View {
    @AppStorage("showMenuBarButtons") private var showMenuBarButtons = false
    @AppStorage("hoverShowDelay") private var hoverShowDelay = 0.0
    @AppStorage("hoverHideDelay") private var hoverHideDelay = 0.08

    private let delayRange: ClosedRange<Double> = 0...1.5
    private let step: Double = 0.05

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("在菜单栏显示切换按钮", isOn: $showMenuBarButtons)
            if !showMenuBarButtons {
                Text("在刘海区域右键即可打开设置")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            LaunchAtLogin.Toggle("登录时自动打开")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("刘海触发延迟（秒）")
                        .font(.headline)
                    Spacer()
                    Button("恢复默认") {
                        hoverShowDelay = 0.0
                        hoverHideDelay = 0.08
                    }
                    .buttonStyle(.link)
                }
                delayRow(title: "展开延迟", value: $hoverShowDelay)
                delayRow(title: "关闭延迟", value: $hoverHideDelay)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("切换到左侧桌面", systemImage: "arrow.left")
                Label("显示 Mission Control", systemImage: "rectangle.3.group")
                Label("切换到右侧桌面", systemImage: "arrow.right")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 360, height: 250, alignment: .topLeading)
        .onChange(of: showMenuBarButtons) { _ in
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
            if showMenuBarButtons == false {
                NotchNotification.present(
                    message: "菜单栏图标已隐藏，下次启动将自动打开设置"
                )
            }
        }
        .onChange(of: hoverShowDelay) { _ in
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
        .onChange(of: hoverHideDelay) { _ in
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    @ViewBuilder
    private func delayRow(title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Stepper(value: value, in: delayRange, step: step) {
                Text(String(format: "%.2f", value.wrappedValue))
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    SettingsView()
}
