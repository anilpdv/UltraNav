import SwiftUI
import MapKit
import CoreLocation
import WatchKit

@MainActor
@Observable
final class NavigationModel: NSObject, CLLocationManagerDelegate {
    enum State: Equatable {
        case idle
        case searching
        case emptySearch(query: String)
        case calculatingRoute(destinationName: String)
        case preview
        case navigating
        case rerouting
        case error(String)
    }

    var state: State = .idle
    var searchState: ScreenState<[MKMapItem]> = .idle
    var routeState: ScreenState<MKRoute> = .idle
    var query = ""
    var searchResults: [MKMapItem] = []
    var selectedDestination: MKMapItem?
    var route: MKRoute?
    var currentLocation: CLLocation?
    var cameraPosition: MapCameraPosition = .automatic
    var travelledDistance: CLLocationDistance = 0
    var transportType: MKDirectionsTransportType = .automobile

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastRerouteLocation: CLLocation?
    private var searchTask: Task<Void, Never>?
    private var routeTask: Task<Void, Never>?
    private var failedOperation: FailedOperation?

#if targetEnvironment(simulator)
    private static let simulatorLocation = CLLocation(
        latitude: 37.3349,
        longitude: -122.0090
    )
#endif

    private enum FailedOperation {
        case location
        case search
        case route(MKMapItem)
        case reroute(MKMapItem)
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
#if !targetEnvironment(simulator)
        locationManager.allowsBackgroundLocationUpdates = true
#endif
    }

    var nextStep: MKRoute.Step? {
        guard let route, let location = currentLocation else {
            return route?.steps.first(where: { !$0.instructions.isEmpty })
        }

        return route.steps
            .filter { !$0.instructions.isEmpty }
            .min {
                CLLocation(
                    latitude: $0.polyline.coordinate.latitude,
                    longitude: $0.polyline.coordinate.longitude
                ).distance(from: location)
                <
                CLLocation(
                    latitude: $1.polyline.coordinate.latitude,
                    longitude: $1.polyline.coordinate.longitude
                ).distance(from: location)
            }
    }

    var distanceToNextStep: CLLocationDistance? {
        guard let step = nextStep, let location = currentLocation else { return nil }
        return location.distance(
            from: CLLocation(
                latitude: step.polyline.coordinate.latitude,
                longitude: step.polyline.coordinate.longitude
            )
        )
    }

    func requestLocationAccess() {
        AppLogger.lifecycle.info("Requesting location authorisation")
#if targetEnvironment(simulator)
        if currentLocation == nil {
            currentLocation = Self.simulatorLocation
        }
#endif
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func submitSearch() {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, !searchState.isLoading else { return }

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.performSearch(term: term)
        }
    }

    func select(_ destination: MKMapItem) {
        guard !routeState.isLoading else { return }

        routeTask?.cancel()
        routeTask = Task { [weak self] in
            await self?.performSelection(destination)
        }
    }

    func retry() {
        switch failedOperation {
        case .location:
            state = .idle
            requestLocationAccess()
        case .search:
            searchState = .idle
            submitSearch()
        case .route(let destination):
            routeState = .idle
            select(destination)
        case .reroute(let destination):
            routeState = .idle
            startRouteTask(to: destination, beginNavigation: true)
        case nil:
            state = .idle
        }
    }

    func resetSearch() {
        searchTask?.cancel()
        searchTask = nil
        searchResults = []
        searchState = .idle
        state = .idle
    }

    func startNavigation() {
        guard route != nil else { return }
        failedOperation = nil
        state = .navigating
        travelledDistance = 0
        lastLocation = currentLocation
        lastRerouteLocation = currentLocation
        locationManager.startUpdatingLocation()
        WKInterfaceDevice.current().play(.start)
    }

