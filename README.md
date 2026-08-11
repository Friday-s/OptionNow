# OptionNow

OptionNow 是一个 macOS 菜单栏小工具入口。按下 `⌥ Space`，即可在鼠标附近唤出拨盘，并打开外部应用、系统访达、最近使用或设置。

当前本地测试构建面向 macOS 26；后续使用完整 Xcode 工程验证更低系统版本兼容性。

## 当前版本

- 全局快捷键：`⌥ Space`
- 纯圆形快捷拨盘，无外层矩形容器
- 拨盘每页 4、6、8 项
- 自动识别独立 Orbit 与 ClipMate，翻译应用可手动绑定
- 点击 Orbit 会通过本机分布式通知直接唤出待办面板
- 点击“访达”直接打开系统 Finder
- 最近使用记录
- 本地设置持久化

## 构建

```bash
./Scripts/validate.sh
./Scripts/build_app.sh
```

生成的应用位于相邻输出目录的 `OptionNow.app`。

## 首次使用

1. 启动 OptionNow。
2. 点击菜单栏的 OptionNow 图标，进入设置。
3. Orbit 和 ClipMate 会自动识别；只需为尚未找到的翻译工具选择 `.app`。
4. 按 `⌥ Space` 唤出工具菜单。

目前应用使用本地临时签名，尚未进行 Apple 开发者公证。
