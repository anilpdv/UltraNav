import Foundation
@testable import UltraNav

/// Fake settings provider for controlling AppConfiguration and user preferences in tests.
final class FakeSettingsProvider: @unchecked Sendable {
    private let lock = NSLock()
    var configuration: AppConfiguration

    init(configuration: AppConfiguration = .test) {
        self.configuration = configuration
    }

    func updateConfiguration(_ config: AppConfiguration) {
        lock.withLock {
            self.configuration = config
        }
    }

    func currentConfiguration() -> AppConfiguration {
        lock.withLock {
            self.configuration
        }
    }
}
