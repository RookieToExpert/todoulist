# TudouList

TudouList 是一个 macOS 原生 SwiftUI 计划表 / Todo / Goal Planning 应用。它面向层级化目标管理，支持从「计划表」拆解到「年目标 -> 月目标 -> 周目标 -> 日目标」。

## 如何运行

当前项目使用 Swift Package 形式组织，最低支持 macOS 14。当前开发环境缺少 SwiftData 宏插件，因此持久化采用 `Codable + JSON` 本地文件方案，数据保存到用户 Application Support 目录下的 `TudouList/store.json`。

```bash
swift build
swift run TudouList
```

如果本机只有 Command Line Tools，且出现 SDK / Swift toolchain 不匹配错误，请安装完整 Xcode，或在 Xcode 设置中选择与当前 Swift 编译器匹配的 Command Line Tools。

## 打包成可双击打开的 App

可以运行下面的脚本生成 macOS App Bundle 和 zip 包：

```bash
./package-app.sh
```

生成文件：

```text
dist/TudouList.app
dist/TudouList-macOS.zip
```

把 `dist/TudouList-macOS.zip` 上传到 GitHub Release 后，用户下载、解压，就可以像普通 App 一样双击打开。当前脚本使用 ad-hoc codesign，适合本地和内部测试；如果要让陌生用户下载后完全无 Gatekeeper 提示，需要 Apple Developer ID 签名并 notarize。

## 已实现功能

- 多计划表管理：新增、重命名、删除计划表。
- 三栏 macOS 原生布局：左侧计划表，中间目标层级列表，右侧目标详情编辑。
- 目标层级：支持年、月、周、日四级目标，并限制创建合法下一级。
- 目标编辑：支持标题、备注、完成状态、加急状态编辑。
- 完成时间：完成目标时自动写入 `completedAt`，取消完成时清空。
- 层级展示：年 -> 月 -> 周 -> 日 递归缩进展示，支持折叠 / 展开。
- 排序规则：同级目标中加急优先、未完成优先，其次按 `sortOrder` 和创建时间排序。
- 删除确认：删除计划表或目标前确认；删除目标会同时删除子目标。
- 本地持久化：使用 Codable + JSON 保存数据，关闭 App 后重新打开仍然存在。
- 浅色 / 深色模式：使用系统颜色与材质，跟随 macOS 外观。

## 主要文件结构

```text
Package.swift
Sources/TudouList/
  TudouListApp.swift
  Models/
    Goal.swift
    GoalLevel.swift
    PlanList.swift
  Stores/
    PlanningStore.swift
  Views/
    ContentView.swift
    EmptyStateView.swift
    GoalBoardView.swift
    GoalDetailView.swift
    GoalRowView.swift
    PlanSidebarView.swift
```

## 后续可扩展方向

- 拖拽调整同级目标顺序，并写回 `sortOrder`。
- 为计划表增加描述编辑入口和统计信息。
- 增加目标搜索、筛选和按日期聚合视图。
- 增加快捷键，例如快速新建年目标 / 下一级目标。
- 增加单元测试，覆盖 Store 的层级删除、排序和完成状态逻辑。
