import Foundation

/// Per-language UI string for the Subway Navigator screen. Resolves via the
/// user's chosen `StationLanguage` so the entire flow reads cleanly in one
/// language — no Japanese/Korean mixing.
struct NavLoc {
    let ko: String
    let ja: String
    let en: String
    let zh: String      // 简体
    let zhHant: String  // 繁體 (Taiwan wording) — scripts/i18n/zh_hant.py 로 간체에서 뽑은 뒤 다듬는다

    func resolved(_ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return ko
        case .japanese: return ja
        case .english:  return en
        case .chinese:  return zh
        case .chineseTraditional: return zhHant
        }
    }
}

// MARK: - Catalog

extension NavLoc {

    // Destination CTA / no-journey state
    static let whereToGo = NavLoc(
        ko: "어디로 가시나요?",
        ja: "どこに行きますか？",
        en: "Where to?",
        zh: "想去哪里?",
        zhHant: "想去哪裡?"
    )
    static let tapStationForRoute = NavLoc(
        ko: "역을 탭하면 경로가 보여요",
        ja: "駅をタップして経路を表示",
        en: "Tap a station to see the route",
        zh: "点击车站查看路线",
        zhHant: "點選車站查看路線"
    )

    // Station search sheet
    static let currentStationTitle = NavLoc(
        ko: "현재 역",
        ja: "現在地",
        en: "Current station",
        zh: "当前车站",
        zhHant: "目前車站"
    )
    static let destinationTitle = NavLoc(
        ko: "목적지",
        ja: "目的地",
        en: "Destination",
        zh: "目的地",
        zhHant: "目的地"
    )
    static let searchPrompt = NavLoc(
        ko: "역 이름",
        ja: "駅名",
        en: "Station name",
        zh: "车站名",
        zhHant: "車站名"
    )
    static let allLines = NavLoc(
        ko: "전체 노선",
        ja: "全路線",
        en: "All lines",
        zh: "所有线路",
        zhHant: "所有線路"
    )
    static let noMatchingStation = NavLoc(
        ko: "일치하는 역이 없어요",
        ja: "該当する駅が見つかりません",
        en: "No matching station",
        zh: "没有找到匹配的车站",
        zhHant: "沒有找到符合的車站"
    )

