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

            Section("唤出与启动") {
                LabeledContent("全局快捷键") {
                    HotKeyRecorderView(configuration: $settings.hotKey)
                }
                if settings.hotKeyConflict {
                    Label("这个快捷键已被其他应用占用，OptionNow 保留原快捷键。", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("点击快捷键框，然后按下带 ⌃、⌥、⇧ 或 ⌘ 的新组合。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Toggle("登录时自动启动", isOn: $settings.launchAtLogin)
                Toggle("点击圆盘外侧后关闭", isOn: $settings.closeOnDeactivate)
                Toggle("按住快捷键滑向扇区，松开执行", isOn: $settings.releaseToSelect)
                Toggle("显示最近使用入口", isOn: $settings.showRecents)
                Picker("拨盘位置", selection: $settings.launcherPosition) {
                    ForEach(LauncherPosition.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
            }

            Section("圆形拨盘") {
                Picker("每页项目", selection: $settings.sectorCount) {
                    Text("4").tag(4)
                    Text("6").tag(6)
                    Text("8").tag(8)
                }
                .pickerStyle(.segmented)
                Picker("主题", selection: $settings.launcherTheme) {
                    ForEach(LauncherTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Picker("强调色", selection: $settings.launcherAccent) {
                    ForEach(LauncherAccent.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                LabeledContent("面板透明度") {
                    Slider(value: $settings.panelOpacity, in: 0.65...1)
                        .frame(width: 220)
                }
                LabeledContent("图标大小") {
                    Slider(value: $settings.iconSize, in: 16...28, step: 1)
                        .frame(width: 220)
                }
                Text("方向键选择，Return 打开，Esc 关闭；滚轮或左右滑动可切换分页。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("工具") {
                ForEach($settings.toolItems) { $item in
                    ToolEditorRow(item: $item, settings: settings)
                }

                Menu("添加工具") {
                    Button("应用") { settings.addTool(kind: .externalApplication) }
                    Button("文件夹") { settings.addTool(kind: .folder) }
                    Button("网页") { settings.addTool(kind: .url) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 700, height: 720)
        .navigationTitle("OptionNow 设置")
    }
}

private struct ToolEditorRow: View {
    @Binding var item: ToolItem
    @ObservedObject var settings: SettingsStore

    private var isCustom: Bool { item.integrationID == nil }
    private var index: Int? { settings.toolItems.firstIndex(where: { $0.id == item.id }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Toggle("", isOn: $item.isEnabled)
                    .labelsHidden()
                Image(systemName: item.symbol)
                    .frame(width: 22)
                TextField("名称", text: $item.name)
                    .frame(width: 120)
                if isCustom {
                    TextField("SF Symbol", text: $item.symbol)
                        .frame(width: 110)
                    Picker("", selection: $item.kind) {
                        Text("应用").tag(ToolKind.externalApplication)
                        Text("文件夹").tag(ToolKind.folder)
                        Text("网页").tag(ToolKind.url)
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }
                Spacer()
                Button { settings.moveTool(id: item.id, offset: -1) } label: { Image(systemName: "chevron.up") }
                    .disabled(index == 0)
                Button { settings.moveTool(id: item.id, offset: 1) } label: { Image(systemName: "chevron.down") }
                    .disabled(index == settings.toolItems.count - 1)
                if isCustom {
                    Button(role: .destructive) { settings.removeTool(id: item.id) } label: {
                        Image(systemName: "trash")
                    }
                }
            }

            HStack {
                Spacer().frame(width: 38)
                targetEditor
            }
        }
        .padding(.vertical, 3)
    }

    @ViewBuilder
    private var targetEditor: some View {
        switch item.kind {
        case .externalApplication:
            Text(settings.applicationStatus(for: item))
                .foregroundStyle(settings.applicationStatus(for: item) == "未绑定" ? Color.red : Color.secondary)
                .lineLimit(1)
            Spacer()
            Button("选择应用…") { settings.chooseApplication(for: item.id) }
        case .folder:
            Text(item.applicationPath ?? "未选择文件夹")
                .foregroundStyle(item.applicationPath == nil ? Color.red : Color.secondary)
                .lineLimit(1)
            Spacer()
            Button("选择文件夹…") { settings.chooseFolder(for: item.id) }
        case .url:
            TextField("https://", text: Binding(
                get: { item.applicationPath ?? "" },
                set: { item.applicationPath = $0 }
            ))
        case .files, .recents, .settings:
            Text(settings.applicationStatus(for: item))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
