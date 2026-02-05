# SynonymBar (菜单栏同义词面板)

一个极简的 macOS 菜单栏小工具：输入中文词语，直接调用大模型接口返回可替换词语与简短用法说明，方便写作时快速选择。

## 结构
- `app/`：SwiftUI 菜单栏应用（前端直连 API，无后端）。

## 运行
> 需要 macOS 13+（`MenuBarExtra`）。

方式 A：使用 Xcode 打开 `app/Package.swift` 并运行。

方式 B：命令行运行：
```bash
cd app
swift run
```

## 设置
在面板的“设置”中配置：
- 接口：OpenAI / OpenAI Compatible / Anthropic / Gemini 四选一
- 接口地址（可替换）
- API Key（本地存储在用户偏好中）
- 模型名称

默认接口地址：
- OpenAI：`https://api.openai.com/v1/responses`
- OpenAI Compatible：使用供应商提供的完整地址（常见为 `/v1/chat/completions` 或 `/v1/completions`）
- Anthropic：`https://api.anthropic.com/v1/messages`
- Gemini：`https://generativelanguage.googleapis.com/v1beta/models`

默认模型建议：
- OpenAI：`gpt-4o-mini`
- OpenAI Compatible：使用供应商提供的模型名
- Anthropic：`claude-3-5-sonnet-latest`
- Gemini：`gemini-1.5-flash`

### OpenAI Compatible 的请求格式
如果第三方接口报缺少 `prompt` 或 `messages`，请在设置里切换：
- `Chat`：用于 `/v1/chat/completions`
- `Completion`：用于 `/v1/completions`

## 接口返回格式
模型会被要求仅输出 JSON，格式如下：
```json
{
  "candidates": [
    {"word": "替换词", "note": "简短用法说明"}
  ]
}
```
