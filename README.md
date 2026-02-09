# RewriteShadow

[中文说明](README.zh-CN.md)

Lightweight macOS menu bar assistant for Chinese writing. Generate better word choices and sentence rewrites using your own LLM API key—no backend required.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-111111?style=flat" />
  <img src="https://img.shields.io/badge/Language-Swift-f05138?style=flat" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-0a84ff?style=flat" />
  <img src="https://img.shields.io/badge/App-Menu%20Bar-333333?style=flat" />
</p>

<p align="center">
  <img src="app/Sources/RewriteShadow/Resources/Assets.xcassets/AppIcon.appiconset/icon_512.png" alt="RewriteShadow Icon" width="160" height="160" />
</p>

<p align="center">
  <strong>Minimal. Fast. Focused.</strong>
</p>

---

## Highlights
- Menu bar app with a compact panel
- Word alternatives with usage hints
- Sentence rewrites with Casual and Formal styles
- Adjustable creativity (temperature)
- Works with multiple providers and OpenAI-compatible endpoints

---

## Screenshots
<p align="center">
  <img src="assets/word-mode.png" width="420" />
  <img src="assets/sentence-mode.png" width="420" />
</p>
<p align="center">
  <strong>Word Mode</strong> · <strong>Sentence Mode</strong>
</p>

<p align="center">
  <img src="assets/settings.png" width="520" />
</p>
<p align="center">
  <strong>Settings</strong>
</p>

<p align="center">
  <img src="assets/menu-bar-icon.png" width="56" />
</p>
<p align="center">
  <strong>Menu Bar Icon</strong>
</p>

---

## Download
Get the latest build from GitHub Releases: [Download RewriteShadow](https://github.com/BeauBan/RewriteShadow/releases)

---

## Quick Start
**Xcode (recommended)**
1. Open `RewriteShadow.xcodeproj`
2. Select scheme `RewriteShadow`
3. Run with `Cmd+R`

**SwiftPM (dev)**
```bash
cd app
swift run
```

---

## Usage
1. Click the menu bar icon.
2. Choose `Word` or `Sentence` mode.
3. Enter text and press `Query`.
4. Click any result to copy it.

---

## Configuration
All settings live in the app UI and are stored locally in macOS UserDefaults.

- Provider: OpenAI, OpenAI Compatible, Anthropic, Gemini
- API Base URL
- API Key
- Model
- Temperature
- Result count

Your API key stays on your machine and is never written to this repo.

---

## Project Structure
- `app/` SwiftUI app source (SwiftPM)
- `RewriteShadow.xcodeproj/` Xcode project for building and distribution

---

## License
Add your license here (e.g., MIT).
