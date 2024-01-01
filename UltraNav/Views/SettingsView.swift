import SwiftUI
import MapKit
import CoreBluetooth

public struct SettingsView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(CyclingRideEngine.self) private var cyclingEngine
    @Environment(\.dismiss) private var dismiss
    @State private var sensorManager = BluetoothSensorManager.shared
    @State private var showingSensorScan: Bool = false

    public var body: some View {
        @Bindable var engine = cyclingEngine

        Form {
            // Section 1: Bluetooth Cycling Sensors
            Section(header: Text("CYCLING SENSORS")) {
                Button {
                    showingSensorScan = true
                    sensorManager.startScanning()
                } label: {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(.cyan)
                        Text("Pair BLE Sensors")
                        Spacer()
                        if sensorManager.connectedSensors.isEmpty {
                            Text("None")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(sensorManager.connectedSensors.count) connected")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }

                if let battery = sensorManager.sensorBatteryLevel {
                    HStack {
                        Image(systemName: "battery.75")
                            .foregroundStyle(.green)
                        Text("Sensor Battery")
                        Spacer()
                        Text("\(battery)%")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Section 2: Cycling Computer Preferences
            Section(header: Text("CYCLING COMPUTER")) {
                Toggle("Auto-Pause", isOn: $engine.isAutoPauseEnabled)

                Picker("Auto-Lap", selection: $engine.autoLapDistanceMeters) {
                    Text("Off").tag(Double.infinity)
                    Text("1 km").tag(1000.0)
                    Text("5 km").tag(5000.0)
                    Text("10 km").tag(10000.0)
                }

                Stepper("Max HR: \(engine.maxHeartRate) bpm", value: $engine.maxHeartRate, in: 140...220, step: 1)
            }

            // Section 3: Navigation Transport Mode
            Section(header: Text("NAVIGATION")) {
                Picker("Transport Mode", selection: transportSelection) {
                    Text("Walking").tag(MKDirectionsTransportType.walking.rawValue)
                    Text("Cycling").tag(MKDirectionsTransportType.cycling.rawValue)
                    Text("Driving").tag(MKDirectionsTransportType.automobile.rawValue)
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
        .sheet(isPresented: $showingSensorScan) {
            SensorPairingSheet()
        }
    }

    private var transportSelection: Binding<UInt> {
        Binding(
            get: { navigationModel.transportType.rawValue },
            set: { navigationModel.transportType = MKDirectionsTransportType(rawValue: $0) }
        )
    }
}

private struct SensorPairingSheet: View {
    @State private var sensorManager = BluetoothSensorManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: HStack {
                    Text("DISCOVERED SENSORS")
                    Spacer()
                    if sensorManager.isScanning {
                        ProgressView().controlSize(.small)
                    }
                }) {
                    if sensorManager.discoveredSensors.isEmpty {
                        Text("Searching for Power Meters, Cadence, Speed & HR Straps...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sensorManager.discoveredSensors) { sensor in
                            Button {
                                if sensor.isConnected {
                                    sensorManager.disconnect(sensor: sensor)
                                } else {
                                    sensorManager.connect(sensor: sensor)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sensor.name)
                                            .font(.headline)
                                        Text(sensor.isConnected ? "Connected" : "Tap to Pair")
                                            .font(.caption2)
                                            .foregroundStyle(sensor.isConnected ? .green : .secondary)
                                    }
                                    Spacer()
                                    if sensor.isConnected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sensors")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        sensorManager.stopScanning()
                        dismiss()
                    }
                }
            }
        }
    }
}
