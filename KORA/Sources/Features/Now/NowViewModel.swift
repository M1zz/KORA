import SwiftUI
import CoreLocation
import Observation

@MainActor
@Observable
final class NowViewModel: NSObject {
    var events: [NowEvent] = []
    var isLoadingLocation: Bool = false
    var locationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let store = PlaceStore.shared

    var nearbyPlaces: [Place] { store.places.filter { $0.isOpen } }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        isLoadingLocation = true
        locationManager.requestWhenInUseAuthorization()
    }
}

extension NowViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else {
            isLoadingLocation = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoadingLocation = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
    }
}

// MARK: - Now Event Model

struct NowEvent: Identifiable {
    let id: UUID
    let titleJP: String
    let locationJP: String
    let startTime: String
    let endTime: String
    let category: EventCategory
    let distanceM: Int

    enum EventCategory: String {
        case kpop = "K-POP"
        case popup = "ポップアップ"
        case festival = "フェスティバル"
        case market = "マーケット"

        var color: String {
            switch self {
            case .kpop:     return "#534AB7"
            case .popup:    return "#D85A30"
            case .festival: return "#1D9E75"
            case .market:   return "#BA7517"
            }
        }
    }
}
