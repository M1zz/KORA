import SwiftUI
import MapKit
import Observation

@MainActor
@Observable
final class GoViewModel {
    var selectedPlace: Place? = nil
    var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5519, longitude: 126.9245),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    var isOptimizing: Bool = false
    var optimizedRoute: [Place] = []

    // MARK: - Routing
    var currentRoute: MKRoute? = nil
    var isCalculatingRoute: Bool = false
    var transportType: MKDirectionsTransportType = .walking

    private let store = PlaceStore.shared

    var places: [Place] {
        store.places.filter { $0.coordinate.latitude != 0 || $0.coordinate.longitude != 0 }
    }

    // MARK: - Apple Maps In-App Route

    func calculateRoute(to place: Place) async {
        guard place.coordinate.latitude != 0 else { return }
        isCalculatingRoute = true
        currentRoute = nil

        let request = MKDirections.Request()
        request.source = .forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate.clLocation))
        request.transportType = transportType

        do {
            let response = try await MKDirections(request: request).calculate()
            currentRoute = response.routes.first

            // 경로가 있으면 카메라를 경로 전체가 보이도록 이동
            if let route = currentRoute {
                let rect = route.polyline.boundingMapRect
                let padded = rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)
                position = .rect(padded)
            }
        } catch {
            currentRoute = nil
        }
        isCalculatingRoute = false
    }

    // MARK: - Apple Maps App (외부)

    func openInAppleMaps(_ place: Place) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate.clLocation))
        item.name = place.nameJP
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: transportType == .walking
                ? MKLaunchOptionsDirectionsModeWalking
                : MKLaunchOptionsDirectionsModeDriving
        ])
    }

    func clearRoute() {
        currentRoute = nil
    }

    // MARK: - Route Optimization (그리디)

    func optimizeRoute() async {
        isOptimizing = true
        try? await Task.sleep(nanoseconds: 800_000_000)

        var remaining = places
        var route: [Place] = []
        guard var current = remaining.first else { isOptimizing = false; return }
        remaining.removeFirst()
        route.append(current)

        while !remaining.isEmpty {
            let nearest = remaining.min { distance(from: current, to: $0) < distance(from: current, to: $1) }!
            route.append(nearest)
            remaining.removeAll { $0.id == nearest.id }
            current = nearest
        }

        optimizedRoute = route
        isOptimizing = false
    }

    private func distance(from a: Place, to b: Place) -> Double {
        CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude)
            .distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
    }
}
