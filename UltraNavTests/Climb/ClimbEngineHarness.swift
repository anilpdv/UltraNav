import Foundation
@testable import UltraNav

@MainActor
final class ClimbEngineHarness {
    let profileBuilder: FakeElevationProfileBuilder
    let detector: FakeClimbDetector
    let classifier: FakeClimbClassifier
    let progressCalculator: FakeClimbProgressCalculator
    let selector: StandardActiveClimbSelector
    let engine: ClimbEngine
    let snapshotRecorder: ClimbSnapshotRecorder
    let notificationRecorder: ClimbNotificationRecorder

    init() {
        let fakeProfileBuilder = FakeElevationProfileBuilder()
        let fakeDetector = FakeClimbDetector()
        let fakeClassifier = FakeClimbClassifier()
        let fakeProgress = FakeClimbProgressCalculator()
        let standardSelector = StandardActiveClimbSelector()

        let analysisService = ClimbAnalysisService(
            profileBuilder: fakeProfileBuilder,
            detector: fakeDetector,
            assembler: ClimbAssembler(classifier: fakeClassifier)
        )

        let engine = ClimbEngine(
            analysisService: analysisService,
            selector: standardSelector,
            progressCalculator: fakeProgress,
            snapshotBuilder: ClimbSnapshotBuilder()
        )

        self.profileBuilder = fakeProfileBuilder
        self.detector = fakeDetector
        self.classifier = fakeClassifier
        self.progressCalculator = fakeProgress
        self.selector = standardSelector
        self.engine = engine
        self.snapshotRecorder = ClimbSnapshotRecorder()
        self.notificationRecorder = ClimbNotificationRecorder()

        self.snapshotRecorder.startRecording(stream: engine.snapshots)
        self.notificationRecorder.startRecording(stream: engine.notifications)
    }

    func tearDown() {
        snapshotRecorder.stopRecording()
        notificationRecorder.stopRecording()
    }
}