    // Ride / boarding flow
    static let verifyTipTitle = NavLoc(
        ko: "다음 정거장 확인",
        ja: "次の駅を確認",
        en: "Verify the next stop",
        zh: "确认下一站",
        zhHant: "確認下一站"
    )
    static let verifyTipMessage = NavLoc(
        ko: "차량 안내판에 이 역명이 나오면 맞는 열차예요. 다른 역이면 내려서 반대편 승강장으로 가세요.",
        ja: "車内の表示にこの駅名が出れば正しい電車です。違う場合は降りて反対側のホームへ。",
        en: "If this station name appears on the in-train display, you're on the right train. If not, get off and take the opposite platform.",
        zh: "如果车内显示这个站名,就是正确的列车。如果不是,请下车前往对面站台。",
        zhHant: "如果車內顯示這個站名,就是正確的列車。如果不是,請下車前往對面月台。"
    )
    static let arrived = NavLoc(
        ko: "도착!",
        ja: "到着!",
        en: "Arrived!",
        zh: "到达!",
        zhHant: "到達!"
    )
    static let arrivingSoon = NavLoc(
        ko: "곧 도착",
        ja: "まもなく到着",
        en: "Arriving soon",
        zh: "即将到达",
        zhHant: "即將到達"
    )
    static let startOver = NavLoc(
        ko: "다른 곳 찾아가기",
        ja: "別の場所へ行く",
        en: "Find another place",
        zh: "去往其他地方",
        zhHant: "前往其他地方"
    )
    static let correctPosition = NavLoc(
        ko: "현재 위치 수정",
        ja: "現在地を修正",
        en: "Correct my position",
        zh: "修正当前位置",
        zhHant: "修正目前位置"
    )
    static let changeDepartureStation = NavLoc(
        ko: "출발역 변경",
        ja: "出発駅を変更",
        en: "Change start",
        zh: "更改出发站",
        zhHant: "更改出發站"
    )
    static let changeLanguageAction = NavLoc(
        ko: "언어 변경",
        ja: "言語を変更",
        en: "Change language",
        zh: "更改语言",
        zhHant: "更改語言"
    )
    static let longPressLanguageHint = NavLoc(
        ko: "길게 누르면 언어를 바꿀 수 있어요",
        ja: "長押しで言語を変更できます",
        en: "Long-press to change the language",
        zh: "长按可更改语言",
        zhHant: "長按可更改語言"
    )
    static let pickCurrentStation = NavLoc(
        ko: "지금 어느 역인가요?",
        ja: "今どの駅にいますか？",
        en: "Which station are you at now?",
        zh: "您现在在哪一站?",
        zhHant: "您現在在哪一站?"
    )
    static let nextStationShort = NavLoc(
        ko: "다음역",
        ja: "次の駅",
        en: "Next station",
        zh: "下一站",
        zhHant: "下一站"
    )
    static let nearbyStations = NavLoc(
        ko: "가까운 역",
        ja: "近くの駅",
        en: "Nearby stations",
        zh: "附近车站",
        zhHant: "附近車站"
    )
    // Alight safety — name-anchored verification
    static let verifyStationNameAlight = NavLoc(
        ko: "역 이름을 확인하고 내리세요",
        ja: "駅名を確認してから降りてください",
        en: "Check the station name before getting off",
        zh: "请确认站名后再下车",
        zhHant: "請確認站名後再下車"
    )
    static let alightPositionUnconfirmed = NavLoc(
        ko: "위치 미확정 — 안내방송·역명으로 확인하세요",
        ja: "現在地は推定です — 放送・駅名で確認を",
        en: "Position estimated — verify by sign/announcement",
        zh: "位置为推算 — 请凭广播·站名确认",
        zhHant: "位置為推算 — 請憑廣播·站名確認"
    )
    static let alightPositionConfirmed = NavLoc(
        ko: "위치 확인됨",
        ja: "現在地確認済み",
        en: "Position confirmed",
        zh: "位置已确认",
        zhHant: "位置已確認"
    )
    // Position sync confidence / realtime signals
    static let positionUncertain = NavLoc(
        ko: "위치가 정확하지 않나요? 탭하여 보정",
        ja: "現在地がずれていますか？タップして修正",
        en: "Position off? Tap to correct",
        zh: "位置不准确？点按修正",
        zhHant: "位置不準確？點選修正"
    )
    static let approachingNext = NavLoc(
        ko: "다음 역 접근 중",
        ja: "まもなく次の駅",
        en: "Approaching next station",
        zh: "即将到达下一站",
        zhHant: "即將到達下一站"
    )
    static let heardFromAnnouncement = NavLoc(
        ko: "안내방송으로 확인됨",
        ja: "車内放送で確認",
        en: "Confirmed by announcement",
        zh: "已通过广播确认",
        zhHant: "已透過廣播確認"
    )
    static let doorOpensRight = NavLoc(
        ko: "내리실 문: 오른쪽",
        ja: "降り口：右側",
        en: "Doors open: right",
        zh: "下车门：右侧",
        zhHant: "下車門：右側"
    )
    static let doorOpensLeft = NavLoc(
        ko: "내리실 문: 왼쪽",
        ja: "降り口：左側",
        en: "Doors open: left",
        zh: "下车门：左侧",
        zhHant: "下車門：左側"
    )
    // Camera direction scanner
    static let scanDirectionButton = NavLoc(
        ko: "어느 쪽인지 카메라로 확인",
        ja: "カメラで方向を確認",
        en: "Check direction with camera",
        zh: "用相机确认方向",
        zhHant: "用相機確認方向"
    )
    static let scanAimPrompt = NavLoc(
        ko: "열차 행선지(전광판)를 비춰주세요",
        ja: "列車の行先表示を映してください",
        en: "Point at the train's destination display",
        zh: "请对准列车终点站显示屏",
        zhHant: "請對準列車終點站顯示幕"
    )
    static let scanCorrect = NavLoc(
        ko: "이 방향이 맞아요 — 타세요",
        ja: "この方向で合っています — 乗車OK",
        en: "Correct direction — board here",
        zh: "方向正确 — 可乘车",
        zhHant: "方向正確 — 可搭車"
    )
    static let scanWrong = NavLoc(
        ko: "반대 방향이에요 — 타지 마세요",
        ja: "逆方向です — 乗らないで",
        en: "Wrong direction — don't board",
        zh: "方向相反 — 请勿乘车",
        zhHant: "方向相反 — 請勿搭車"
    )
    static let scanSearching = NavLoc(
        ko: "행선지를 찾는 중…",
        ja: "行先を探しています…",
        en: "Looking for a destination sign…",
        zh: "正在识别目的地…",
        zhHant: "正在辨識目的地…"
    )
    static let scanNoCamera = NavLoc(
        ko: "카메라 권한이 필요해요",
        ja: "カメラの許可が必要です",
        en: "Camera permission needed",
        zh: "需要相机权限",
        zhHant: "需要相機權限"
    )
    static let gpsSuggestion = NavLoc(
        ko: "위치 기반 추천",
        ja: "位置情報からの候補",
        en: "Location-based guess",
        zh: "根据位置推荐",
        zhHant: "根據位置推薦"
    )
    static let searchingLocation = NavLoc(
        ko: "현재 위치 확인 중...",
        ja: "現在地を取得中...",
        en: "Locating you...",
        zh: "正在定位...",
        zhHant: "正在定位..."
    )
    static let stopsToAlight = NavLoc(
        ko: "내릴 곳까지",
        ja: "降車駅まで",
        en: "Until you get off",
        zh: "到下车站",
        zhHant: "到下車站"
    )
    static let etaLabel = NavLoc(
        ko: "도착 예정",
        ja: "到着予定",
        en: "ETA",
        zh: "预计到达",
        zhHant: "預計到達"
    )
    static let alightCalm = NavLoc(
        ko: "내릴 역",
        ja: "降車駅",
        en: "Get off at",
        zh: "下车站",
        zhHant: "下車站"
    )
    static let prepareToGetOff = NavLoc(
        ko: "곧 내릴 준비하세요",
        ja: "そろそろ降車の準備",
        en: "Prepare to get off",
        zh: "请准备下车",
        zhHant: "請準備下車"
    )
    static let nextStopGetOff = NavLoc(
        ko: "다음 정거장에서 내리세요",
        ja: "次の駅で降りてください",
        en: "Get off at the next stop",
        zh: "请在下一站下车",
        zhHant: "請在下一站下車"
    )
    static let getOffNow = NavLoc(
        ko: "지금 내리세요!",
        ja: "今降りてください!",
        en: "Get off now!",
        zh: "请立即下车!",
        zhHant: "請立即下車!"
    )
    static func stopsRemaining(_ stops: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(stops) 정거장"
        case .japanese: return "\(stops) 駅"
        case .english:  return stops == 1 ? "\(stops) stop" : "\(stops) stops"
        case .chinese:  return "\(stops) 站"
        case .chineseTraditional: return "\(stops) 站"
        }
    }

    // No route
    static let noRouteFound = NavLoc(
        ko: "경로를 찾을 수 없어요",
        ja: "経路が見つかりません",
        en: "No route found",
        zh: "找不到路线",
        zhHant: "找不到路線"
    )
    static let noRouteHint = NavLoc(
        ko: "최대 2회 환승으로 도달할 수 있는 경로가 없어요",
        ja: "最大2回までの乗換で到達できる経路がありません",
        en: "No route reachable within two transfers",
        zh: "两次换乘内无法到达",
        zhHant: "兩次轉乘內無法到達"
    )
    static let pickAnotherDestination = NavLoc(
        ko: "다른 목적지 선택",
        ja: "別の目的地を選ぶ",
        en: "Pick a different destination",
        zh: "选择其他目的地",
        zhHant: "選擇其他目的地"
    )

    // Suffixes / inline pieces
    static func aboutMinutes(_ m: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return m <= 1 ? "약 1분 후" : "약 \(m)분 후"
        case .japanese: return m <= 1 ? "約1分後" : "約\(m)分後"
        case .english:  return m <= 1 ? "in ~1 min" : "in ~\(m) min"
        case .chinese:  return m <= 1 ? "约1分钟后" : "约\(m)分钟后"
        case .chineseTraditional: return m <= 1 ? "約1分鐘後" : "約\(m)分鐘後"
        }
    }
    static func lineLabel(_ num: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(num)호선"
        case .japanese: return "\(num)号線"
        case .english:  return "Line \(num)"
        case .chinese:  return "\(num)号线"
        case .chineseTraditional: return "\(num)號線"
        }
    }

    // Language picker
    static let languagePickerTitle = NavLoc(
        ko: "언어",
        ja: "言語",
        en: "Language",
        zh: "语言",
        zhHant: "語言"
    )
    static let done = NavLoc(
        ko: "완료",
        ja: "完了",
        en: "Done",
        zh: "完成",
        zhHant: "完成"
    )
    static let autoLabel = NavLoc(
        ko: "자동",
        ja: "自動",
        en: "Auto",
        zh: "自动",
        zhHant: "自動"
    )

    // Developer contact
    static let contactSectionTitle = NavLoc(
        ko: "개발자에게 문의",
        ja: "開発者へのお問い合わせ",
        en: "Contact the Developer",
        zh: "联系开发者",
        zhHant: "聯絡開發者"
    )
    static let contactEmail = NavLoc(
        ko: "이메일로 문의하기",
        ja: "メールで問い合わせる",
        en: "Email",
        zh: "通过邮件联系",
        zhHant: "透過電子郵件聯絡"
    )
    static let contactInstagram = NavLoc(
        ko: "인스타그램 DM (@lee25_ios)",
        ja: "インスタグラムDM (@lee25_ios)",
        en: "Instagram DM (@lee25_ios)",
        zh: "Instagram 私信 (@lee25_ios)",
        zhHant: "Instagram 私訊 (@lee25_ios)"
    )
    static let contactFooter = NavLoc(
        ko: "버그 제보와 기능 제안을 환영합니다.",
        ja: "バグ報告や機能のご提案を歓迎します。",
        en: "Bug reports and feature suggestions are welcome.",
        zh: "欢迎反馈问题和提出功能建议。",
        zhHant: "歡迎回報問題並提出功能建議。"
    )

    // Location errors
    static let locationErrorNoStation = NavLoc(
        ko: "근처에서 역을 찾을 수 없어요",
        ja: "近くに駅が見つかりませんでした",
        en: "No nearby station found",
        zh: "附近找不到车站",
        zhHant: "附近找不到車站"
    )
    static let locationErrorFetchFailed = NavLoc(
        ko: "현재 위치를 가져오지 못했어요",
        ja: "現在地の取得に失敗しました",
        en: "Couldn't get your location",
        zh: "无法获取当前位置",
        zhHant: "無法取得目前位置"
    )

    static let locationErrorDenied = NavLoc(
        ko: "위치 권한이 꺼져 있어요 (설정 → 한국 길찾기 → 위치)",
        ja: "位置情報の権限が許可されていません（設定 → 韓国ナビ → 位置情報）",
        en: "Location access is off (Settings → Korea Wayfinder → Location)",
        zh: "未开启定位权限（设置 → 韩国导航 → 位置）",
        zhHant: "未開啟定位權限（設定 → 韓國導航 → 位置）"
    )
    static let locationErrorUnavailable = NavLoc(
        ko: "현재 위치를 가져오지 못했어요. 출발역을 직접 골라주세요",
        ja: "現在地を取得できませんでした。出発駅を手動で選んでください",
        en: "Couldn't get your location. Please pick your starting station",
        zh: "无法获取当前位置，请手动选择出发车站",
        zhHant: "無法取得目前位置，請手動選擇出發車站"
    )
    static let locationErrorTimeout = NavLoc(
        ko: "위치를 가져오는 데 시간이 너무 오래 걸려요",
        ja: "位置情報の取得がタイムアウトしました",
        en: "Getting your location timed out",
        zh: "获取位置超时",
        zhHant: "取得位置逾時"
    )

    /// Unit under the big stop count on the Live Activity.
    static let stopsUnit = NavLoc(
        ko: "정거장",
        ja: "駅",
        en: "stops",
        zh: "站",
        zhHant: "站"
    )

    // TipKit
    static let tipTitle = NavLoc(
        ko: "언어 전환",
        ja: "言語の切り替え",
        en: "Switch language",
        zh: "切换语言",
        zhHant: "切換語言"
    )
    static let tipMessage = NavLoc(
        ko: "역 이름을 길게 누르면 표시 언어를 바꿀 수 있어요.",
        ja: "駅名を長押しすると、表示言語を変更できます。",
        en: "Long-press a station name to change the display language.",
        zh: "长按车站名可更改显示语言。",
        zhHant: "長按車站名可更改顯示語言。"
    )
}
