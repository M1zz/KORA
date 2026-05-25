import UIKit
import Social
import UniformTypeIdentifiers

/// Receives a URL (and optional caption text) from the iOS share sheet —
/// stores it into the App Group inbox so the host app can pick it up next time
/// it becomes active.
class ShareViewController: SLComposeServiceViewController {

    private static let appGroupID = "group.com.kora.leeo"
    private static let urlKey  = "pending_share_url"
    private static let textKey = "pending_share_text"
    private static let dateKey = "pending_share_at"

    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        title = NSLocalizedString("share.title", value: "KORAに保存", comment: "Share sheet title")
        placeholder = NSLocalizedString("share.memo_placeholder", value: "メモ（任意・後で編集可）", comment: "Memo input placeholder")
    }

    override func isContentValid() -> Bool {
        // The URL comes from the share extension's attachments, not from
        // the editable text field, so the "Post" button should always be
        // enabled regardless of whether the user types a memo.
        return true
    }

    override func didSelectPost() {
        Task {
            await self.extractAndStore()
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! { [] }

    // MARK: - Extraction

    private func extractAndStore() async {
        let memo = self.contentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var foundURL: String? = nil
        var captionText: String? = nil

        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let res = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
                    if let u = res as? URL { foundURL = u.absoluteString }
                    else if let s = res as? String { foundURL = s }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                          let res = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil),
                          let s = res as? String {
                    captionText = s
                }
            }
        }

        // Fallback: try to find a URL inside the caption/memo.
        if foundURL == nil {
            foundURL = Self.firstURL(in: captionText) ?? Self.firstURL(in: memo)
        }

        guard let url = foundURL, !url.isEmpty,
              let defaults = UserDefaults(suiteName: Self.appGroupID) else { return }

        let combinedText: String? = {
            var parts: [String] = []
            if !memo.isEmpty { parts.append(memo) }
            if let c = captionText, !c.isEmpty { parts.append(c) }
            return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
        }()

        defaults.set(url, forKey: Self.urlKey)
        defaults.set(combinedText, forKey: Self.textKey)
        defaults.set(Date(), forKey: Self.dateKey)
    }

    private static func firstURL(in text: String?) -> String? {
        guard let text, !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, options: [], range: range)
            .flatMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
}
