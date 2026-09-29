import SwiftUI

/// Screen to select an offline course from the route library or start a Free Ride.
public struct RoutePickerView: View {
    @Environment(RouteLibraryViewModel.self) private var libraryViewModel
    @Environment(RideViewModel.self) private var rideViewModel
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        let state = libraryViewModel.state

        NavigationStack {
            List {
                Section(header: Text("FREE RIDE")) {
                    Button {
                        rideViewModel.handle(.primaryControlSelected)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.outdoor.cycle")
                                .font(.title3)
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Ride (No Course)")
                                    .font(.headline)
                                Text("Record metrics, breadcrumbs & elevation")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.black.opacity(0.7))
                }

                Section(header: Text("OFFLINE COURSES")) {
                    if state.routes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No offline courses imported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Import GPX files via iPhone app")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.black.opacity(0.7))
                    } else {
                        ForEach(state.routes) { route in
                            Button {
                                libraryViewModel.handle(.routeSelected(route.id))
                                rideViewModel.handle(.primaryControlSelected)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(route.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    HStack(spacing: 12) {
                                        Label("\(route.distance.primaryText) \(route.distance.unitText)", systemImage: "arrow.triangle.swap")
                                        if let elev = route.elevationAvailabilityText {
                                            Label(elev, systemImage: "mountain.2.fill")
                                        }
                                    }
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.cyan)
                                }
                                .padding(.vertical, 2)
                            }
                            .listRowBackground(Color.black.opacity(0.7))
                        }
                    }
                }
            }
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                libraryViewModel.handle(.appeared)
            }
        }
    }
}
