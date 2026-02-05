import AppKit
import SwiftUI

struct Candidate: Identifiable, Decodable {
    let word: String
    let note: String
    let id = UUID()

    private enum CodingKeys: String, CodingKey {
        case word
        case note
    }
}

struct ResponsePayload: Decodable {
    let candidates: [Candidate]
}

enum Provider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case openAICompatible = "OpenAI Compatible"
    case anthropic = "Anthropic"
    case gemini = "Gemini"

    var id: String { rawValue }
}

enum OpenAICompatMode: String, CaseIterable, Identifiable {
    case chat = "Chat"
    case completion = "Completion"

    var id: String { rawValue }
}

enum APIError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let msg):
            return msg
        }
    }
}

struct ContentView: View {
    @AppStorage("provider") private var providerRaw = Provider.openAI.rawValue
    @AppStorage("openAIURL") private var openAIURL = "https://api.openai.com/v1/responses"
    @AppStorage("openAIKey") private var openAIKey = ""
    @AppStorage("openAIModel") private var openAIModel = "gpt-4o-mini"

    @AppStorage("openAICompatURL") private var openAICompatURL = ""
    @AppStorage("openAICompatKey") private var openAICompatKey = ""
    @AppStorage("openAICompatModel") private var openAICompatModel = "gpt-4o-mini"
    @AppStorage("openAICompatMode") private var openAICompatModeRaw = OpenAICompatMode.chat.rawValue

    @AppStorage("anthropicURL") private var anthropicURL = "https://api.anthropic.com/v1/messages"
    @AppStorage("anthropicKey") private var anthropicKey = ""
    @AppStorage("anthropicModel") private var anthropicModel = "claude-3-5-sonnet-latest"

    @AppStorage("geminiURL") private var geminiURL = "https://generativelanguage.googleapis.com/v1beta/models"
    @AppStorage("geminiKey") private var geminiKey = ""
    @AppStorage("geminiModel") private var geminiModel = "gemini-1.5-flash"

    @State private var input = ""
    @State private var isLoading = false
    @State private var candidates: [Candidate] = []
    @State private var errorMessage: String?
    @State private var isTesting = false
    @State private var testMessage: String?

    private var providerBinding: Binding<Provider> {
        Binding(
            get: { Provider(rawValue: providerRaw) ?? .openAI },
            set: { providerRaw = $0.rawValue }
        )
    }

    private var openAICompatModeBinding: Binding<OpenAICompatMode> {
        Binding(
            get: { OpenAICompatMode(rawValue: openAICompatModeRaw) ?? .chat },
            set: { openAICompatModeRaw = $0.rawValue }
        )
    }

