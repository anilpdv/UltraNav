import CoreLocation
import MapKit
import UserNotifications
import XCTest
@testable import UltraNav

@MainActor
final class UltraNavCoreTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
    }

    func testNavigationModelResetReturnsToIdleAndClearsSearch() {
        let model = NavigationModel()
        model.query = "Coffee"
        model.searchResults = [
            MKMapItem(
                placemark: MKPlacemark(
                    coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
                )
            )
        ]
        model.searchState = .empty
        model.state = .emptySearch(query: "Coffee")

        model.resetSearch()

        XCTAssertEqual(model.state, .idle)
        if case .idle = model.searchState {
            // Expected state.
        } else {
            XCTFail("Expected search state to return to idle")
        }
        XCTAssertTrue(model.searchResults.isEmpty)
    }

    func testNavigationModelRetryWithoutFailedOperationReturnsToIdle() {
        let model = NavigationModel()
        model.state = .error("Temporary failure")

        model.retry()

        XCTAssertEqual(model.state, .idle)
    }

    func testCacheExpirationUsesExactMaximumAgeBoundary() {
        let savedAt = Date(timeIntervalSince1970: 1_000)
        let results = CachedSearchResults(
            query: "Station",
            destinations: [],
            savedAt: savedAt
        )

        XCTAssertFalse(
            results.isStale(
                at: savedAt.addingTimeInterval(300),
                maximumAge: 300
            )
        )
        XCTAssertTrue(
            results.isStale(
                at: savedAt.addingTimeInterval(300.001),
                maximumAge: 300
            )
        )
    }

    func testCacheRoundTripAndClear() async throws {
        let cache = makeCache()
        let destination = CachedDestination(
            name: "Central Station",
            locality: "City Centre",
            latitude: 51.5,
            longitude: -0.1
        )
        let expected = CachedSearchResults(
            query: "Station",
            destinations: [destination],
            savedAt: Date(timeIntervalSince1970: 1_000)
        )

        try await cache.saveSearchResults(expected)
        let restored = try await cache.loadSearchResults()
        XCTAssertEqual(restored, expected)

        try await cache.clear()
        let cleared = try await cache.loadSearchResults()
        XCTAssertNil(cleared)
    }

    func testNewestPendingMutationWinsForSameDestination() async throws {
        let cache = makeCache()
        let destination = CachedDestination(
            id: UUID(),
            name: "Office",
            locality: nil,
            latitude: 12.3,
            longitude: 45.6
        )
        let save = PendingMutation(
            kind: .saveDestination,
            destination: destination,
            createdAt: Date(timeIntervalSince1970: 1)
        )
        let remove = PendingMutation(
            kind: .removeDestination,
            destination: destination,
            createdAt: Date(timeIntervalSince1970: 2)
        )

        try await cache.enqueueMutation(save)
        try await cache.enqueueMutation(remove)
        let pending = try await cache.loadPendingMutations()

        XCTAssertEqual(pending, [remove])
    }

    func testSyncCoordinatorCollapsesConflictingQueuedMutations() {
        let coordinator = SyncCoordinator(
            cache: makeCache(),
            startMonitoring: false,
            restorePending: false
        )
        let destination = CachedDestination(
            id: UUID(),
            name: "Trailhead",
            locality: nil,
            latitude: 10,
            longitude: 20
        )

        coordinator.enqueue(
            PendingMutation(kind: .saveDestination, destination: destination)
        )
        coordinator.enqueue(
            PendingMutation(kind: .removeDestination, destination: destination)
        )

        XCTAssertEqual(coordinator.pendingMutations.count, 1)
        XCTAssertEqual(coordinator.pendingMutations.first?.kind, .removeDestination)
    }

    func testNotificationReminderRequestIsDeterministicAndActionable() {
        let now = Date(timeIntervalSince1970: 1_000)
        let request = NotificationManager.reminderDescriptor(
            identifier: "route-1",
            title: "Continue route",
            body: "Your route is ready.",
            at: now.addingTimeInterval(120),
            now: now
        )

        XCTAssertEqual(request.identifier, "navigation-reminder.route-1")
        XCTAssertEqual(
            request.content.categoryIdentifier,
            NotificationManager.Category.navigationReminder
        )
        XCTAssertEqual(
            request.content.userInfo["deepLink"] as? String,
            "ultranav://navigation"
        )

        guard let trigger = request.trigger as? UNTimeIntervalNotificationTrigger else {
            return XCTFail("Expected a time interval notification trigger")
        }
        XCTAssertEqual(trigger.timeInterval, 120, accuracy: 0.001)
    }

    private func makeCache() -> AppCache {
        AppCache(
            cacheURL: temporaryDirectory.appendingPathComponent("cache.json"),
            pendingMutationsURL: temporaryDirectory.appendingPathComponent("mutations.json")
        )
    }
}