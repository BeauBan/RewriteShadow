# RewriteShadow

[English](README.md)

轻量级 macOS 菜单栏中文写作助手。输入词语或句子，使用你自己的大模型 API Key 生成更合适的替换词与改写结果，无需后端。

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-111111?style=flat" />
  <img src="https://img.shields.io/badge/Language-Swift-f05138?style=flat" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-0a84ff?style=flat" />
  <img src="https://img.shields.io/badge/App-Menu%20Bar-333333?style=flat" />
</p>

<p align="center">
  <img src="app/Sources/RewriteShadow/Resources/Assets.xcassets/AppIcon.appiconset/icon_512.png" alt="RewriteShadow 图标" width="160" height="160" />
</p>

<p align="center">
  <strong>极简、快速、专注</strong>
</p>

---

## 亮点
- 菜单栏小面板，打开即用
- 词语替换并附使用提示
- 句子改写支持口语与书面风格
- 可调灵活程度（temperature）
- 支持多个主流模型接口与 OpenAI 兼容接口

---


## 快速开始
**Xcode（推荐）**
1. 打开 `RewriteShadow.xcodeproj`
2. 选择 Scheme：`RewriteShadow`
3. 运行：`Cmd+R`

**SwiftPM（开发调试）**
```bash
cd app
swift run
```

---

## 使用方式
1. 点击菜单栏图标。
2. 选择 `词语` 或 `句子` 模式。
3. 输入内容并点击 `查询`。
4. 点击结果即可复制。

---

## 设置说明
所有设置均在应用内完成，并只保存在本机 UserDefaults。

- Provider：OpenAI、OpenAI Compatible、Anthropic、Gemini
- API Base URL
- API Key
- Model
- Temperature
- 返回数量

密钥不会上传到任何服务器，本仓库也不包含任何密钥信息。

---

## 项目结构
- `app/` SwiftUI 源码（SwiftPM）
- `RewriteShadow.xcodeproj/` 用于构建与分发

---

## Roadmap
- 写作风格预设
- 更细的改写与语气控制
- 复制与历史记录优化

---

## 许可证
请在此处填写开源协议（例如 MIT）。
