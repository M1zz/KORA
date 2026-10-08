import Foundation

/// Per-language UI string for the Subway Navigator screen. Resolves via the
/// user's chosen `StationLanguage` so the entire flow reads cleanly in one
/// language — no mixing.
///
/// The catalog itself (`static let …`) is generated into
/// `SubwayNavigatorCatalog.swift` from `scripts/i18n/navloc.json` by
/// `scripts/i18n/gen_navloc.py`. Every field is required, so a missing
/// translation can't compile.
struct NavLoc {
    let ko: String
    let ja: String
    let en: String
    let zh: String      // 简体
    let zhHant: String  // 繁體 (Taiwan wording)
    let de: String
    let es: String
    let fr: String
    let it: String
    let ptBR: String
    let ru: String
    let cs: String
    let da: String
    let el: String
    let fi: String
    let id: String
    let nb: String
    let nl: String
    let pl: String
    let sv: String
    let th: String
    let tr: String
    let vi: String

    func resolved(_ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return ko
        case .japanese: return ja
        case .english:  return en
        case .chinese:  return zh
        case .chineseTraditional: return zhHant
        case .german:   return de
        case .spanish:  return es
        case .french:   return fr
        case .italian:  return it
        case .portugueseBrazil: return ptBR
        case .russian:  return ru
        case .czech:    return cs
        case .danish:   return da
        case .greek:    return el
        case .finnish:  return fi
        case .indonesian: return id
        case .norwegian: return nb
        case .dutch:    return nl
        case .polish:   return pl
        case .swedish:  return sv
        case .thai:     return th
        case .turkish:  return tr
        case .vietnamese: return vi
        }
    }

    /// Resolves a template and fills `{0}`, `{1}` … with `args`.
    func fill(_ lang: StationLanguage, _ args: String...) -> String {
        var s = resolved(lang)
        for (i, a) in args.enumerated() {
            s = s.replacingOccurrences(of: "{\(i)}", with: a)
        }
        return s
    }
}

// MARK: - Counted / formatted pieces (plural rules differ per language)

extension NavLoc {

    /// CLDR plural category for the languages that need more than one/other.
    private enum Plural { case one, few, many }

    /// Slavic one/few/many (ru, pl) and Czech one/few/other.
    private static func slavic(_ n: Int, czech: Bool = false) -> Plural {
        if czech {
            if n == 1 { return .one }
            if (2...4).contains(n) { return .few }
            return .many
        }
        let m10 = n % 10, m100 = n % 100
        if m10 == 1 && m100 != 11 { return .one }
        if (2...4).contains(m10) && !(12...14).contains(m100) { return .few }
        return .many
    }

    private static func pick(_ n: Int, _ lang: StationLanguage, one: String, few: String, many: String) -> String {
        let polishOne = lang == .polish && n == 1
        let form: Plural
        switch lang {
        case .russian: form = slavic(n)
        case .polish:  form = polishOne ? .one : (slavic(n) == .few ? .few : .many)
        case .czech:   form = slavic(n, czech: true)
        default:       form = n == 1 ? .one : .many
        }
        switch form {
        case .one:  return one
        case .few:  return few
        case .many: return many
        }
    }

    /// "3 stops" — remaining stops / stop count.
    static func stopsRemaining(_ stops: Int, _ lang: StationLanguage) -> String {
        let n = stops
        switch lang {
        case .korean:   return "\(n) 정거장"
        case .japanese: return "\(n) 駅"
        case .english:  return n == 1 ? "\(n) stop" : "\(n) stops"
        case .chinese:  return "\(n) 站"
        case .chineseTraditional: return "\(n) 站"
        case .german:   return n == 1 ? "\(n) Station" : "\(n) Stationen"
        case .spanish:  return n == 1 ? "\(n) parada" : "\(n) paradas"
        case .french:   return n <= 1 ? "\(n) arrêt" : "\(n) arrêts"
        case .italian:  return n == 1 ? "\(n) fermata" : "\(n) fermate"
        case .portugueseBrazil: return n <= 1 ? "\(n) estação" : "\(n) estações"
        case .russian:  return "\(n) " + pick(n, lang, one: "станция", few: "станции", many: "станций")
        case .czech:    return "\(n) " + pick(n, lang, one: "stanice", few: "stanice", many: "stanic")
        case .danish:   return n == 1 ? "\(n) station" : "\(n) stationer"
        case .greek:    return n == 1 ? "\(n) στάση" : "\(n) στάσεις"
        case .finnish:  return n == 1 ? "\(n) asema" : "\(n) asemaa"
        case .indonesian: return "\(n) stasiun"
        case .norwegian: return n == 1 ? "\(n) stasjon" : "\(n) stasjoner"
        case .dutch:    return n == 1 ? "\(n) halte" : "\(n) haltes"
        case .polish:   return "\(n) " + pick(n, lang, one: "stacja", few: "stacje", many: "stacji")
        case .swedish:  return n == 1 ? "\(n) station" : "\(n) stationer"
        case .thai:     return "\(n) สถานี"
        case .turkish:  return "\(n) durak"
        case .vietnamese: return "\(n) ga"
        }
    }

