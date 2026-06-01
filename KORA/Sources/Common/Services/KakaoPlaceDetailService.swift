import Foundation

// MARK: - Model

struct KakaoPlaceDetail {
    var mainPhotoURL: String?
    var phone: String?
    var hours: [HourEntry]
    var photos: [String]       // smallurl list

    struct HourEntry {
        let days: String
        let time: String
    }

    var isEmpty: Bool { mainPhotoURL == nil && phone == nil && hours.isEmpty && photos.isEmpty }
}

// MARK: - Service
// Uses Kakao Maps internal endpoint (place.map.kakao.com/main/v/{id}).
// Not officially documented but publicly accessible — same data the Kakao Maps web app uses.

final class KakaoPlaceDetailService {

    enum DetailError: Error { case invalidID, httpError(Int), parseFailure }

    // MARK: - Public

    func fetch(kakaoMapURL: String) async throws -> KakaoPlaceDetail {
        guard let id = Self.placeID(from: kakaoMapURL) else { throw DetailError.invalidID }
        return try await fetch(placeID: id)
    }

    func fetch(placeID: String) async throws -> KakaoPlaceDetail {
        guard let url = URL(string: "https://place.map.kakao.com/main/v/\(placeID)") else {
            throw DetailError.invalidID
        }
        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("https://map.kakao.com/", forHTTPHeaderField: "Referer")
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DetailError.httpError(http.statusCode)
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DetailError.parseFailure
        }
        return parse(json)
    }

    // MARK: - Parse

    private func parse(_ json: [String: Any]) -> KakaoPlaceDetail {
        let basic = json["basicInfo"] as? [String: Any] ?? [:]

        let mainPhoto = basic["mainphotourl"] as? String
        let rawPhone = (basic["phonenum"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phone: String? = rawPhone.isEmpty ? nil : rawPhone

        // Hours
        var hours: [KakaoPlaceDetail.HourEntry] = []
        if let openHour = basic["openHour"] as? [String: Any],
           let periodList = openHour["periodList"] as? [[String: Any]] {
            for period in periodList {
                guard let timeList = period["timeList"] as? [[String: Any]] else { continue }
                for slot in timeList {
                    let days = (slot["dayOfWeek"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let time = (slot["timeSE"]    as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !time.isEmpty else { continue }
                    hours.append(.init(days: days, time: time))
                }
            }
        }

        // Photos — prefer the largest available size that's still safe to
        // download in a card-sized hero. Order: largeurl → orgurl → smallurl.
        // Card carousels at 170×160pt need ~340×320 minimum, and `smallurl`
        // tops out around 150px which renders fuzzy.
        func bestURL(_ item: [String: Any]) -> String? {
            for key in ["largeurl", "orgurl", "smallurl"] {
                if let url = item[key] as? String,
                   !url.trimmingCharacters(in: .whitespaces).isEmpty {
                    return url
                }
            }
            return nil
        }

        var photoURLs: [String] = []
        if let main = mainPhoto { photoURLs.append(main) }
        if let photoSection = json["photo"] as? [String: Any],
           let photoList = photoSection["photoList"] as? [[String: Any]] {
            for item in photoList {
                if let url = bestURL(item), !photoURLs.contains(url) {
                    photoURLs.append(url)
                }
                if photoURLs.count >= 8 { break }
            }
        }

        return KakaoPlaceDetail(
            mainPhotoURL: mainPhoto,
            phone: phone,
            hours: hours,
            photos: photoURLs
        )
    }

    // MARK: - Helpers

    static func placeID(from kakaoMapURL: String) -> String? {
        guard let id = URL(string: kakaoMapURL)?.lastPathComponent, !id.isEmpty else { return nil }
        return id
    }
}
