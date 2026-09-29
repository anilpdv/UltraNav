# Device & Hardware Test Matrix

## 1. Hardware Tiers & Environments

| Dimension | Simulator | Physical Apple Watch |
|---|---|---|
| **Platform** | watchOS 10+ Simulator (`x86_64` / `arm64`) | Apple Watch Series 8, 9, Ultra, Ultra 2 |
| **GPS** | Simulated locations via `LocationFixture` / GPX playback | Dual-frequency L1/L5 GPS |
| **HealthKit** | In-memory `FakeWorkoutProvider` | Live `HKWorkoutSession` & `HKLiveWorkoutBuilder` |
| **Bluetooth** | In-memory `FakeSensorProvider` & `FakeCentralManager` | Live CoreBluetooth Central Manager (BLE Power, HR, CSC) |
| **Haptics** | `FakeHapticProvider` / `HapticRecorder` | WkInterfaceDevice click/pattern generation |
| **Battery & Thermal** | N/A (profiling in Instruments) | 1-hour, 4-hour, 8-hour endurance testing on Ultra |

---

## 2. CI Test Execution Commands

### Full Unit & Integration Suite:
```bash
xcodebuild \
  -project UltraNav.xcodeproj \
  -scheme UltraNav \
  -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 2 (49mm)' \
  test \
  -only-testing:UltraNavTests
```

### Subsystem Specific Test Runs:
```bash
# Ride Lifecycle
xcodebuild -project UltraNav.xcodeproj -scheme UltraNav -destination 'platform=watchOS Simulator,id=DDF0DEC5-1398-49B0-93E2-AABAB423884D' test -only-testing:UltraNavTests/CompleteRideLifecycleIntegrationTests

# Navigation & Climbs
xcodebuild -project UltraNav.xcodeproj -scheme UltraNav -destination 'platform=watchOS Simulator,id=DDF0DEC5-1398-49B0-93E2-AABAB423884D' test -only-testing:UltraNavTests/NavigationEngineIntegrationTests

# Concurrency & Races
xcodebuild -project UltraNav.xcodeproj -scheme UltraNav -destination 'platform=watchOS Simulator,id=DDF0DEC5-1398-49B0-93E2-AABAB423884D' test -only-testing:UltraNavTests/CancellationAndRaceIntegrationTests
```
