# RewriteShadow

一个极简的 macOS 菜单栏写作助手。输入中文词语或句子，使用你自己的大模型 API Key 获取更合适的替换词或改写结果，无需后端。

![RewriteShadow 图标](app/Sources/RewriteShadow/Resources/Assets.xcassets/AppIcon.appiconset/icon_512.png)

---

## 为什么是 RewriteShadow
- 快速、克制的菜单栏界面
- 词语替换 + 用法说明
- 句子改写（口语 / 书面）
- 可调“灵活程度”（temperature）
- 支持多个主流模型接口

---

## 快速开始
**Xcode（推荐）**
1. 打开 `RewriteShadow.xcodeproj`
2. 选择 Scheme：`RewriteShadow`
3. 运行（⌘R）

**SwiftPM（开发调试）**
```bash
cd app
swift run
```

---

## 使用方式
- **词语模式**：替换词语并给出简短说明
- **句子模式**：输出口语或书面风格改写
- **设置**：配置接口、API Key、模型与灵活程度

API Key 只保存在本机 UserDefaults，本仓库不包含任何密钥信息。

---

## 项目结构
- `app/` SwiftUI 源码
- `RewriteShadow.xcodeproj/` 用于构建与分发

---

## 许可证
请在此处填写开源协议（例如 MIT）。
