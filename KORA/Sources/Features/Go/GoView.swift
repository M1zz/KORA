import SwiftUI
import MapKit

struct GoView: View {
    @State private var viewModel = GoViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                map
                    .ignoresSafeArea(edges: .top)

                // 하단 패널
                VStack(spacing: 0) {
                    if let place = viewModel.selectedPlace {
                        SelectedPlacePanel(
                            place: place,
                            route: viewModel.currentRoute,
                            isCalculating: viewModel.isCalculatingRoute,
                            transportType: $viewModel.transportType,
                            onSwitchTransport: {
                                Task { await viewModel.calculateRoute(to: place) }
                            },
                            onNavigate: {
                                viewModel.openInAppleMaps(place)
                            },
                            onClose: {
                                viewModel.selectedPlace = nil
                                viewModel.clearRoute()
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        routePanel
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: viewModel.selectedPlace) { _, place in
            guard let place else { return }
            Task { await viewModel.calculateRoute(to: place) }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $viewModel.position) {
            // 저장된 장소 핀
            ForEach(viewModel.places) { place in
                Annotation("", coordinate: place.coordinate.clLocation) {
                    MapPinView(
                        place: place,
                        isSelected: viewModel.selectedPlace?.id == place.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedPlace = place
                        }
                    }
                }
            }

            // 경로 폴리라인
            if let route = viewModel.currentRoute {
                MapPolyline(route.polyline)
                    .stroke(
                        KORATheme.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
            }

            // 현재 위치
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Route Optimization Panel

    private var routePanel: some View {
        VStack(spacing: 12) {
            if !viewModel.optimizedRoute.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(viewModel.optimizedRoute.enumerated()), id: \.element.id) { idx, place in
                            HStack(spacing: 4) {
                                Text("\(idx + 1)")
                                    .font(.body).fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(KORATheme.accent)
                                    .clipShape(Circle())
                                Text(place.nameJP)
                                    .font(.body).fontWeight(.medium)
                                    .foregroundStyle(KORATheme.labelPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(KORATheme.surface)
                            .clipShape(Capsule())

                            if idx < viewModel.optimizedRoute.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.body)
                                    .foregroundStyle(KORATheme.labelTertiary)
                            }
                        }
                    }
                }
            }

            KORAPrimaryButton(
                viewModel.isOptimizing ? "最適化中..." : "動線を最適化する",
                icon: "arrow.triangle.turn.up.right.diamond.fill"
            ) {
                Task { await viewModel.optimizeRoute() }
            }
            .disabled(viewModel.isOptimizing || viewModel.places.isEmpty)
        }
        .padding(KORATheme.spacing16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusXL))
    }
}

// MARK: - Map Pin

struct MapPinView: View {
    let place: Place
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? KORATheme.accent : KORATheme.categoryColor(place.category))
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: .black.opacity(0.2), radius: 4)

                Image(systemName: place.category.systemImage)
                    .font(isSelected ? .title3 : .body)
                    .foregroundStyle(.white)
            }

            if isSelected {
                Text(place.nameJP)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Selected Place Panel

struct SelectedPlacePanel: View {
    let place: Place
    let route: MKRoute?
    let isCalculating: Bool
    @Binding var transportType: MKDirectionsTransportType
    let onSwitchTransport: () -> Void
    let onNavigate: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.nameJP)
                        .font(.body).fontWeight(.semibold)
                    if !place.name.isEmpty && place.name != place.nameJP {
                        Text(place.name)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }

            // 주소
            if !place.address.isEmpty {
                Label(place.address, systemImage: "mappin")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
            }

            // 교통수단 전환
            transportPicker

            // 경로 정보
            routeInfoRow

            // 안내 버튼
            KORAPrimaryButton("Appleマップで案内を開始", icon: "arrow.triangle.turn.up.right.circle.fill") {
                onNavigate()
            }
        }
        .padding(KORATheme.spacing16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusXL))
    }

    // MARK: - Transport Picker

    private var transportPicker: some View {
        HStack(spacing: 8) {
            transportButton(icon: "figure.walk", type: .walking, label: "徒歩")
            transportButton(icon: "car.fill", type: .automobile, label: "車")
        }
    }

    private func transportButton(icon: String, type: MKDirectionsTransportType, label: String) -> some View {
        Button {
            transportType = type
            onSwitchTransport()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.body).fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(transportType == type ? KORATheme.accent : KORATheme.surface)
            .foregroundStyle(transportType == type ? .white : KORATheme.labelSecondary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Route Info

    @ViewBuilder
    private var routeInfoRow: some View {
        if isCalculating {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("経路を計算中...")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
            }
        } else if let route {
            HStack(spacing: 16) {
                Label(formatDistance(route.distance), systemImage: "arrow.left.and.right")
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.accent)

                Label(formatTime(route.expectedTravelTime), systemImage: "clock")
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.accent)

                Spacer()
            }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : "\(Int(meters)) m"
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return minutes >= 60
            ? "\(minutes / 60)時間\(minutes % 60)分"
            : "\(minutes)分"
    }
}

#Preview {
    GoView()
}
