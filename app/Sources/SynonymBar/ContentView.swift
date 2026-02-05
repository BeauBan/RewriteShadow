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

enum InputMode: String, CaseIterable, Identifiable {
    case word = "词语"
    case sentence = "句子"

    var id: String { rawValue }
}

enum SentenceTone: String, CaseIterable, Identifiable {
    case casual = "口语"
    case formal = "书面"

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

struct InsetTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 10, height: 8)
        textView.textContainer?.lineFragmentPadding = 0
        textView.drawsBackground = false
        textView.backgroundColor = .clear

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: InsetTextEditor

        init(_ parent: InsetTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
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

    @AppStorage("temperature") private var temperature = 0.35
    @AppStorage("wordCount") private var wordCount = 6
    @AppStorage("sentenceCount") private var sentenceCount = 3

    @State private var inputMode: InputMode = .word
    @State private var tone: SentenceTone = .casual
    @State private var wordInput = ""
    @State private var sentenceInput = ""
    @State private var isLoading = false
    @State private var candidates: [Candidate] = []
    @State private var errorMessage: String?
    @State private var isTesting = false
    @State private var testMessage: String?
    @State private var settingsExpanded = false

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
                "minItems": 1,
                "maxItems": 12,
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

    private let jsonFormatExample = "{\"candidates\":[{\"word\":\"...\",\"note\":\"...\"}]}"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("模式", selection: $inputMode) {
                ForEach(InputMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: inputMode) { _ in
                candidates = []
                errorMessage = nil
            }

            if inputMode == .word {
                Text("中文词语")
                    .font(.headline)

                TextField("输入一个中文词语", text: $wordInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        fetchCandidates()
                    }

                countPicker(title: "数量", selection: $wordCount, options: [3, 5, 8, 10])
            } else {
                Text("中文句子")
                    .font(.headline)

                InsetTextEditor(text: $sentenceInput)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.35))
                    )

                Picker("改写风格", selection: $tone) {
                    ForEach(SentenceTone.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                countPicker(title: "数量", selection: $sentenceCount, options: [2, 3, 4, 5])
            }

            HStack(spacing: 8) {
                Button("查询") {
                    fetchCandidates()
                }
                .keyboardShortcut(.defaultAction)

                Button("清空") {
                    if inputMode == .word {
                        wordInput = ""
                    } else {
                        sentenceInput = ""
                    }
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
                            if !candidate.note.isEmpty {
                                Text(candidate.note)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button("复制") {
                            copyToPasteboard(candidate.word)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 240)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        settingsExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: settingsExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                        Text("设置")
                            .font(.headline)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if settingsExpanded {
                    settingsPanel
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
        .frame(width: 400)
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 6) {
                Text("变化灵活程度")
                    .font(.caption)
                HStack(spacing: 10) {
                    Slider(value: $temperature, in: 0...1, step: 0.05)
                    Text(String(format: "%.2f", temperature))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                Text("数值越高，改写越大胆。")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    }

    private func countPicker(title: String, selection: Binding<Int>, options: [Int]) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .labelsHidden()
            .frame(width: 90)
            Spacer()
        }
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

    private func fetchCandidates() {
        let text = inputMode == .word ? wordInput : sentenceInput
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = inputMode == .word ? "请输入一个中文词语" : "请输入一个中文句子"
            return
        }

        isLoading = true
        errorMessage = nil
        candidates = []

        Task {
            do {
                let payload = try await requestCandidates(text: trimmed, mode: inputMode, tone: tone)
                await MainActor.run {
                    isLoading = false
                    let maxCount = inputMode == .word ? wordCount : sentenceCount
                    let limited = Array(payload.candidates.prefix(maxCount))
                    if limited.isEmpty {
                        errorMessage = "模型未返回结果，请调整提示或灵活程度。"
                    } else {
                        candidates = limited
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func requestCandidates(text: String, mode: InputMode, tone: SentenceTone) async throws -> ResponsePayload {
        let (systemPrompt, userPrompt, maxTokens) = buildPrompts(text: text, mode: mode, tone: tone)
        let provider = providerBinding.wrappedValue
        switch provider {
        case .openAI:
            return try await requestOpenAI(systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: maxTokens)
        case .openAICompatible:
            return try await requestOpenAICompatible(systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: maxTokens)
        case .anthropic:
            return try await requestAnthropic(systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: maxTokens)
        case .gemini:
            return try await requestGemini(systemPrompt: systemPrompt, userPrompt: userPrompt, maxTokens: maxTokens)
        }
    }

    private func runSelfTest() {
        isTesting = true
        testMessage = nil

        Task {
            do {
                _ = try await requestCandidates(text: "测试", mode: .word, tone: tone)
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

    private func buildPrompts(text: String, mode: InputMode, tone: SentenceTone) -> (String, String, Int) {
        if mode == .word {
            let systemPrompt = """
你是中文写作助手。根据给定词语，提供可替换的词语。
输出必须是 JSON 对象，格式为：
\(jsonFormatExample)
输出数量必须严格等于 \(wordCount)。
每个候选词给出简短用法说明，词语之间差异明显，避免重复。
不得输出代码块或额外说明文字。
"""
            let userPrompt = "词语：\(text)\n请给出可替换词语，并简述语境差异。"
            let maxTokens = 120 + wordCount * 24
            return (systemPrompt, userPrompt, maxTokens)
        }

        let systemPrompt = """
你是中文改写助手。根据给定句子进行改写。
输出必须是 JSON 对象，格式为：
\(jsonFormatExample)
输出数量必须严格等于 \(sentenceCount)。
要求改写幅度明显，允许调整句式、拆分或合并短语，但保持原意。
不得输出代码块或额外说明文字。
口语：更简洁、更自然、更生活化。
书面：更正式、更严谨、更书面化。
"""
        let userPrompt = "原句：\(text)\n请改写为更\(tone.rawValue)的表达，只返回该风格，避免与原句措辞过于接近，并做适度优化。"
        let maxTokens = 180 + sentenceCount * 40
        return (systemPrompt, userPrompt, maxTokens)
    }

    private func requestOpenAI(systemPrompt: String, userPrompt: String, maxTokens: Int) async throws -> ResponsePayload {
        guard !openAIKey.isEmpty else {
            throw APIError.message("请在设置中填写 OpenAI API Key")
        }
        guard let url = URL(string: openAIURL) else {
            throw APIError.message("OpenAI 接口地址无效")
        }

        let payload: [String: Any] = [
            "model": openAIModel,
            "instructions": systemPrompt,
            "input": userPrompt,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "synonyms",
                    "schema": jsonSchema,
                    "strict": true
                ]
            ],
            "temperature": temperature,
            "max_output_tokens": maxTokens
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

    private func requestOpenAICompatible(systemPrompt: String, userPrompt: String, maxTokens: Int) async throws -> ResponsePayload {
        guard !openAICompatKey.isEmpty else {
            throw APIError.message("请在设置中填写 OpenAI Compatible API Key")
        }
        guard let url = URL(string: openAICompatURL) else {
            throw APIError.message("OpenAI Compatible 接口地址无效")
        }

        let mode = openAICompatModeBinding.wrappedValue
        let payload: [String: Any]
        if mode == .chat {
            payload = [
                "model": openAICompatModel,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": userPrompt]
                ],
                "temperature": temperature,
                "max_tokens": maxTokens,
                "stream": false
            ]
        } else {
            payload = [
                "model": openAICompatModel,
                "prompt": "\(systemPrompt)\n\n\(userPrompt)",
                "temperature": temperature,
                "max_tokens": maxTokens,
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

    private func requestAnthropic(systemPrompt: String, userPrompt: String, maxTokens: Int) async throws -> ResponsePayload {
        guard !anthropicKey.isEmpty else {
            throw APIError.message("请在设置中填写 Anthropic API Key")
        }
        guard let url = URL(string: anthropicURL) else {
            throw APIError.message("Anthropic 接口地址无效")
        }

        let payload: [String: Any] = [
            "model": anthropicModel,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "temperature": temperature
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

    private func requestGemini(systemPrompt: String, userPrompt: String, maxTokens: Int) async throws -> ResponsePayload {
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
                        ["text": userPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": maxTokens,
                "temperature": temperature
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
        if let jsonText = try? extractJSON(from: text),
           let data = jsonText.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(ResponsePayload.self, from: data) {
                return decoded
            }

            if let dict = try? jsonObject(data) {
                let rawCandidates = dict["candidates"] as? [Any] ?? []
                let mapped = mapCandidates(from: rawCandidates)
                if !mapped.isEmpty {
                    return ResponsePayload(candidates: mapped)
                }
            }
        }

        let fallback = fallbackCandidates(from: text)
        if !fallback.isEmpty {
            return ResponsePayload(candidates: fallback)
        }

        throw APIError.message("模型返回格式无法解析")
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

        if let start = trimmed.firstIndex(of: "["), let end = trimmed.lastIndex(of: "]") {
            let arrayText = String(trimmed[start...end])
            return "{\"candidates\":\(arrayText)}"
        }

        throw APIError.message("无法解析模型返回内容")
    }

    private func mapCandidates(from rawCandidates: [Any]) -> [Candidate] {
        var mapped: [Candidate] = []
        for item in rawCandidates {
            if let textItem = item as? String {
                mapped.append(Candidate(word: textItem, note: ""))
                continue
            }
            guard let obj = item as? [String: Any] else { continue }
            let word = (obj["word"] as? String)
                ?? (obj["text"] as? String)
                ?? (obj["sentence"] as? String)
                ?? ""
            let note = (obj["note"] as? String)
                ?? (obj["style"] as? String)
                ?? ""
            if !word.isEmpty {
                mapped.append(Candidate(word: word, note: note))
            }
        }
        return mapped
    }

    private func fallbackCandidates(from text: String) -> [Candidate] {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let lines = cleaned
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var results: [Candidate] = []
        for line in lines {
            var content = line
            content = content.replacingOccurrences(of: #"^\d+[\.\)、]\s*"#, with: "", options: .regularExpression)
            content = content.replacingOccurrences(of: #"^[\-•]\s*"#, with: "", options: .regularExpression)

            if content.isEmpty { continue }

            if let splitIndex = content.firstIndex(of: "：") ?? content.firstIndex(of: ":") {
                let word = String(content[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                let note = String(content[content.index(after: splitIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !word.isEmpty {
                    results.append(Candidate(word: word, note: note))
                }
            } else if let dashRange = content.range(of: " - ") ?? content.range(of: " — ") ?? content.range(of: " – ") {
                let word = String(content[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let note = String(content[dashRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !word.isEmpty {
                    results.append(Candidate(word: word, note: note))
                }
            } else {
                results.append(Candidate(word: content, note: ""))
            }
        }

        return results
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
