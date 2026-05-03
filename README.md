# QuickNew

macOS Finder 右键菜单扩展，在 Finder 和桌面空白处右键即可快速创建文件和文件夹。

## 功能

固定 8 种新建类型：

- 文件夹
- 文本文件 (.txt)
- Markdown (.md)
- RTF (.rtf)
- Word (.docx)
- Excel (.xlsx)
- PowerPoint (.pptx)
- CSV (.csv)

菜单固定不可编辑，无需配置，开箱即用。

## 安装

1. 将 QuickNew.app 拖入「应用程序」文件夹
2. 打开 QuickNew，点击工具栏「启用扩展」
3. 在系统设置中打开 QuickNew 的 Finder 扩展开关
4. 重启 Finder（点击工具栏「重启 Finder」）
5. 在 Finder 或桌面空白处右键，即可看到「新建」菜单

## 系统要求

- macOS 14.0 (Sonoma) 及以上
- Xcode 16+
- Swift 6

## 技术架构

- **FinderSync Extension** — 右键菜单由 Finder Sync 扩展直接提供，无需打开主 App
- **无 TCC 授权** — 扩展通过 FinderSync 框架获取目录访问权限，不使用 Security-Scoped Bookmarks，避免权限提示
- **无 App Groups** — 扩展不依赖共享容器，主 App 与扩展完全解耦
- **固定菜单** — 8 种常用文件类型硬编码在扩展中
- **Office 模板** — Word / Excel / PPT 使用内置模板创建，保证格式正确

## 构建

```bash
# 安装 xcodegen
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 构建
xcodebuild -project RightMenu.xcodeproj -scheme RightMenu -configuration Debug build

# 测试
xcodebuild -project RightMenu.xcodeproj -scheme RightMenu -configuration Debug test
```

## 项目结构

```
├── RightMenu/                          # 主 App（扩展管理、语言设置）
│   ├── RightMenuApp.swift              # App 入口
│   ├── ContentView.swift               # 主界面
│   ├── SettingsView.swift              # 设置（语言）
│   ├── AuthorizationStatusStore.swift   # 扩展启用状态
│   ├── ExtensionManager.swift          # 扩展注册
│   └── LanguageSettingsStore.swift      # 语言偏好
├── RightMenuFinderExtension/           # Finder Sync 扩展
│   ├── FinderSyncController.swift      # 右键菜单实现（核心）
│   └── Info.plist
├── Shared/                             # 共享代码
│   ├── MenuItemKind.swift              # 文件类型定义
│   ├── FileCreationService.swift       # 文件创建逻辑
│   ├── MenuItemIcon.swift              # 图标
│   ├── PreferencesStore.swift          # 偏好存储
│   ├── MenuPreferences.swift           # 菜单配置
│   ├── DirectoryAuthorizationStore.swift # 目录授权
│   └── AppConstants.swift              # 常量与本地化
├── Resources/                          # 资源
│   ├── FileIcons/                      # SVG 图标
│   ├── template-docx.docx              # Word 模板
│   ├── template-xlsx.xlsx              # Excel 模板
│   └── template-pptx.pptx              # PPT 模板
└── RightMenuTests/                     # 单元测试
```

## 本地化

支持中文（简体/繁体）和英文，跟随系统语言设置，可在设置中切换。

## License

MIT
