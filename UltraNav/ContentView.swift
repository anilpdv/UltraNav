import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(NavigationModel.self) private var model
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(RideViewModel.self) private var rideViewModel

    var body: some View {
        NavigationStack {
            Group {
                if rideViewModel.state.phase == .active || rideViewModel.state.phase == .paused || rideViewModel.state.phase == .preparing || rideViewModel.state.phase == .ready {
                    CyclingComputerContainerView()
                } else {
                    switch model.state {
                    case .calculatingRoute(let destinationName):
                        LoadingView(
                            "Calculating route",
                            message: "Finding a \(model.transportType.name) route to \(destinationName)."
                        )
                    case .preview:
                        RoutePreviewView()
                    case .navigating, .rerouting:
                        NavigationView()
                    case .error(let message):
                        ErrorStateView(message: message) {
                            model.retry()
                        }
                    case .idle, .searching, .emptySearch:
                        SearchView()
                    }
                }
            }
            .task {
                model.requestLocationAccess()
            }
        }
        .accessibilityIdentifier("navigationScreen")
    }
}

private struct SearchView: View {
    @Environment(NavigationModel.self) private var model
    @State private var showingSettings = false
    @State private var showingRoutePicker = false

    var body: some View {
        @Bindable var model = model

        ZStack(alignment: .top) {
            RouteMap()

            VStack(spacing: 6) {
                // Offline Cycling Computer Quick Start
                Button {
                    showingRoutePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.black)
                        Text("Start Cycling Computer")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.15, green: 1.0, blue: 0.3), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingRoutePicker) {
                    RoutePickerView()
                }

                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Where to?", text: $model.query)
                        .accessibilityLabel("Destination")
                        .accessibilityHint("Enter a place to search for a route")
                        .accessibilityIdentifier("destinationSearchField")
                        .minimumWatchTapTarget()
                        .onSubmit {
                            model.submitSearch()
                        }
                }
                .padding(.horizontal, 11)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.2)))

                if model.state == .searching {
                    LoadingView("Searching", message: "Looking for places nearby.")
                        .padding(10)
                        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                } else if case .emptySearch(let query) = model.state {
                    EmptyStateView(
                        title: "Nothing found",
                        message: "No matches for “\(query)”.",
                        systemImage: "magnifyingglass"
                    ) {
                        RetryButton("Try again") { model.submitSearch() }
                    }
                    .padding(10)
                    .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
                } else if !model.searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(model.searchResults, id: \.self) { item in
                            Button {
                                model.select(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name ?? "Destination")
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text(item.placemark.locality ?? "Nearby")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .minimumWatchTapTarget()
                            Divider().opacity(0.25)
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 7)
            .padding(.top, 4)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gear") {
                    showingSettings = true
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier("settingsButton")
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            .environment(model)
        }
    }

}

private struct RoutePreviewView: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        VStack(spacing: 5) {
            RouteMap()
                .frame(maxHeight: .infinity)

            if let route = model.route {
                HStack {
                    Label(
                        route.expectedTravelTime.formattedDuration,
                        systemImage: "clock"
                    )
                    Spacer()
                    Text(route.distance.formattedDistance)
                }
                .font(.caption)
            }

            Button("Start", systemImage: model.transportType.symbol) {
                model.startNavigation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(model.route == nil)
            .accessibilityHint("Starts turn-by-turn \(model.transportType.name) navigation")
            .accessibilityIdentifier("startNavigationButton")
            .minimumWatchTapTarget()
        }
        .navigationTitle(model.selectedDestination?.name ?? "Route")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NavigationView: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        ZStack {
            RouteMap()

            VStack(spacing: 0) {
                WazeHeader()
                    .padding(.horizontal, 6)
                    .padding(.top, 2)

                Spacer()

                if model.state == .rerouting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Updating route")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.72), in: Capsule())
                    .foregroundStyle(.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Updating route")
                }

                GuidanceCard()
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    model.stopNavigation()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("End navigation")
                .accessibilityIdentifier("stopNavigationButton")
                .minimumWatchTapTarget()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.recenterOnUser()
                } label: {
                    Image(systemName: "location.fill")
                }
                .accessibilityLabel("Recenter on route")
                .minimumWatchTapTarget()
            }
        }
    }
}

