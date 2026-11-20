//
//  KoreaNaviIntents.swift
//  KoreaNavi
//
//  Siri · 단축어로 길 안내를 시작한다.
//
//  - "Korea Navi, route to Gangnam": 말한 역을 도착역으로, 지금 위치에서 가까운 역을 출발역으로 연다.
//  - "Korea Navi nearest station": 가장 가까운 역과 거리를 알려 준다.
//
//  역 이름은 앱이 아는 모든 언어 표기(한국어 · 영어 · 일본어 · 중국어 …)로 찾는다.
//

import AppIntents
import CoreLocation
import Foundation

// MARK: - 앱 화면으로 넘기는 요청

@MainActor @Observable
final class KoreaNaviIntentRouter {
    static let shared = KoreaNaviIntentRouter()
    /// 도착역(한국어 정식 이름). 길 안내 화면이 받아 채우고 비운다.
    var destination: String?
}

// MARK: - 역

struct KoreaNaviStationEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Station", comment: "Siri: a subway station")
    )
    static let defaultQuery = KoreaNaviStationQuery()

    /// 한국어 정식 이름("강남"). 앱 안에서 역을 가리키는 값과 같다.
    let id: String

    var displayRepresentation: DisplayRepresentation {
        let language = StationLanguage.resolveFromSystemLocale()
        return DisplayRepresentation(title: "\(MetroLineData.displayBilingual(for: id, language: language))")
    }
}

struct KoreaNaviStationQuery: EntityStringQuery {
    private static var names: [String] { Array(MetroLineData.stationCoordinates.keys) }

    func entities(for identifiers: [String]) async throws -> [KoreaNaviStationEntity] {
        identifiers.filter { MetroLineData.stationCoordinates[$0] != nil }.map(KoreaNaviStationEntity.init)
    }

    /// 어느 언어 표기로 말해도 찾는다. 앞부분이 맞는 것이 먼저.
    func entities(matching string: String) async throws -> [KoreaNaviStationEntity] {
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
        return (prefix.sorted() + contains.sorted()).prefix(20).map(KoreaNaviStationEntity.init)
    }

    /// 마지막으로 고른 두 역.
    func suggestedEntities() async throws -> [KoreaNaviStationEntity] {
        ["kora.destination_station", "kora.current_station"]
            .compactMap { UserDefaults.standard.string(forKey: $0) }
            .filter { MetroLineData.stationCoordinates[$0] != nil }
            .map(KoreaNaviStationEntity.init)
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { !" -·.'’()역站駅".contains($0) }
    }
}

// MARK: - 인텐트

/// 그 역까지 가는 길을 연다.
struct KoreaNaviRouteIntent: AppIntent {
    static let title = LocalizedStringResource("Route to Station", comment: "Siri: start subway directions to a station")
    static let description = IntentDescription(
        LocalizedStringResource("Opens directions from the station nearest you to the station you choose.", comment: "Siri: route intent description")
    )
    static let openAppWhenRun = true

    @Parameter(title: LocalizedStringResource("Destination", comment: "Siri: destination station parameter"),
               description: LocalizedStringResource("The station you’re going to. Its name works in any language the app supports.", comment: "Siri: destination station parameter description"),
               requestValueDialog: IntentDialog(LocalizedStringResource("Which station are you going to?", comment: "Siri: ask destination")))
    var station: KoreaNaviStationEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        KoreaNaviIntentRouter.shared.destination = station.id
        return .result()
    }
}

/// 가장 가까운 역과 거리.
struct KoreaNaviNearestStationIntent: AppIntent {
    static let title = LocalizedStringResource("Nearest Station", comment: "Siri: nearest subway station")
    static let description = IntentDescription(
        LocalizedStringResource("Tells you the subway station closest to you.", comment: "Siri: nearest station description")
    )

    func perform() async throws -> some IntentResult & ReturnsValue<KoreaNaviStationEntity?> & ProvidesDialog {
        guard let here = CLLocationManager().location else {
            return .result(value: nil, dialog: IntentDialog(LocalizedStringResource("I don’t know where you are yet. Open Korea Navi once and allow location.", comment: "Siri: location unknown")))
        }
        guard let nearest = MetroLineData.nearestStation(latitude: here.coordinate.latitude, longitude: here.coordinate.longitude) else {
            return .result(value: nil, dialog: IntentDialog(LocalizedStringResource("There’s no station within 2 km.", comment: "Siri: no station nearby")))
        }
        let name = MetroLineData.displayBilingual(for: nearest.name, language: StationLanguage.resolveFromSystemLocale())
        let meters = Int(nearest.distanceMeters.rounded())
        return .result(
            value: KoreaNaviStationEntity(id: nearest.name),
            dialog: IntentDialog(LocalizedStringResource("The nearest station is \(name), \(meters) m away.", comment: "Siri: nearest station. Arguments: station name, meters"))
        )
    }
}

// MARK: - Siri 문구

struct KoreaNaviShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: KoreaNaviRouteIntent(),
            phrases: [
                "Route to \(\.$station) with \(.applicationName)",
                "Get subway directions with \(.applicationName)"
            ],
            shortTitle: "Route to Station",
            systemImageName: "tram.fill"
        )
        AppShortcut(
            intent: KoreaNaviNearestStationIntent(),
            phrases: [
                "\(.applicationName) nearest station",
                "Find the nearest station with \(.applicationName)"
            ],
            shortTitle: "Nearest Station",
            systemImageName: "location.circle"
        )
    }
}
