import SwiftUI

/// Main multi-page cycling computer dashboard (Wahoo ELEMNT & Garmin Edge experience).
public struct CyclingComputerContainerView: View {
    @Environment(RideViewModel.self) private var rideViewModel
    @State private var selectedTab: Int = 0
    @State private var showingStopConfirmation: Bool = false

    public init() {}

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
                .disabled(rideViewModel.state.controls.secondaryAction == nil || !rideViewModel.state.controls.secondaryEnabled)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    rideViewModel.handle(.primaryControlSelected)
                } label: {
                    let isPaused = rideViewModel.state.phase == .paused
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .foregroundStyle(isPaused ? .green : .yellow)
                }
                .accessibilityLabel(rideViewModel.state.phase == .paused ? "Resume ride" : "Pause ride")
                .disabled(rideViewModel.state.controls.primaryAction == nil || !rideViewModel.state.controls.primaryEnabled)
            }
        }
        .confirmationDialog(
            "Finish Ride?",
            isPresented: $showingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish & Save Ride", role: .destructive) {
                rideViewModel.handle(.finishConfirmed)
            }
            Button("Cancel", role: .cancel) {
                rideViewModel.handle(.finishCancelled)
            }
        } message: {
            Text("Your ride metrics and workout will be saved.")
        }
    }
}
