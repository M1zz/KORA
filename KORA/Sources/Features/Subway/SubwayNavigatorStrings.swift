import Foundation

/// Per-language UI string for the Subway Navigator screen. Resolves via the
/// user's chosen `StationLanguage` so the entire flow reads cleanly in one
/// language — no Japanese/Korean mixing.
struct NavLoc {
    let ko: String
    let ja: String
    let en: String
    let zh: String

    func resolved(_ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return ko
        case .japanese: return ja
        case .english:  return en
        case .chinese:  return zh
        }
    }
}

// MARK: - Catalog

extension NavLoc {
    // Welcome / initial state
    static let welcomeTitle = NavLoc(
        ko: "지금 어느 역이세요?",
        ja: "今いる駅は？",
        en: "What station are you at?",
        zh: "您现在在哪一站？"
    )
    static let welcomeHintDefault = NavLoc(
        ko: "먼저 출발역을 알려주세요",
        ja: "まずは出発駅を教えてください",
        en: "Tell us your starting station first",
        zh: "请先告诉我们您的出发车站"
    )
    static let welcomeHintNoGPS = NavLoc(
        ko: "GPS를 사용할 수 없으면 아래에서 역을 직접 골라주세요",
        ja: "GPSが使えない場合は下から駅を選んでください",
        en: "If GPS isn't available, pick a station below",
        zh: "如果 GPS 无法使用,请从下方选择车站"
    )
    static let useGPS = NavLoc(
        ko: "GPS로 현재 위치 가져오기",
        ja: "GPSで現在地を取得",
        en: "Get my location with GPS",
        zh: "用 GPS 获取当前位置"
    )
    static let pickStationManually = NavLoc(
        ko: "역을 직접 선택",
        ja: "駅を手動で選ぶ",
        en: "Pick a station manually",
        zh: "手动选择车站"
    )
    static let footerNote = NavLoc(
        ko: "선택한 역은 다음 실행 때도 기억돼요",
        ja: "選んだ駅は次回起動時にも記憶されます",
        en: "Your station will be remembered next time",
        zh: "您选择的车站会保留到下次启动"
    )

    // Destination CTA / no-journey state
    static let whereToGo = NavLoc(
        ko: "어디로 가시나요?",
        ja: "どこに行きますか？",
        en: "Where to?",
        zh: "想去哪里?"
    )
    static let tapStationForRoute = NavLoc(
        ko: "역을 탭하면 경로가 보여요",
        ja: "駅をタップして経路を表示",
        en: "Tap a station to see the route",
        zh: "点击车站查看路线"
    )

    // Station search sheet
    static let currentStationTitle = NavLoc(
        ko: "현재 역",
        ja: "現在地",
        en: "Current station",
        zh: "当前车站"
    )
    static let destinationTitle = NavLoc(
        ko: "목적지",
        ja: "目的地",
        en: "Destination",
        zh: "目的地"
    )
    static let searchPrompt = NavLoc(
        ko: "역 이름",
        ja: "駅名",
        en: "Station name",
        zh: "车站名"
    )
    static let allLines = NavLoc(
        ko: "전체 노선",
        ja: "全路線",
        en: "All lines",
        zh: "所有线路"
    )
    static let noMatchingStation = NavLoc(
        ko: "일치하는 역이 없어요",
        ja: "該当する駅が見つかりません",
        en: "No matching station",
        zh: "没有找到匹配的车站"
    )

