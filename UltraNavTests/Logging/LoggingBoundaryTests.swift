import Testing
import Foundation
@testable import UltraNav

@Suite("LoggingBoundary Tests")
struct LoggingBoundaryTests {
    @Test("NoOpLogger safely accepts all levels without effect")
    func testNoOpLoggerAcceptsCalls() async {
        let noop = NoOpLogger()
        await noop.trace(category: .app, "trace msg")
        await noop.debug(category: .app, "debug msg")
        await noop.information(category: .app, "info msg")
        await noop.notice(category: .app, "notice msg")
        await noop.warning(category: .app, "warning msg")
        await noop.error(category: .app, "error msg")
        await noop.critical(category: .app, "critical msg")
        // Succeeds with zero crash or throw
    }
}
