import SwiftUI

/// Main multi-page cycling computer dashboard (Wahoo ELEMNT & Garmin Edge experience).
public struct CyclingComputerContainerView: View {
    @Environment(CyclingRideEngine.self) private var engine
    @State private var selectedTab: Int = 0
    @State private var showingStopConfirmation: Bool = false

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Page 0: High-Contrast Metrics Matrix
            MetricsGridView()
                .tag(0)

            // Page 1: 100% Offline Vector & Breadcrumb Map
            OfflineBreadcrumbMapView()
                .tag(1)

            // Page 2: ClimbPro & Live Elevation
            ClimbProView()
                .tag(2)

            // Page 3: Turn Cue Sheet
            CueSheetListView()
                .tag(3)

            // Page 4: Laps & Interval Splits
            LapMetricsView()
                .tag(4)
        }
        .tabViewStyle(.page)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    showingStopConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("End ride")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if engine.isPaused {
                        engine.resumeRide()
                    } else {
                        engine.pauseRide()
                    }
                } label: {
                    Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                        .foregroundStyle(engine.isPaused ? .green : .yellow)
                }
                .accessibilityLabel(engine.isPaused ? "Resume ride" : "Pause ride")
            }
        }
        .confirmationDialog(
            "Finish Ride?",
            isPresented: $showingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish & Save Ride", role: .destructive) {
                engine.finishRide()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your ride metrics and workout will be saved.")
        }
    }
}
