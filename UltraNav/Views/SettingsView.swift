import SwiftUI
import MapKit
import CoreBluetooth

public struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("isAutoPauseEnabled") private var isAutoPauseEnabled: Bool = true
    @AppStorage("autoLapDistanceMeters") private var autoLapDistanceMeters: Double = 5000.0
    @AppStorage("maxHeartRate") private var maxHeartRate: Int = 185
    @AppStorage("transportTypeRawValue") private var transportTypeRawValue: Int = Int(MKDirectionsTransportType.cycling.rawValue)

    public var body: some View {
        Form {
            // Section 1: Bluetooth Cycling Sensors
            Section(header: Text("CYCLING SENSORS")) {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundStyle(.cyan)
                    Text("BLE Sensors")
                    Spacer()
                    Text("Active")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            // Section 2: Cycling Computer Preferences
            Section(header: Text("CYCLING COMPUTER")) {
                Toggle("Auto-Pause", isOn: $isAutoPauseEnabled)

                Picker("Auto-Lap", selection: $autoLapDistanceMeters) {
                    Text("Off").tag(Double.infinity)
                    Text("1 km").tag(1000.0)
                    Text("5 km").tag(5000.0)
                    Text("10 km").tag(10000.0)
                }

                Stepper("Max HR: \(maxHeartRate) bpm", value: $maxHeartRate, in: 140...220, step: 1)
            }

            // Section 3: Navigation Transport Mode
            Section(header: Text("NAVIGATION")) {
                Picker("Transport Mode", selection: $transportTypeRawValue) {
                    Text("Walking").tag(Int(MKDirectionsTransportType.walking.rawValue))
                    Text("Cycling").tag(Int(MKDirectionsTransportType.cycling.rawValue))
                    Text("Driving").tag(Int(MKDirectionsTransportType.automobile.rawValue))
                }
                .pickerStyle(.inline)
                .accessibilityLabel("Transport mode")
                .accessibilityHint("Select walking, cycling, or driving directions")
            }

            // Section 4: Apple Watch Ultra Action Button
            Section(header: Text("ACTION BUTTON")) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Apple Watch Ultra Action Button")
                        .font(.caption.bold())
                    Text("Configured to instantly trigger Lap Splits or Pause/Resume your ride.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .navigationTitle("Settings")
    }
}
