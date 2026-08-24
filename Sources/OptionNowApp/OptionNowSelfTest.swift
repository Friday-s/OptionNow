import Foundation

@MainActor
enum OptionNowSelfTest {
    static func run() -> Int32 {
        var passed = 0
        var failed = 0
        func check(_ name: String, _ condition: Bool) {
            print("\(condition ? "PASS" : "FAIL"): \(name)")
            condition ? (passed += 1) : (failed += 1)
        }

        let oldJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","name":"翻译","symbol":"character.bubble","kind":"externalApplication","isEnabled":true}
        """.data(using: .utf8)!
        let migrated = try? JSONDecoder().decode(ToolItem.self, from: oldJSON)
        check("旧配置可迁移", migrated?.integrationID == nil && migrated?.name == "翻译")

        let sendLingo = ToolItem.defaults.first { $0.integrationID == "sendlingo" }!
        check("SendLingo 使用稳定集成 ID", ApplicationIntegration.matching(sendLingo)?.bundleIdentifier == "com.ivor.sendlingo")

        let clipMate = ToolItem.defaults.first { $0.integrationID == "clipmate" }!
        let clipMateIntegration = ApplicationIntegration.matching(clipMate)
        check(
            "ClipMate 隐藏实例使用重启策略",
            clipMateIntegration?.terminateWhenClosing == true && clipMateIntegration?.showPanelNotification == nil
        )

        let recent = RecentAction(item: sendLingo)
        let recentRoundTrip = try? JSONDecoder().decode(
            RecentAction.self,
            from: JSONEncoder().encode(recent)
        )
        check("最近使用可持久化并恢复动作", recentRoundTrip?.item.integrationID == "sendlingo")
        check("默认快捷键显示正确", HotKeyConfiguration.defaultValue.displayName == "⌥ Space")

        let items = (0..<8).map { index in
            ToolItem(
                id: UUID(),
                name: "Item \(index)",
                symbol: "app",
                kind: .externalApplication,
                applicationPath: nil,
                isEnabled: true,
                integrationID: nil
            )
        }
        let interaction = LauncherInteractionState()
        check("8 项按 4 项分页", interaction.visibleItems(from: items, capacity: 4).count == 4)
        interaction.changePage(in: items, capacity: 4, delta: 1)
        check("分页可切换到第二页", interaction.currentPage == 1)
        interaction.moveSelection(in: items, capacity: 4, delta: 1)
        check("键盘可选择当前页项目", interaction.highlightedID == items[4].id)

        print("SELFTEST RESULT: \(passed) passed, \(failed) failed")
        return failed == 0 ? 0 : 1
    }
}
