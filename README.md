# RewriteShadow

A minimal macOS menu bar assistant for Chinese writing. Enter a word or a sentence and get cleaner alternatives or rewrites using your own LLM API key—no backend required.

![RewriteShadow Icon](app/Sources/RewriteShadow/Resources/Assets.xcassets/AppIcon.appiconset/icon_512.png)

---

## Why RewriteShadow
- Fast, single‑purpose UI
- Word replacements with usage notes
- Sentence rewrites in **Casual** or **Formal** tone
- Adjustable creativity (temperature)
- Works with multiple LLM providers

---

## Quick Start
**Xcode (recommended)**
1. Open `RewriteShadow.xcodeproj`
2. Select scheme `RewriteShadow`
3. Run (⌘R)

**SwiftPM (dev)**
```bash
cd app
swift run
```

---

## How It Works
- **Word mode**: replaces a word with better alternatives
- **Sentence mode**: rewrites a sentence into casual or formal style
- **Settings**: configure provider, API key, model, and creativity

Your API key is stored locally in macOS UserDefaults and is never included in this repository.

---

## Project Structure
- `app/` SwiftUI app source
- `RewriteShadow.xcodeproj/` Xcode project for building and distribution

---

## License
Add your license here (e.g., MIT).
