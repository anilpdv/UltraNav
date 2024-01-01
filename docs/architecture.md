# UltraNav Architecture and User Flows

UltraNav is a single-target watchOS cycling-navigation application built with SwiftUI, Observation, MapKit, Core Location, and WatchKit. This audit records the repository architecture and implemented behaviour verified on 28 September 2026.

## Target map

```text
UltraNav.xcodeproj
└── UltraNav application target
    ├── Product: UltraNav.app
    ├── Platform: watchOS and watchOS Simulator
    ├── Deployment target: watchOS 11.0
    ├── Swift language mode: Swift 6
    ├── Sources
    │   ├── UltraNav/UltraNavApp.swift
    │   ├── UltraNav/ContentView.swift
    │   └── UltraNav/NavigationModel.swift
    ├── Configuration
    │   ├── UltraNav/Info.plist
    │   └── UltraNav/UltraNav.entitlements
    └── Apple frameworks
        ├── SwiftUI
        ├── Observation
        ├── MapKit
        ├── CoreLocation
        └── WatchKit