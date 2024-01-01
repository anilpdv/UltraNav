import SwiftUI

/// Screen to select an offline course from the route library or start a Free Ride.
public struct RoutePickerView: View {
    @Environment(CyclingRideEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    @State private var library = RouteLibraryManager.shared

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("FREE RIDE")) {
                    Button {
                        engine.startRide(route: nil)
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
                    ForEach(library.savedRoutes) { route in
                        Button {
                            engine.startRide(route: route)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(route.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                if !route.summary.isEmpty {
                                    Text(route.summary)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 12) {
                                    Label(String(format: "%.1f km", route.totalDistance / 1000.0), systemImage: "arrow.triangle.swap")
                                    Label("+\(Int(route.totalAscent))m", systemImage: "mountain.2.fill")
                                    if !route.climbs.isEmpty {
                                        Label("\(route.climbs.count) climbs", systemImage: "flag.fill")
                                            .foregroundStyle(.orange)
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
            .navigationTitle("Select Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