    private let jsonSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "candidates": [
                "type": "array",
                "minItems": 3,
                "maxItems": 8,
                "items": [
                    "type": "object",
                    "properties": [
                        "word": ["type": "string"],
                        "note": ["type": "string"]
                    ],
                    "required": ["word", "note"],
                    "additionalProperties": false
                ]
            ]
        ],
        "required": ["candidates"],
        "additionalProperties": false
    ]

    private let systemPrompt = """
你是中文写作助手。根据给定词语，提供可替换的词语。
输出必须是 JSON 对象，格式为：
{"candidates":[{"word":"替换词","note":"简短用法说明"}]}
每个候选词给出简短用法说明，方便写作时选择。
"""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("中文词语")
                .font(.headline)

            TextField("输入一个中文词语", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    fetchSynonyms()
                }

            HStack(spacing: 8) {
                Button("查询") {
                    fetchSynonyms()
                }
                .keyboardShortcut(.defaultAction)

                Button("清空") {
                    input = ""
                    candidates = []
                    errorMessage = nil
                }
            }

            if isLoading {
                ProgressView("查询中…")
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !candidates.isEmpty {
                List(candidates) { candidate in
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.word)
                                .font(.headline)
                            Text(candidate.note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("复制") {
                            copyToPasteboard(candidate.word)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
            }

            Divider()

            DisclosureGroup("设置") {
                Picker("接口", selection: providerBinding) {
                    ForEach(Provider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                switch providerBinding.wrappedValue {
                case .openAI:
                    settingsGroup(
                        url: $openAIURL,
                        key: $openAIKey,
                        model: $openAIModel,
                        hint: "默认: https://api.openai.com/v1/responses"
                    )
                case .openAICompatible:
                    settingsGroup(
                        url: $openAICompatURL,
                        key: $openAICompatKey,
                        model: $openAICompatModel,
                        hint: "示例: https://your-host/v1/chat/completions 或 /v1/completions"
                    )
                    Picker("请求格式", selection: openAICompatModeBinding) {
                        ForEach(OpenAICompatMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("若报缺少 prompt，请选择 Completion 并使用 /v1/completions。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .anthropic:
                    settingsGroup(
                        url: $anthropicURL,
                        key: $anthropicKey,
                        model: $anthropicModel,
                        hint: "默认: https://api.anthropic.com/v1/messages"
                    )
                case .gemini:
                    settingsGroup(
                        url: $geminiURL,
                        key: $geminiKey,
                        model: $geminiModel,
                        hint: "默认: https://generativelanguage.googleapis.com/v1beta/models"
                    )
                }

                HStack(spacing: 8) {
                    Button("一键自测") {
                        runSelfTest()
                    }
                    .disabled(isTesting)

                    if isTesting {
                        ProgressView()
                    }
                }

                if let testMessage {
                    Text(testMessage)
                        .font(.caption)
                        .foregroundColor(testMessage.contains("成功") ? .green : .red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 360)
    }

    @ViewBuilder
    private func settingsGroup(url: Binding<String>, key: Binding<String>, model: Binding<String>, hint: String) -> some View {
        TextField("接口地址", text: url)
            .textFieldStyle(.roundedBorder)
        SecureField("API Key", text: key)
            .textFieldStyle(.roundedBorder)
        TextField("模型", text: model)
            .textFieldStyle(.roundedBorder)
        Text(hint)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func fetchSynonyms() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "请输入一个中文词语"
            return
        }

        isLoading = true
        errorMessage = nil
        candidates = []

        Task {
            do {
                let payload = try await requestSynonyms(text: trimmed)
                await MainActor.run {
                    candidates = payload.candidates
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func requestSynonyms(text: String) async throws -> ResponsePayload {
        let provider = providerBinding.wrappedValue
        switch provider {
        case .openAI:
            return try await requestOpenAI(text: text)
        case .openAICompatible:
            return try await requestOpenAICompatible(text: text)
        case .anthropic:
            return try await requestAnthropic(text: text)
        case .gemini:
            return try await requestGemini(text: text)
        }
    }

    private func runSelfTest() {
        isTesting = true
        testMessage = nil

        Task {
            do {
                _ = try await requestSynonyms(text: "测试")
                await MainActor.run {
                    testMessage = "连接成功，可以开始使用。"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testMessage = error.localizedDescription
                    isTesting = false
                }
            }
        }
    }

    private func requestOpenAI(text: String) async throws -> ResponsePayload {
        guard !openAIKey.isEmpty else {
            throw APIError.message("请在设置中填写 OpenAI API Key")
        }
        guard let url = URL(string: openAIURL) else {
            throw APIError.message("OpenAI 接口地址无效")
        }

        let payload: [String: Any] = [
            "model": openAIModel,
            "instructions": systemPrompt,
            "input": "词语：\(text)\n请给出可替换词语，并简述语境差异。",
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "synonyms",
                    "schema": jsonSchema,
                    "strict": true
                ]
            ],
            "max_output_tokens": 300
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try jsonData(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 200
        return try parseOpenAIResponse(data: data, status: status)
    }

    private func requestOpenAICompatible(text: String) async throws -> ResponsePayload {
        guard !openAICompatKey.isEmpty else {
            throw APIError.message("请在设置中填写 OpenAI Compatible API Key")
        }
        guard let url = URL(string: openAICompatURL) else {
            throw APIError.message("OpenAI Compatible 接口地址无效")
        }

        let userPrompt = "词语：\(text)\n请给出可替换词语，并简述语境差异。"
        let mode = openAICompatModeBinding.wrappedValue
        let payload: [String: Any]
        if mode == .chat {
            payload = [
                "model": openAICompatModel,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userPrompt]
                ],
                "temperature": 0.2,
                "max_tokens": 300,
                "stream": false
            ]
        } else {
            payload = [
                "model": openAICompatModel,
                "prompt": "\(systemPrompt)\n\n\(userPrompt)",
                "temperature": 0.2,
                "max_tokens": 300,
                "stream": false
            ]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAICompatKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try jsonData(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 200
        return try parseOpenAICompatibleResponse(data: data, status: status)
    }

    private func requestAnthropic(text: String) async throws -> ResponsePayload {
        guard !anthropicKey.isEmpty else {
            throw APIError.message("请在设置中填写 Anthropic API Key")
        }
        guard let url = URL(string: anthropicURL) else {
            throw APIError.message("Anthropic 接口地址无效")
        }

        let payload: [String: Any] = [
            "model": anthropicModel,
            "max_tokens": 300,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": "词语：\(text)\n请给出可替换词语，并简述语境差异。"
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try jsonData(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 200
        return try parseAnthropicResponse(data: data, status: status)
    }

    private func requestGemini(text: String) async throws -> ResponsePayload {
        guard !geminiKey.isEmpty else {
            throw APIError.message("请在设置中填写 Gemini API Key")
        }

        let base = geminiURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else {
            throw APIError.message("Gemini 接口地址无效")
        }

        let urlString = "\(base)/\(geminiModel):generateContent?key=\(geminiKey)"
        guard let url = URL(string: urlString) else {
            throw APIError.message("Gemini 接口地址无效")
        }

        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [
                    ["text": systemPrompt]
                ]
            ],
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": "词语：\(text)\n请给出可替换词语，并简述语境差异。"]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 300
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonData(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 200
        return try parseGeminiResponse(data: data, status: status)
    }

    private func parseOpenAIResponse(data: Data, status: Int) throws -> ResponsePayload {
        guard let dict = try jsonObject(data) else {
            throw APIError.message("OpenAI 返回格式不正确")
        }

        if let errorDict = dict["error"] as? [String: Any], let message = errorDict["message"] as? String {
            throw APIError.message(message)
        }

        if status >= 400 {
            throw APIError.message("OpenAI 请求失败：HTTP \(status)")
        }

        let output = dict["output"] as? [[String: Any]] ?? []
        var text = ""
        for item in output {
            if (item["type"] as? String) != "message" { continue }
            let contents = item["content"] as? [[String: Any]] ?? []
            for content in contents {
                if (content["type"] as? String) == "output_text", let snippet = content["text"] as? String {
                    text += snippet
                }
            }
        }

        if text.isEmpty {
            throw APIError.message("OpenAI 返回内容为空")
        }

        return try decodeCandidates(from: text)
    }

    private func parseAnthropicResponse(data: Data, status: Int) throws -> ResponsePayload {
        guard let dict = try jsonObject(data) else {
            throw APIError.message("Anthropic 返回格式不正确")
        }

        if let errorDict = dict["error"] as? [String: Any], let message = errorDict["message"] as? String {
            throw APIError.message(message)
        }

        if status >= 400 {
            throw APIError.message("Anthropic 请求失败：HTTP \(status)")
        }

        let content = dict["content"] as? [[String: Any]] ?? []
        let text = content.first(where: { ($0["type"] as? String) == "text" })?["text"] as? String ?? ""

        if text.isEmpty {
            throw APIError.message("Anthropic 返回内容为空")
        }

        return try decodeCandidates(from: text)
    }

    private func parseOpenAICompatibleResponse(data: Data, status: Int) throws -> ResponsePayload {
        guard let dict = try jsonObject(data) else {
            throw APIError.message("OpenAI Compatible 返回格式不正确")
        }

        if let errorDict = dict["error"] as? [String: Any], let message = errorDict["message"] as? String {
            throw APIError.message(message)
        }

        if let errorMessage = dict["message"] as? String, status >= 400 {
            throw APIError.message(errorMessage)
        }

        if status >= 400 {
            throw APIError.message("OpenAI Compatible 请求失败：HTTP \(status)")
        }

        let root = (dict["data"] as? [String: Any]) ?? dict
        let choices = root["choices"] as? [[String: Any]] ?? []
        let firstChoice = choices.first ?? [:]
        let message = firstChoice["message"] as? [String: Any]
        let delta = firstChoice["delta"] as? [String: Any]
        let messageText = extractText(from: message)
        let deltaText = extractText(from: delta)
        let completionText = firstChoice["text"] as? String ?? ""
        let text = !messageText.isEmpty ? messageText : (!deltaText.isEmpty ? deltaText : completionText)

        if text.isEmpty {
            let raw = String(data: data, encoding: .utf8) ?? ""
            let preview = raw.prefix(600)
            throw APIError.message("OpenAI Compatible 返回内容为空。原始响应: \(preview)")
        }

        return try decodeCandidates(from: text)
    }

    private func extractText(from container: [String: Any]?) -> String {
        guard let container else { return "" }
        if let text = container["content"] as? String {
            return text
        }
        if let contentParts = container["content"] as? [[String: Any]] {
            let texts = contentParts.compactMap { part -> String? in
                if let text = part["text"] as? String { return text }
                return nil
            }
            return texts.joined()
        }
        if let text = container["text"] as? String {
            return text
        }
        return ""
    }

    private func parseGeminiResponse(data: Data, status: Int) throws -> ResponsePayload {
        guard let dict = try jsonObject(data) else {
            throw APIError.message("Gemini 返回格式不正确")
        }

        if let errorDict = dict["error"] as? [String: Any], let message = errorDict["message"] as? String {
            throw APIError.message(message)
        }

        if status >= 400 {
            throw APIError.message("Gemini 请求失败：HTTP \(status)")
        }

        let candidates = dict["candidates"] as? [[String: Any]] ?? []
        let first = candidates.first
        let content = first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]] ?? []
        let text = parts.first?["text"] as? String ?? ""

        if text.isEmpty {
            throw APIError.message("Gemini 返回内容为空")
        }

        return try decodeCandidates(from: text)
    }

    private func decodeCandidates(from text: String) throws -> ResponsePayload {
        let jsonText = try extractJSON(from: text)
        guard let data = jsonText.data(using: .utf8) else {
            throw APIError.message("无法解析模型返回内容")
        }
        return try JSONDecoder().decode(ResponsePayload.self, from: data)
    }

    private func extractJSON(from text: String) throws -> String {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            if let firstNewline = trimmed.firstIndex(of: "\n") {
                trimmed = String(trimmed[trimmed.index(after: firstNewline)...])
            }
            if let lastFence = trimmed.range(of: "```", options: .backwards) {
                trimmed = String(trimmed[..<lastFence.lowerBound])
            }
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") {
            return String(trimmed[start...end])
        }

        throw APIError.message("无法解析模型返回内容")
    }

    private func jsonObject(_ data: Data) throws -> [String: Any]? {
        let obj = try JSONSerialization.jsonObject(with: data)
        return obj as? [String: Any]
    }

    private func jsonData(_ payload: [String: Any]) throws -> Data {
        guard JSONSerialization.isValidJSONObject(payload) else {
            throw APIError.message("无法构造请求")
        }
        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
