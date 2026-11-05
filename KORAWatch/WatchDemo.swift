//
//  WatchDemo.swift
//  스크린샷용 데모 (DEBUG 전용): `-watchDemo riding` · `-watchDemo alight`
//  2호선 홍대입구 → 시청. 글은 아이폰이 보내는 것과 같은 낱말이다(scripts/i18n/navloc.json 에서 옮겨 옴).
//

#if DEBUG
import Foundation

enum WatchDemo {
    static var ride: RideSnapshot? {
        let index: Int
        switch UserDefaults.standard.string(forKey: "watchDemo") {
        case "riding": index = 2    // 이대 — 세 정거장 남음
        case "alight": index = 4    // 충정로 — 다음 정거장에서 내린다
        default: return nil
        }
        let (line, stations, l) = table[language] ?? table["en"]!
        return RideSnapshot(
            id: "demo", line: line, lineColorHex: "#00A84D", stations: stations,
            index: index, at: .now, secondsPerStop: 120, transfers: false, vibrate: false,
            stopsUnits: [l[5]],   // 데모는 '세 정거장' 만 보인다
            labels: .init(getOffAt: l[0], nextStation: l[1], nextStopGetOff: l[2], getOffNow: l[3],
                          transfer: l[4]))
    }

    /// -AppleLanguages 로 고른 언어 → 표의 칸
    private static var language: String {
        let code = Locale.preferredLanguages.first ?? "en"
        if code.hasPrefix("zh-Hant") || code.hasPrefix("zh-TW") || code.hasPrefix("zh-HK") { return "zh-Hant" }
        if code.hasPrefix("zh") { return "zh-Hans" }
        if code.hasPrefix("pt") { return "pt-BR" }
        if code.hasPrefix("no") { return "nb" }
        return String(code.prefix { $0 != "-" })
    }

    /// 언어 → (노선, 역, [내릴 역 · 다음역 · 다음 정거장에서 내리세요 · 지금 내리세요 · 환승 · '3 정거장' 의 정거장])
    private static let table: [String: (String, [String], [String])] = [
        "ko": ("2호선", ["홍대입구", "신촌", "이대", "아현", "충정로", "시청"], ["내릴 역", "다음역", "다음 정거장에서 내리세요", "지금 내리세요!", "환승", "정거장"]),
        "ja": ("2号線", ["ホンデイック", "シンチョン", "イデ", "アヒョン", "チュンジョンノ", "シチョン"], ["降車駅", "次の駅", "次の駅で降りてください", "今降りてください!", "乗換", "駅"]),
        "en": ("Line 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Get off at", "Next station", "Get off at the next stop", "Get off now!", "Transfer", "stops"]),
        "zh-Hans": ("2号线", ["弘大入口", "新村", "梨大", "阿岘", "忠正路", "市厅"], ["下车站", "下一站", "请在下一站下车", "请立即下车!", "换乘", "站"]),
        "zh-Hant": ("2號線", ["弘大入口", "新村", "梨大", "阿峴", "忠正路", "市廳"], ["下車站", "下一站", "請在下一站下車", "請立即下車!", "轉乘", "站"]),
        "de": ("Linie 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Aussteigen an", "Nächste Station", "An der nächsten Station aussteigen", "Jetzt aussteigen!", "Umstieg", "Stationen"]),
        "es": ("Línea 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Bajar en", "Próxima estación", "Baja en la próxima parada", "¡Baja ahora!", "Transbordo", "paradas"]),
        "fr": ("Ligne 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Descendre à", "Prochaine station", "Descendez au prochain arrêt", "Descendez maintenant !", "Correspondance", "arrêts"]),
        "it": ("Linea 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Scendi a", "Prossima stazione", "Scendi alla prossima fermata", "Scendi ora!", "Cambio", "fermate"]),
        "pt-BR": ("Linha 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Desça em", "Próxima estação", "Desça na próxima estação", "Desça agora!", "Baldeação", "estações"]),
        "ru": ("Линия 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Выход на станции", "Следующая станция", "Выходите на следующей", "Выходите сейчас!", "Пересадка", "станции"]),
        "cs": ("Linka 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Výstup ve stanici", "Příští stanice", "Vystupte na příští stanici", "Vystupte teď!", "Přestup", "stanice"]),
        "da": ("Linje 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Stå af ved", "Næste station", "Stå af ved næste station", "Stå af nu!", "Skift", "stationer"]),
        "el": ("Γραμμή 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Αποβίβαση στο", "Επόμενος σταθμός", "Κατεβείτε στην επόμενη στάση", "Κατεβείτε τώρα!", "Μετεπιβίβαση", "στάσεις"]),
        "fi": ("Linja 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Jää pois asemalla", "Seuraava asema", "Jää pois seuraavalla asemalla", "Jää pois nyt!", "Vaihto", "asemaa"]),
        "id": ("Jalur 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Turun di", "Stasiun berikutnya", "Turun di stasiun berikutnya", "Turun sekarang!", "Transit", "stasiun"]),
        "nb": ("Linje 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Gå av på", "Neste stasjon", "Gå av på neste stasjon", "Gå av nå!", "Bytte", "stasjoner"]),
        "nl": ("Lijn 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Uitstappen bij", "Volgend station", "Stap uit bij de volgende halte", "Nu uitstappen!", "Overstap", "haltes"]),
        "pl": ("Linia 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Stacja docelowa", "Następna stacja", "Wysiądź na następnej stacji", "Wysiądź teraz!", "Przesiadka", "stacje"]),
        "sv": ("Linje 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Kliv av vid", "Nästa station", "Kliv av vid nästa station", "Kliv av nu!", "Byte", "stationer"]),
        "th": ("สาย 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["ลงที่", "สถานีถัดไป", "ลงสถานีถัดไป", "ลงเดี๋ยวนี้!", "ต่อรถ", "สถานี"]),
        "tr": ("Hat 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["İneceğin istasyon", "Sonraki istasyon", "Sonraki istasyonda in", "Şimdi in!", "Aktarma", "durak"]),
        "vi": ("Tuyến 2", ["Hongik Univ.", "Sinchon", "Ewha Womans Univ.", "Ahyeon", "Chungjeongno", "City Hall"], ["Xuống tại", "Ga tiếp theo", "Xuống ở ga tiếp theo", "Xuống ngay!", "Chuyển tuyến", "ga"]),
    ]
}
#endif
