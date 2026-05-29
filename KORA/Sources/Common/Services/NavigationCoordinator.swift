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
    /// Real-world coordinates of the destination place (not the subway station).
    /// Used to fetch exit number from Odsay API.
    var destinationCoordinate: Coordinate? = nil
    var destinationPlaceName: String? = nil
    private(set) var routeRequestNonce: Int = 0

    /// URL handed off from the Share Extension. When set, MainTabView switches
    /// to the Save tab and SaveView pipes it into the URL parser.
    var pendingShareURL: String? = nil
    var pendingShareText: String? = nil
    private(set) var shareRequestNonce: Int = 0

    private init() {}

    func routeTo(station: String, fromCurrentLocation: Bool = false,
                 destinationCoordinate: Coordinate? = nil, destinationPlaceName: String? = nil) {
        pendingDestination = station
        autoFromCurrentLocation = fromCurrentLocation
        self.destinationCoordinate = destinationCoordinate
        self.destinationPlaceName = destinationPlaceName
        routeRequestNonce &+= 1
    }

    func clearPending() {
        pendingDestination = nil
        autoFromCurrentLocation = false
        destinationCoordinate = nil
        destinationPlaceName = nil
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
