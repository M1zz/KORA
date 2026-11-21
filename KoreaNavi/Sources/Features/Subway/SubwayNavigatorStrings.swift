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
    let ar: String

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
        case .arabic:   return ar
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

    /// 아랍어 수 세기: 1 · 2 는 수 없이 낱말로(محطة واحدة · محطتان), 3~10 은 복수(محطات),
    /// 11 부터는 단수 목적격(محطة). 끝 두 자리로 고른다(103 → 3~10 꼴).
    private static func arabic(_ n: Int, one: String, two: String, few: String, many: String) -> String {
        let m100 = n % 100
        switch n {
        case 1: return one
        case 2: return two
        default:
            if (3...10).contains(m100) { return "\(n) \(few)" }
            return "\(n) \(many)"
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
        case .arabic:   return arabic(n, one: "محطة واحدة", two: "محطتان", few: "محطات", many: "محطة")
        }
    }

    /// 큰 숫자 아래에 붙는 '정거장' 낱말 (워치). 숫자를 따로 크게 쓰므로 수 없이 낱말만.
    static func stopsUnitWord(_ n: Int, _ lang: StationLanguage) -> String {
        guard lang == .arabic else { return String(stopsRemaining(n, lang).dropFirst("\(n) ".count)) }
        if n == 2 { return "محطتان" }
        return (3...10).contains(n % 100) ? "محطات" : "محطة"
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
        case .arabic:   return arabic(n, one: "تبديل واحد", two: "تبديلان", few: "تبديلات", many: "تبديلًا")
        }
    }

    /// 팁 부탁 카드의 숫자 한 줄 — KoreaNavi 와 함께 목적지에 닿은 여정 수.
    static func tipArrivals(_ n: Int, _ lang: StationLanguage) -> String {
        switch lang {
        case .korean:   return "한국길찾기와 함께 목적지에 \(n)번 도착했어요"
        case .japanese: return "韓国ナビで目的地に\(n)回たどり着きました"
        case .english:  return "You've reached your destination \(n) times with Korea Navi"
        case .chinese:  return "你已用韩国导航顺利到达目的地 \(n) 次"
        case .chineseTraditional: return "你已用韓國導航順利抵達目的地 \(n) 次"
        case .german:   return "Mit Korea Navi schon \(n)-mal gut ans Ziel gekommen"
        case .spanish:  return "Ya llegaste a tu destino \(n) veces con Korea Navi"
        case .french:   return "Déjà \(n) trajets menés à bon port avec Korea Navi"
        case .italian:  return "Con Korea Navi sei già arrivato a destinazione \(n) volte"
        case .portugueseBrazil: return "Você já chegou ao destino \(n) vezes com o Korea Navi"
        case .russian:  return "С Korea Navi вы доехали до цели уже \(n) " + pick(n, lang, one: "раз", few: "раза", many: "раз")
        case .czech:    return "S Korea Navi jste dojeli do cíle už \(n)×"
        case .danish:   return "Du er kommet frem \(n) gange med Korea Navi"
        case .greek:    return "Φτάσατε στον προορισμό σας \(n) φορές με το Korea Navi"
        case .finnish:  return "Olet päässyt Korea Navin kanssa perille jo \(n) kertaa"
        case .indonesian: return "Kamu sudah \(n) kali sampai tujuan bersama Korea Navi"
        case .norwegian: return "Du har kommet frem \(n) ganger med Korea Navi"
        case .dutch:    return "Je bent al \(n) keer op je bestemming gekomen met Korea Navi"
        case .polish:   return "Z Korea Navi już \(n) " + pick(n, lang, one: "raz", few: "razy", many: "razy") + " bez problemu do celu"
        case .swedish:  return "Du har kommit fram \(n) gånger med Korea Navi"
        case .thai:     return "คุณเดินทางถึงที่หมายกับ Korea Navi มาแล้ว \(n) ครั้ง"
        case .turkish:  return "Korea Navi ile \(n) kez hedefine ulaştın"
        case .vietnamese: return "Bạn đã đến nơi \(n) lần cùng Korea Navi"
        case .arabic:   return "وصلت إلى وجهتك " + arabic(n, one: "مرة واحدة", two: "مرتين", few: "مرات", many: "مرة") + " مع Korea Navi"
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
        case .arabic:   return "بعد " + arabic(n, one: "دقيقة", two: "دقيقتين", few: "دقائق", many: "دقيقة") + " تقريبًا"
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
        case .arabic:   return "الخط \(num)"
        }
    }
}

// MARK: - Locale for formatting

extension StationLanguage {
    /// 오른쪽에서 왼쪽으로 쓰는 언어 — 앱 루트에서 화면 방향을 이것으로 바꾼다.
    var isRightToLeft: Bool { self == .arabic }

    /// 날짜·시각·숫자를 이 언어의 표기로 쓸 때의 로케일 (앱 안에서 고른 언어를 따른다).
    var locale: Locale {
        let id: String
        switch self {
        case .korean: id = "ko_KR"
        case .japanese: id = "ja_JP"
        case .english: id = "en_US"
        case .chinese: id = "zh_Hans_CN"
        case .chineseTraditional: id = "zh_Hant_TW"
        case .german: id = "de_DE"
        case .spanish: id = "es_ES"
        case .french: id = "fr_FR"
        case .italian: id = "it_IT"
        case .portugueseBrazil: id = "pt_BR"
        case .russian: id = "ru_RU"
        case .czech: id = "cs_CZ"
        case .danish: id = "da_DK"
        case .greek: id = "el_GR"
        case .finnish: id = "fi_FI"
        case .indonesian: id = "id_ID"
        case .norwegian: id = "nb_NO"
        case .dutch: id = "nl_NL"
        case .polish: id = "pl_PL"
        case .swedish: id = "sv_SE"
        case .thai: id = "th_TH"
        case .turkish: id = "tr_TR"
        case .vietnamese: id = "vi_VN"
        // 숫자는 0~9, 달력은 양력으로 맞춘다 (사우디 기기에선 ١٢٣ 와 123 이 섞이고 날짜가 히즈리력으로 나온다).
        case .arabic: id = "ar_SA@numbers=latn;calendar=gregorian"
        }
        return Locale(identifier: id)
    }
}
