import SwiftUI
import NotchNotification

struct SettingsView: View {
    @AppStorage("showMenuBarButtons") private var showMenuBarButtons = true
    @AppStorage("hoverShowDelay") private var hoverShowDelay = 0.18
    @AppStorage("hoverHideDelay") private var hoverHideDelay = 0.28

    private let delayRange: ClosedRange<Double> = 0...1.5
    private let step: Double = 0.05

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("在菜单栏显示切换按钮", isOn: $showMenuBarButtons)

            VStack(alignment: .leading, spacing: 8) {
                Text("刘海触发延迟（秒）")
                    .font(.headline)
                delayRow(title: "展开延迟", value: $hoverShowDelay)
                delayRow(title: "关闭延迟", value: $hoverHideDelay)
            }
        }
        .padding(20)
        .frame(width: 360, height: 200, alignment: .topLeading)
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