private struct WazeHeader: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "location.north.fill")
                .font(.caption2.bold())
                .foregroundStyle(.cyan)

            Text(model.selectedDestination?.name ?? "Active ride")
                .font(.caption2.bold())
                .lineLimit(1)

            Text("•")
                .foregroundStyle(.white.opacity(0.45))

            Text(model.state == .rerouting ? "UPDATING" : "ON ROUTE")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(model.state == .rerouting ? .orange : .cyan)

            Spacer(minLength: 3)

            if let route = model.route {
                Text(remainingDistance(route))
                    .font(.caption.bold())
                Text(remainingTime(route))
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.black.opacity(0.68), in: Capsule())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(hudLabel)
    }

    private var hudLabel: String {
        guard let route = model.route else { return "Active ride" }
        return "\(model.selectedDestination?.name ?? "Active ride"), \(remainingDistance(route)) remaining, \(remainingTime(route))"
    }

    private func remainingDistance(_ route: MKRoute) -> String {
        max(0, route.distance - model.travelledDistance).formattedDistance
    }

    private func remainingTime(_ route: MKRoute) -> String {
        let ratio = max(0, 1 - model.travelledDistance / max(route.distance, 1))
        return (route.expectedTravelTime * ratio).formattedDuration
    }
}

private struct GuidanceCard: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: instructionSymbol)
                .font(.headline.bold())
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                if let distance = model.distanceToNextStep {
                    Text(distance.formattedDistance)
                        .font(.subheadline.bold())
                }

                Text(model.nextStep?.instructions ?? "Continue on route")
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: 250)
        .background(.black.opacity(0.72), in: Capsule())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(guidanceLabel)
    }

    private var guidanceLabel: String {
        if let distance = model.distanceToNextStep {
            return "\(distance.formattedDistance), \(model.nextStep?.instructions ?? "Continue on route")"
        }
        return model.nextStep?.instructions ?? "Continue on route"
    }

    private var instructionSymbol: String {
        let text = model.nextStep?.instructions.lowercased() ?? ""
        if text.contains("u-turn") { return "arrow.uturn.left" }
        if text.contains("left") { return "arrow.turn.up.left" }
        if text.contains("right") { return "arrow.turn.up.right" }
        if text.contains("arrive") || text.contains("destination") { return "flag.checkered" }
        return "arrow.up"
    }
}

private struct GuidanceView: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: instructionSymbol)
                .font(.largeTitle.bold())
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            if let distance = model.distanceToNextStep {
                Text(distance.formattedDistance)
                    .font(.title2.bold())
                    .minimumScaleFactor(0.7)
            }

            Text(model.nextStep?.instructions ?? "Continue on route")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.65)

            if let route = model.route {
                HStack {
                    Text(remainingTime(route))
                    Spacer()
                    Text(route.distance.formattedDistance)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var instructionSymbol: String {
        let text = model.nextStep?.instructions.lowercased() ?? ""
        if text.contains("u-turn") { return "arrow.uturn.left" }
        if text.contains("left") { return "arrow.turn.up.left" }
        if text.contains("right") { return "arrow.turn.up.right" }
        if text.contains("arrive") || text.contains("destination") {
            return "flag.checkered"
        }
        return "arrow.up"
    }

    private func remainingTime(_ route: MKRoute) -> String {
        let ratio = max(0, 1 - model.travelledDistance / max(route.distance, 1))
        return (route.expectedTravelTime * ratio).formattedDuration
    }
}

private struct RouteMap: View {
    @Environment(NavigationModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Map(position: $model.cameraPosition) {
            UserAnnotation()

            if let route = model.route {
                MapPolyline(route.polyline)
                    .stroke(
                        .black.opacity(0.82),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round)
                    )
                MapPolyline(route.polyline)
                    .stroke(
                        Color(red: 0.05, green: 0.86, blue: 1),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
                    )
            }

            if let destination = model.selectedDestination {
                Marker(
                    destination.name ?? "Destination",
                    coordinate: destination.placemark.coordinate
                )
                .tint(.red)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .preferredColorScheme(.dark)
        .overlay {
            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }
}

private extension CLLocationDistance {
    var formattedDistance: String {
        if self < 1_000 {
            return Measurement(value: self, unit: UnitLength.meters)
                .formatted(
                    .measurement(
                        width: .abbreviated,
                        numberFormatStyle: .number.precision(.fractionLength(0))
                    )
                )
        }

        return Measurement(value: self / 1_000, unit: UnitLength.kilometers)
            .formatted(
                .measurement(
                    width: .abbreviated,
                    numberFormatStyle: .number.precision(.fractionLength(1))
                )
            )
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        Duration.seconds(self).formatted(
            .units(allowed: [.hours, .minutes], width: .abbreviated)
        )
    }
}