import SwiftUI
import MapKit

// MARK: - Place Map View

struct PlaceMapView: View {
    let places: [Place]
    @Binding var selectedPlace: Place?
    @State private var mapSelection: UUID?

    private var locatablePlaces: [Place] { places.filter { $0.hasLocation } }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: initialCameraPosition, selection: $mapSelection) {
                ForEach(locatablePlaces) { place in
                    Annotation(
                        place.nameJP.isEmpty ? place.name : place.nameJP,
                        coordinate: place.coordinate.clLocation,
                        anchor: .bottom
                    ) {
                        PlaceMapPin(
                            category: place.category,
                            isSelected: selectedPlace?.id == place.id
                        )
                    }
                    .tag(place.id)
                }
            }
            .mapStyle(.standard)
            .onChange(of: mapSelection) { _, id in
                withAnimation(.spring(response: 0.35)) {
                    selectedPlace = id == nil ? nil : locatablePlaces.first { $0.id == id }
                }
            }

            if let place = selectedPlace {
                selectedCard(place)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPlace?.id)
    }

    // MARK: - Camera Position

    private var initialCameraPosition: MapCameraPosition {
        guard !places.isEmpty,
              let minLat = places.map(\.coordinate.latitude).min(),
              let maxLat = places.map(\.coordinate.latitude).max(),
              let minLon = places.map(\.coordinate.longitude).min(),
              let maxLon = places.map(\.coordinate.longitude).max()
        else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            ))
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.06, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.06, (maxLon - minLon) * 1.6)
        )
        return .region(MKCoordinateRegion(center: center, span: span))
    }

    // MARK: - Selected Card

    @ViewBuilder
    private func selectedCard(_ place: Place) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 4)

            PlaceCardView(place: place, onRoute: { p in
                guard !p.nearestStation.isEmpty else { return }
                NavigationCoordinator.shared.routeTo(station: p.nearestStation)
            })
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 16, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Map Pin

struct PlaceMapPin: View {
    let category: PlaceCategory
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(KORATheme.categoryColor(category).opacity(0.25))
                    .frame(width: 56, height: 56)
            }
            Circle()
                .fill(KORATheme.categoryColor(category))
                .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                .shadow(
                    color: KORATheme.categoryColor(category).opacity(0.5),
                    radius: isSelected ? 8 : 4
                )
            Image(systemName: category.systemImage)
                .font(.system(size: isSelected ? 18 : 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
