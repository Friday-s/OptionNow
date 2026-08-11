import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            if let message = settings.configurationMessage {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                        Spacer()
                        Button("关闭") { settings.configurationMessage = nil }
                    }
                }
            }

            Section("唤出方式") {
                LabeledContent("全局快捷键") {
                    Text("⌥ Space")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
                }
                Text("第一版使用固定快捷键，后续加入快捷键录制与冲突检测。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("圆形拨盘") {
                Picker("每页项目", selection: $settings.sectorCount) {
                    Text("4").tag(4)
                    Text("6").tag(6)
                    Text("8").tag(8)
                }
                .pickerStyle(.segmented)
            }

            Section("工具") {
                ForEach($settings.toolItems) { $item in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $item.isEnabled)
                            .labelsHidden()
                        Image(systemName: item.symbol)
                            .frame(width: 22)
                        TextField("名称", text: $item.name)
                            .frame(width: 110)
                        Spacer()
                        if item.kind == .externalApplication {
                            Text(settings.applicationStatus(for: item))
                                .foregroundStyle(settings.applicationStatus(for: item) == "未绑定" ? Color.red : Color.secondary)
                                .lineLimit(1)
                            Button("选择应用…") { settings.chooseApplication(for: item.id) }
                        } else {
                            Text(settings.applicationStatus(for: item))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 620, height: 520)
        .navigationTitle("OptionNow 设置")
    }
}
