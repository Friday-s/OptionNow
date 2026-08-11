# OptionNow

OptionNow 是一个 macOS 菜单栏小工具入口。按下 `⌥ Space`，即可在鼠标附近唤出拨盘，并打开外部应用、系统访达、最近使用或设置。

当前本地测试构建面向 macOS 26；后续使用完整 Xcode 工程验证更低系统版本兼容性。

## 当前版本

- 全局快捷键：`⌥ Space`
- 纯圆形快捷拨盘，无外层矩形容器
- 拨盘每页 4、6、8 项
- 自动识别独立 Orbit、SendLingo 与 ClipMate
- Orbit 与 SendLingo 使用本机通知直接唤出面板；ClipMate 使用系统窗口激活
- 点击“访达”直接打开系统 Finder
- 最近使用持久化，并可点击再次执行
- 自定义快捷键与冲突提示、登录时启动
- 添加、删除、排序应用、文件夹和网页入口
- 键盘选择、滚轮/滑动分页、按住滑向扇区松开执行
- 深浅色、强调色、透明度和图标大小设置
- 本地设置持久化

## 构建

```bash
./Scripts/validate.sh
./Scripts/build_app.sh
./Scripts/lifecycle_test.sh
```

生成的应用位于相邻输出目录的 `OptionNow.app`。

## 首次使用

1. 启动 OptionNow。
2. 点击菜单栏的 OptionNow 图标，进入设置。
3. Orbit、SendLingo 和 ClipMate 会自动识别；未找到时也可以手动选择 `.app`。
4. 按 `⌥ Space` 唤出工具菜单。

## 操作

- 鼠标经过扇区后单击打开。
- 方向键选择，`Return` 打开，`Esc` 关闭。
- 滚轮或左右滑动切换分页。
- 设置中可启用“按住快捷键滑向扇区，松开执行”。

目前应用使用本地临时签名，尚未进行 Apple 开发者公证。