    func recenterOnUser() {
        guard let location = currentLocation else { return }
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: location.coordinate,
                distance: 500,
                heading: max(0, location.course),
                pitch: 42
            )
        )
    }

    func stopNavigation() {
        searchTask?.cancel()
        routeTask?.cancel()
        searchTask = nil
        routeTask = nil
        locationManager.stopUpdatingLocation()
        state = .idle
        searchState = .idle
        routeState = .idle
        route = nil
        selectedDestination = nil
        searchResults = []
        travelledDistance = 0
        lastLocation = nil
        lastRerouteLocation = nil
        failedOperation = nil
        WKInterfaceDevice.current().play(.stop)
    }

    private func performSearch(term: String) async {
        searchState = .loading
        state = .searching
        AppLogger.networking.info("Starting local destination search")
        failedOperation = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        if let currentLocation {
            request.region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                latitudinalMeters: 30_000,
                longitudinalMeters: 30_000
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            try Task.checkCancellation()

            let results = Array(response.mapItems.prefix(8))
            searchResults = results

            if results.isEmpty {
                AppLogger.networking.info("Destination search completed with no results")
                searchState = .empty
                state = .emptySearch(query: term)
            } else {
                AppLogger.networking.info("Destination search completed successfully")
                searchState = .loaded(results)
                state = .idle
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            AppLogger.networking.error("Destination search failed: \(String(describing: type(of: error)), privacy: .public)")
            let message = "Search failed. Check your internet connection and try again."
            failedOperation = .search
            searchState = .failed(message: message)
            state = .error(message)
        }
    }

    private func performSelection(_ destination: MKMapItem) async {
        selectedDestination = destination
        searchResults = []
        await calculateRoute(to: destination, beginNavigation: false)
    }

    private func startRouteTask(to destination: MKMapItem, beginNavigation: Bool) {
        guard !routeState.isLoading else { return }

        routeTask?.cancel()
        routeTask = Task { [weak self] in
            await self?.calculateRoute(to: destination, beginNavigation: beginNavigation)
        }
    }

    private func calculateRoute(to destination: MKMapItem, beginNavigation: Bool) async {
        guard let currentLocation else {
            let message = "Waiting for a GPS fix. Move outdoors and try again."
            failedOperation = .location
            routeState = .failed(message: message)
            state = .error(message)
            return
        }

        routeState = .loading
        AppLogger.networking.info("Starting route calculation; reroute: \(beginNavigation, privacy: .public)")
        state = beginNavigation
            ? .rerouting
            : .calculatingRoute(destinationName: destination.name ?? "destination")

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: currentLocation.coordinate)
        )
        request.destination = destination
        request.transportType = transportType
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            try Task.checkCancellation()

            guard let firstRoute = response.routes.first else {
                AppLogger.networking.notice("Route calculation returned no route")
                failedOperation = beginNavigation ? .reroute(destination) : .route(destination)
                routeState = .empty
                state = .error("No \(transportType.name) route was found.")
                return
            }

            route = firstRoute
            routeState = .loaded(firstRoute)
            cameraPosition = .rect(firstRoute.polyline.boundingMapRect)
            failedOperation = nil
            AppLogger.networking.info("Route calculation completed successfully")
            state = beginNavigation ? .navigating : .preview

            if beginNavigation {
                WKInterfaceDevice.current().play(.directionUp)
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            AppLogger.networking.error("Route calculation failed: \(String(describing: type(of: error)), privacy: .public)")

            let message = "Directions are unavailable for this destination."
            failedOperation = beginNavigation ? .reroute(destination) : .route(destination)
            routeState = .failed(message: message)

            if beginNavigation, route != nil {
                state = .navigating
            } else {
                state = .error(message)
            }
        }
    }

    private func rerouteIfNeeded(from location: CLLocation) {
        guard state == .navigating,
              !routeState.isLoading,
              let route,
              let destination = selectedDestination else { return }

        let routePoint = route.polyline.closestCoordinate(to: location.coordinate)
        let routeLocation = CLLocation(
            latitude: routePoint.latitude,
            longitude: routePoint.longitude
        )
        guard location.distance(from: routeLocation) > 60 else { return }

        if let lastRerouteLocation,
           location.distance(from: lastRerouteLocation) < 100 {
            return
        }

        lastRerouteLocation = location
        startRouteTask(to: destination, beginNavigation: true)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                AppLogger.lifecycle.info("Location authorisation is available")
                self.locationManager.startUpdatingLocation()
            case .denied, .restricted:
                AppLogger.lifecycle.notice("Location authorisation is unavailable")
                let message = "Location access is required for navigation."
                self.failedOperation = .location
                self.routeState = .failed(message: message)
                self.state = .error(message)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let newest = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentLocation = newest

            if self.state == .navigating || self.state == .rerouting {
                if let lastLocation = self.lastLocation, newest.horizontalAccuracy >= 0 {
                    let increment = newest.distance(from: lastLocation)
                    if increment < 100 {
                        self.travelledDistance += increment
                    }
                }

                self.lastLocation = newest
                self.cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: newest.coordinate,
                        distance: 450,
                        heading: max(0, newest.course),
                        pitch: 45
                    )
                )

                if self.state == .navigating {
                    self.rerouteIfNeeded(from: newest)
                }
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        guard (error as? CLError)?.code != .locationUnknown else { return }
        AppLogger.lifecycle.error("Location update failed: \(String(describing: type(of: error)), privacy: .public)")
        Task { @MainActor [weak self] in
            let message = "GPS could not determine your location."
            self?.failedOperation = .location
            self?.routeState = .failed(message: message)
            self?.state = .error(message)
        }
    }
}

private extension MKPolyline {
    func closestCoordinate(to target: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard pointCount > 0 else { return target }

        let targetPoint = MKMapPoint(target)
        let points = points()
        var closestPoint = points[0]
        var shortestDistance = targetPoint.distance(to: closestPoint)

        for index in 1..<pointCount {
            let distance = targetPoint.distance(to: points[index])
            if distance < shortestDistance {
                shortestDistance = distance
                closestPoint = points[index]
            }
        }

        return closestPoint.coordinate
    }
}