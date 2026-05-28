import Foundation
import Observation

/// App-wide navigation intent bus.
/// Used to bridge Save → Subway: "route me to this saved place".
@MainActor
@Observable
final class NavigationCoordinator {
    static let shared = NavigationCoordinator()

    /// Destination station (canonical Korean name, no "역" suffix) requested
    /// by another tab. When set, MainTabView switches to the Subway tab and
    /// SubwayNavigatorView prefills its `toStation`.
    var pendingDestination: String? = nil
    /// When true, Subway tab should auto-detect the user's current location and
    /// use the nearest station as the journey's `from`.
    var autoFromCurrentLocation: Bool = false
    private(set) var routeRequestNonce: Int = 0

    /// URL handed off from the Share Extension. When set, MainTabView switches
    /// to the Save tab and SaveView pipes it into the URL parser.
    var pendingShareURL: String? = nil
    var pendingShareText: String? = nil
    private(set) var shareRequestNonce: Int = 0

    private init() {}

    func routeTo(station: String, fromCurrentLocation: Bool = false) {
        pendingDestination = station
        autoFromCurrentLocation = fromCurrentLocation
        routeRequestNonce &+= 1
    }

    func clearPending() {
        pendingDestination = nil
        autoFromCurrentLocation = false
    }

    func receiveSharedURL(_ url: String, text: String? = nil) {
        pendingShareURL = url
        pendingShareText = text
        shareRequestNonce &+= 1
    }

    func clearShare() {
        pendingShareURL = nil
        pendingShareText = nil
    }
}
