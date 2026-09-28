import CoreBluetooth

enum CoreBluetoothServiceUUID {
    static var heartRate: CBUUID { CBUUID(string: "180D") }
    static var cyclingSpeedAndCadence: CBUUID { CBUUID(string: "1816") }
    static var cyclingPower: CBUUID { CBUUID(string: "1818") }
    static var battery: CBUUID { CBUUID(string: "180F") }
}

enum CoreBluetoothCharacteristicUUID {
    static var heartRateMeasurement: CBUUID { CBUUID(string: "2A37") }
    static var cscMeasurement: CBUUID { CBUUID(string: "2A5B") }
    static var cyclingPowerMeasurement: CBUUID { CBUUID(string: "2A63") }
    static var sensorLocation: CBUUID { CBUUID(string: "2A5D") }
    static var cscFeature: CBUUID { CBUUID(string: "2A5C") }
    static var cyclingPowerFeature: CBUUID { CBUUID(string: "2A65") }
    static var batteryLevel: CBUUID { CBUUID(string: "2A19") }
}
