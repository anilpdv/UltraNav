# Metric Source Inventory

| Metric Field | Primary Source | Secondary Source | Fallback Source | Validation Rules |
| :--- | :--- | :--- | :--- | :--- |
| **Speed** | BLE Cycling Speed (`.bluetooth`) | CoreLocation (`.coreLocation`) | Derived from distance/time | 0.0 .. 70.0 m/s, finite |
| **Heart Rate** | BLE Heart Rate Strap (`.bluetooth`) | HealthKit Watch Sensor (`.healthKit`) | None | 30 .. 260 bpm |
| **Cadence** | BLE Power / Cadence Sensor (`.bluetooth`) | None | None | 0.0 .. 250.0 RPM, finite |
| **Power** | BLE Cycling Power Meter (`.bluetooth`) | None | None | 0 .. 3000 W |
| **Distance** | HealthKit Live Workout (`.healthKit`) | CoreLocation accumulation | GPX Route geometry | >= 0.0 m, monotonic |
| **Altitude** | CoreLocation / Barometer (`.coreLocation`) | GPX elevation track | None | -500.0 .. 9000.0 m |
| **Active Energy**| HealthKit Live Workout (`.healthKit`) | None | None | >= 0.0 kcal |