    // Ride / boarding flow
    static let confirmInTrainDisplay = NavLoc(
        ko: "차내 안내로 확인하세요",
        ja: "車内表示で確認",
        en: "Check the in-train display",
        zh: "请查看车内显示"
    )
    static let arrived = NavLoc(
        ko: "도착!",
        ja: "到着!",
        en: "Arrived!",
        zh: "到达!"
    )
    static let arrivingSoon = NavLoc(
        ko: "곧 도착",
        ja: "まもなく到着",
        en: "Arriving soon",
        zh: "即将到达"
    )
    static let nextTrain = NavLoc(
        ko: "다음 열차",
        ja: "次の電車",
        en: "Next train",
        zh: "下一班列车"
    )
    static let waitingToDepart = NavLoc(
        ko: "발차 대기 중",
        ja: "発車待ち",
        en: "Waiting to depart",
        zh: "等待发车"
    )
    static let startOver = NavLoc(
        ko: "처음부터 다시",
        ja: "最初からもう一度",
        en: "Start over",
        zh: "重新开始"
    )
    static let didYouBoard = NavLoc(
        ko: "탑승했어요?",
        ja: "乗車しましたか？",
        en: "Did you board?",
        zh: "上车了吗?"
    )
    static let didYouGetOff = NavLoc(
        ko: "내렸어요?",
        ja: "降りましたか？",
        en: "Did you get off?",
        zh: "下车了吗?"
    )
    static let tapWhenOff = NavLoc(
        ko: "내리면 탭",
        ja: "降りたらタップ",
        en: "Tap when you get off",
        zh: "下车后点击"
    )
    static let currentlyAt = NavLoc(
        ko: "현재 위치",
        ja: "現在地",
        en: "Currently at",
        zh: "当前位置"
    )
    static let correctPosition = NavLoc(
        ko: "현재 위치 수정",
        ja: "現在地を修正",
        en: "Correct my position",
        zh: "修正当前位置"
    )
    static let pickCurrentStation = NavLoc(
        ko: "지금 어느 역인가요?",
        ja: "今どの駅にいますか？",
        en: "Which station are you at now?",
        zh: "您现在在哪一站?"
    )
    static let gpsSuggestion = NavLoc(
        ko: "위치 기반 추천",
        ja: "位置情報からの候補",
        en: "Location-based guess",
        zh: "根据位置推荐"
    )
    static let searchingLocation = NavLoc(
        ko: "현재 위치 확인 중...",
        ja: "現在地を取得中...",
        en: "Locating you...",
        zh: "正在定位..."
    )
    static let stopsToAlight = NavLoc(
        ko: "내릴 곳까지",
        ja: "降車駅まで",
        en: "Until you get off",
        zh: "到下车站"
    )
    static let etaLabel = NavLoc(
        ko: "도착 예정",
        ja: "到着予定",
        en: "ETA",
        zh: "预计到达"
    )
    static func stopsRemaining(_ stops: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(stops) 정거장"
        case .japanese: return "\(stops) 駅"
        case .english:  return stops == 1 ? "\(stops) stop" : "\(stops) stops"
        case .chinese:  return "\(stops) 站"
        }
    }
    static let walkingArrived = NavLoc(
        ko: "걸어서 도착",
        ja: "徒歩で到着",
        en: "Walk to arrive",
        zh: "步行到达"
    )

    // No route
    static let noRouteFound = NavLoc(
        ko: "경로를 찾을 수 없어요",
        ja: "経路が見つかりません",
        en: "No route found",
        zh: "找不到路线"
    )
    static let noRouteHint = NavLoc(
        ko: "최대 2회 환승으로 도달할 수 있는 경로가 없어요",
        ja: "最大2回までの乗換で到達できる経路がありません",
        en: "No route reachable within two transfers",
        zh: "两次换乘内无法到达"
    )
    static let pickAnotherDestination = NavLoc(
        ko: "다른 목적지 선택",
        ja: "別の目的地を選ぶ",
        en: "Pick a different destination",
        zh: "选择其他目的地"
    )

    // Last train warning
    static func lastTrainRemaining(_ minutes: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "막차까지 \(minutes)분 남음"
        case .japanese: return "終電まで残り \(minutes) 分"
        case .english:  return "\(minutes) min until last train"
        case .chinese:  return "距末班车还有 \(minutes) 分钟"
        }
    }
    static func lastTrainApproaching(line: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(line)호선 막차가 다가오고 있어요"
        case .japanese: return "\(line)号線の終電が近づいています"
        case .english:  return "Line \(line)'s last train is approaching"
        case .chinese:  return "\(line)号线末班车即将开出"
        }
    }

    // Suffixes / inline pieces
    static func boundFor(_ terminus: String, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(terminus)행"
        case .japanese: return "\(terminus)行"
        case .english:  return "Bound for \(terminus)"
        case .chinese:  return "开往\(terminus)"
        }
    }
    static func tapWhenBoarded(_ terminus: String, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(terminus)행 열차에 타면 탭"
        case .japanese: return "\(terminus)行きに乗ったらタップ"
        case .english:  return "Tap once on the \(terminus) train"
        case .chinese:  return "上前往\(terminus)的列车后点击"
        }
    }
    static func aboutMinutes(_ m: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return m <= 1 ? "약 1분 후" : "약 \(m)분 후"
        case .japanese: return m <= 1 ? "約1分後" : "約\(m)分後"
        case .english:  return m <= 1 ? "in ~1 min" : "in ~\(m) min"
        case .chinese:  return m <= 1 ? "约1分钟后" : "约\(m)分钟后"
        }
    }
    static func lineLabel(_ num: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(num)호선"
        case .japanese: return "\(num)号線"
        case .english:  return "Line \(num)"
        case .chinese:  return "\(num)号线"
        }
    }

    // Language picker
    static let languagePickerTitle = NavLoc(
        ko: "언어",
        ja: "言語",
        en: "Language",
        zh: "语言"
    )
    static let done = NavLoc(
        ko: "완료",
        ja: "完了",
        en: "Done",
        zh: "完成"
    )
    static let autoLabel = NavLoc(
        ko: "자동",
        ja: "自動",
        en: "Auto",
        zh: "自动"
    )

    // Ride block sub-labels
    static let getOffStation = NavLoc(
        ko: "내릴 역",
        ja: "降りる駅",
        en: "Get-off station",
        zh: "下车站"
    )
    static let transferStation = NavLoc(
        ko: "환승역에서 하차",
        ja: "乗換駅で下車",
        en: "Transfer here",
        zh: "在换乘站下车"
    )
    static let trainCurrentLocation = NavLoc(
        ko: "열차 현재 위치",
        ja: "電車の現在位置",
        en: "Train's current location",
        zh: "列车当前位置"
    )
    static let boardingShort = NavLoc(
        ko: "탑승",
        ja: "乗車",
        en: "Board",
        zh: "上车"
    )
    static func stopsBefore(_ stops: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(stops) 정거장 전"
        case .japanese: return "\(stops)前"
        case .english:  return "\(stops) stops away"
        case .chinese:  return "前\(stops)站"
        }
    }

    // Saved-place sections
    static let savedAtThisStation = NavLoc(
        ko: "이 역의 저장된 장소",
        ja: "この駅にあるスポット",
        en: "Saved spots at this station",
        zh: "本站的保存地点"
    )
    static let savedGoTo = NavLoc(
        ko: "저장한 장소로 이동",
        ja: "保存スポットへ行く",
        en: "Go to a saved spot",
        zh: "前往保存的地点"
    )

    // Location errors
    static let locationErrorNoStation = NavLoc(
        ko: "근처에서 역을 찾을 수 없어요",
        ja: "近くに駅が見つかりませんでした",
        en: "No nearby station found",
        zh: "附近找不到车站"
    )
    static let locationErrorFetchFailed = NavLoc(
        ko: "현재 위치를 가져오지 못했어요",
        ja: "現在地の取得に失敗しました",
        en: "Couldn't get your location",
        zh: "无法获取当前位置"
    )

    // TipKit
    static let tipTitle = NavLoc(
        ko: "언어 전환",
        ja: "言語の切り替え",
        en: "Switch language",
        zh: "切换语言"
    )
    static let tipMessage = NavLoc(
        ko: "역 이름을 길게 누르면 표시 언어를 바꿀 수 있어요.",
        ja: "駅名を長押しすると、表示言語を変更できます。",
        en: "Long-press a station name to change the display language.",
        zh: "长按车站名可更改显示语言。"
    )
}
