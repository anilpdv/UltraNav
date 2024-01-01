import AppIntents

struct OpenNavigationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open UltraNav"
    static let description = IntentDescription(
        "Opens UltraNav at destination search or the active ride."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "ultranav://navigate")!))
    }
}