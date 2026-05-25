import Foundation
import UIKit

@MainActor
final class LinkParserService {

    enum ParseError: LocalizedError {
        case invalidURL
        case unsupportedPlatform
        case noLocationData
        case networkError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return String(localized: "有効なURLを入力してください")
            case .unsupportedPlatform:
                return String(localized: "Instagram、YouTube、XのURLに対応しています")
            case .noLocationData:
                return String(localized: "スポット情報が取得できませんでした")
            case .networkError(let m):
                return "\(String(localized: "ネットワーク接続エラー")): \(m)"
            }
        }
    }

    enum Platform {
        case instagram, youtube, twitter, unknown

        static func detect(from urlString: String) -> Platform {
            if urlString.contains("instagram.com") || urlString.contains("instagr.am") {
                return .instagram
            } else if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
                return .youtube
            } else if urlString.contains("twitter.com") || urlString.contains("x.com") {
                return .twitter
            }
            return .unknown
        }
    }

    // MARK: - Parse

    func parse(urlString: String) async throws -> Place {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard URL(string: trimmed) != nil else {
            throw ParseError.invalidURL
        }
        let platform = Platform.detect(from: trimmed)
        guard platform != .unknown else {
            throw ParseError.unsupportedPlatform
        }
        return try await fetchPlace(from: trimmed, platform: platform)
    }

    // MARK: - HTTP Fetch + OG Parse

    private func fetchPlace(from urlString: String, platform: Platform) async throws -> Place {
        guard let url = URL(string: urlString) else { throw ParseError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("ko,ja;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
                throw ParseError.networkError("サーバーエラー")
            }
            let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""

            return buildPlace(from: html, urlString: urlString, platform: platform)
        } catch let error as ParseError {
            throw error
        } catch {
            throw ParseError.networkError(error.localizedDescription)
        }
    }

    private func buildPlace(from html: String, urlString: String, platform: Platform) -> Place {
        let ogTitle       = ogTag(html, "og:title") ?? ""
        let ogDescription = ogTag(html, "og:description") ?? ""
        let ogImage       = ogTag(html, "og:image")

        let name     = cleanName(ogTitle, platform: platform)
        let category = guessCategory(ogTitle + " " + ogDescription)

        return Place(
            name:       name.isEmpty ? urlString : name,
            nameJP:     name.isEmpty ? urlString : name,
            category:   category,
            address:    "",
            addressJP:  "",
            coordinate: Coordinate(latitude: 0, longitude: 0),
            sourceURL:  urlString,
            imageURL:   ogImage
        )
    }

    // MARK: - OG Tag Extraction

    private func ogTag(_ html: String, _ property: String) -> String? {
        let patterns = [
            "property=\"\(property)\"[^>]*content=\"([^\"]+)\"",
            "content=\"([^\"]+)\"[^>]*property=\"\(property)\""
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            return String(html[range]).htmlDecoded
        }
        return nil
    }

    private func cleanName(_ raw: String, platform: Platform) -> String {
        let suffixes: [String]
        switch platform {
        case .instagram:
            suffixes = [" on Instagram", " • Instagram photos and videos", " • Instagram"]
        case .youtube:
            suffixes = [" - YouTube"]
        case .twitter:
            suffixes = [" on X", " on Twitter"]
        case .unknown:
            suffixes = []
        }
        for suffix in suffixes {
            if let range = raw.range(of: suffix) {
                return String(raw[..<range.lowerBound])
            }
        }
        return raw
    }

    private func guessCategory(_ text: String) -> PlaceCategory {
        let lower = text.lowercased()
        if lower.contains("카페") || lower.contains("cafe") || lower.contains("coffee") || lower.contains("コーヒー") {
            return .cafe
        } else if lower.contains("맛집") || lower.contains("restaurant") || lower.contains("食堂") || lower.contains("ご飯") {
            return .restaurant
        } else if lower.contains("쇼핑") || lower.contains("shop") || lower.contains("ショッピング") {
            return .shopping
        } else if lower.contains("뷰티") || lower.contains("beauty") || lower.contains("makeup") {
            return .beauty
        }
        return .attraction
    }

    // MARK: - Clipboard

    func detectFromClipboard() -> String? {
        guard let string = UIPasteboard.general.string,
              !string.isEmpty,
              URL(string: string) != nil,
              Platform.detect(from: string) != .unknown
        else { return nil }
        return string
    }
}

// MARK: - HTML Entity Decode

private extension String {
    var htmlDecoded: String {
        var result = self
        let entities = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'"]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}
