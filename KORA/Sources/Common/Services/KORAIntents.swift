//
//  KORAIntents.swift
//  KORA
//
//  Siri · 단축어로 길 안내를 시작한다.
//
//  - "KORA, route to Gangnam": 말한 역을 도착역으로, 지금 위치에서 가까운 역을 출발역으로 연다.
//  - "KORA nearest station": 가장 가까운 역과 거리를 알려 준다.
//
//  역 이름은 앱이 아는 모든 언어 표기(한국어 · 영어 · 일본어 · 중국어 …)로 찾는다.
//

import AppIntents
import CoreLocation
import Foundation

// MARK: - 앱 화면으로 넘기는 요청

@MainActor @Observable
final class KORAIntentRouter {
    static let shared = KORAIntentRouter()
    /// 도착역(한국어 정식 이름). 길 안내 화면이 받아 채우고 비운다.
    var destination: String?
}

// MARK: - 역

struct KORAStationEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Station", comment: "Siri: a subway station")
    )
    static let defaultQuery = KORAStationQuery()

    /// 한국어 정식 이름("강남"). 앱 안에서 역을 가리키는 값과 같다.
    let id: String

    var displayRepresentation: DisplayRepresentation {
        let language = StationLanguage.resolveFromSystemLocale()
        return DisplayRepresentation(title: "\(MetroLineData.displayBilingual(for: id, language: language))")
    }
}

struct KORAStationQuery: EntityStringQuery {
    private static var names: [String] { Array(MetroLineData.stationCoordinates.keys) }

    func entities(for identifiers: [String]) async throws -> [KORAStationEntity] {
        identifiers.filter { MetroLineData.stationCoordinates[$0] != nil }.map(KORAStationEntity.init)
    }

    /// 어느 언어 표기로 말해도 찾는다. 앞부분이 맞는 것이 먼저.
    func entities(matching string: String) async throws -> [KORAStationEntity] {
        let query = Self.fold(string)
        guard !query.isEmpty else { return [] }
        var prefix: [String] = []
        var contains: [String] = []
        for ko in Self.names {
            let spellings = [ko] + StationLanguage.allCases.map { MetroLineData.displayName(for: ko, language: $0) }
            let keys = spellings.map(Self.fold)
            if keys.contains(where: { $0.hasPrefix(query) }) { prefix.append(ko) }
            else if keys.contains(where: { $0.contains(query) }) { contains.append(ko) }
        }
        return (prefix.sorted() + contains.sorted()).prefix(20).map(KORAStationEntity.init)
    }

    /// 마지막으로 고른 두 역.
    func suggestedEntities() async throws -> [KORAStationEntity] {
        ["kora.destination_station", "kora.current_station"]
            .compactMap { UserDefaults.standard.string(forKey: $0) }
            .filter { MetroLineData.stationCoordinates[$0] != nil }
            .map(KORAStationEntity.init)
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { !" -·.'’()역站駅".contains($0) }
    }
}

// MARK: - 인텐트

/// 그 역까지 가는 길을 연다.
struct KORARouteIntent: AppIntent {
    static let title = LocalizedStringResource("Route to Station", comment: "Siri: start subway directions to a station")
    static let description = IntentDescription(
        LocalizedStringResource("Opens directions from the station nearest you to the station you choose.", comment: "Siri: route intent description")
    )
    static let openAppWhenRun = true

    @Parameter(title: LocalizedStringResource("Destination", comment: "Siri: destination station parameter"),
               requestValueDialog: IntentDialog(LocalizedStringResource("Which station are you going to?", comment: "Siri: ask destination")))
    var station: KORAStationEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        KORAIntentRouter.shared.destination = station.id
        return .result()
    }
}

/// 가장 가까운 역과 거리.
struct KORANearestStationIntent: AppIntent {
    static let title = LocalizedStringResource("Nearest Station", comment: "Siri: nearest subway station")
    static let description = IntentDescription(
        LocalizedStringResource("Tells you the subway station closest to you.", comment: "Siri: nearest station description")
    )

    func perform() async throws -> some IntentResult & ReturnsValue<KORAStationEntity?> & ProvidesDialog {
        guard let here = CLLocationManager().location else {
            return .result(value: nil, dialog: IntentDialog(LocalizedStringResource("I don’t know where you are yet. Open KORA once and allow location.", comment: "Siri: location unknown")))
        }
        guard let nearest = MetroLineData.nearestStation(latitude: here.coordinate.latitude, longitude: here.coordinate.longitude) else {
            return .result(value: nil, dialog: IntentDialog(LocalizedStringResource("There’s no station within 2 km.", comment: "Siri: no station nearby")))
        }
        let name = MetroLineData.displayBilingual(for: nearest.name, language: StationLanguage.resolveFromSystemLocale())
        let meters = Int(nearest.distanceMeters.rounded())
        return .result(
            value: KORAStationEntity(id: nearest.name),
            dialog: IntentDialog(LocalizedStringResource("The nearest station is \(name), \(meters) m away.", comment: "Siri: nearest station. Arguments: station name, meters"))
        )
    }
}

// MARK: - Siri 문구

struct KORAShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: KORARouteIntent(),
            phrases: [
                "Route to \(\.$station) with \(.applicationName)",
                "Get subway directions with \(.applicationName)"
            ],
            shortTitle: "Route to Station",
            systemImageName: "tram.fill"
        )
        AppShortcut(
            intent: KORANearestStationIntent(),
            phrases: [
                "\(.applicationName) nearest station",
                "Find the nearest station with \(.applicationName)"
            ],
            shortTitle: "Nearest Station",
            systemImageName: "location.circle"
        )
    }
}
