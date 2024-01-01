import AppIntents
import Foundation

struct OpenNavigationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Navigation"
    static let description = IntentDescription(
        "Opens UltraNav at the destination search screen."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "ultranav://search")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

struct ResumeRideIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume Ride"
    static let description = IntentDescription(
        "Opens UltraNav at the active ride guidance screen."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & OpensIntent {
        let url = URL(string: "ultranav://navigation")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}