    /// "2 transfers" for the route summary (n ≥ 1; 0 uses `noTransfer`).
    static func transfers(_ n: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(n)회 환승"
        case .japanese: return "\(n)回乗換"
        case .english:  return n == 1 ? "\(n) transfer" : "\(n) transfers"
        case .chinese:  return "换乘\(n)次"
        case .chineseTraditional: return "轉乘\(n)次"
        case .german:   return n == 1 ? "\(n) Umstieg" : "\(n) Umstiege"
        case .spanish:  return n == 1 ? "\(n) transbordo" : "\(n) transbordos"
        case .french:   return n == 1 ? "\(n) correspondance" : "\(n) correspondances"
        case .italian:  return n == 1 ? "\(n) cambio" : "\(n) cambi"
        case .portugueseBrazil: return n == 1 ? "\(n) baldeação" : "\(n) baldeações"
        case .russian:  return "\(n) " + pick(n, lang, one: "пересадка", few: "пересадки", many: "пересадок")
        case .czech:    return "\(n) " + pick(n, lang, one: "přestup", few: "přestupy", many: "přestupů")
        case .danish:   return n == 1 ? "\(n) skift" : "\(n) skift"
        case .greek:    return n == 1 ? "\(n) μετεπιβίβαση" : "\(n) μετεπιβιβάσεις"
        case .finnish:  return n == 1 ? "\(n) vaihto" : "\(n) vaihtoa"
        case .indonesian: return "\(n) kali transit"
        case .norwegian: return n == 1 ? "\(n) bytte" : "\(n) bytter"
        case .dutch:    return n == 1 ? "\(n) overstap" : "\(n) overstappen"
        case .polish:   return "\(n) " + pick(n, lang, one: "przesiadka", few: "przesiadki", many: "przesiadek")
        case .swedish:  return n == 1 ? "\(n) byte" : "\(n) byten"
        case .thai:     return "ต่อรถ \(n) ครั้ง"
        case .turkish:  return "\(n) aktarma"
        case .vietnamese: return "\(n) lần chuyển tuyến"
        }
    }

    // Suffixes / inline pieces
    static func aboutMinutes(_ m: Int, _ lang: StationLanguage) -> String {
        let n = max(m, 1)
        switch lang {
        case .korean:   return "약 \(n)분 후"
        case .japanese: return "約\(n)分後"
        case .english:  return "in ~\(n) min"
        case .chinese:  return "约\(n)分钟后"
        case .chineseTraditional: return "約\(n)分鐘後"
        case .german:   return "in ca. \(n) Min."
        case .spanish:  return "en ~\(n) min"
        case .french:   return "dans ~\(n) min"
        case .italian:  return "tra ~\(n) min"
        case .portugueseBrazil: return "em ~\(n) min"
        case .russian:  return "через ~\(n) мин"
        case .czech:    return "za ~\(n) min"
        case .danish:   return "om ca. \(n) min."
        case .greek:    return n == 1 ? "σε ~1 λεπτό" : "σε ~\(n) λεπτά"
        case .finnish:  return "n. \(n) min päästä"
        case .indonesian: return "~\(n) menit lagi"
        case .norwegian: return "om ca. \(n) min"
        case .dutch:    return "over ~\(n) min"
        case .polish:   return "za ~\(n) min"
        case .swedish:  return "om ca \(n) min"
        case .thai:     return "อีกประมาณ \(n) นาที"
        case .turkish:  return "~\(n) dk sonra"
        case .vietnamese: return "khoảng \(n) phút nữa"
        }
    }

    static func lineLabel(_ num: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "\(num)호선"
        case .japanese: return "\(num)号線"
        case .english:  return "Line \(num)"
        case .chinese:  return "\(num)号线"
        case .chineseTraditional: return "\(num)號線"
        case .german:   return "Linie \(num)"
        case .spanish:  return "Línea \(num)"
        case .french:   return "Ligne \(num)"
        case .italian:  return "Linea \(num)"
        case .portugueseBrazil: return "Linha \(num)"
        case .russian:  return "Линия \(num)"
        case .czech:    return "Linka \(num)"
        case .danish:   return "Linje \(num)"
        case .greek:    return "Γραμμή \(num)"
        case .finnish:  return "Linja \(num)"
        case .indonesian: return "Jalur \(num)"
        case .norwegian: return "Linje \(num)"
        case .dutch:    return "Lijn \(num)"
        case .polish:   return "Linia \(num)"
        case .swedish:  return "Linje \(num)"
        case .thai:     return "สาย \(num)"
        case .turkish:  return "Hat \(num)"
        case .vietnamese: return "Tuyến \(num)"
        }
    }
}
