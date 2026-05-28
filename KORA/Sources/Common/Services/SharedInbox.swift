import Foundation

/// Reads pending share-extension payloads from the App Group.
/// The Share Extension writes a URL + optional text into shared
/// UserDefaults; this consumes (read + clear) it for the host app.
enum SharedInbox {
    static let appGroupID = "group.com.kora.leeo"
    private static let urlKey  = "pending_share_url"
    private static let textKey = "pending_share_text"
    private static let dateKey = "pending_share_at"

    struct Payload {
        let url: String
        let text: String?
        let receivedAt: Date
    }

    /// Atomically reads and clears the pending share payload, if any.
    /// Accepts payloads with an empty URL if caption text is present — the
    /// extension may have received only text from Instagram, not a URL.
    static func consume() -> Payload? {
        guard let d = UserDefaults(suiteName: appGroupID) else { return nil }
        let url    = d.string(forKey: urlKey) ?? ""
        let text   = d.string(forKey: textKey)
        let at     = (d.object(forKey: dateKey) as? Date) ?? Date()
        let hasContent = !url.isEmpty || (text != nil && !(text!.isEmpty))
        guard hasContent, d.object(forKey: dateKey) != nil else { return nil }
        d.removeObject(forKey: urlKey)
        d.removeObject(forKey: textKey)
        d.removeObject(forKey: dateKey)
        d.removeObject(forKey: "debug_status")
        return Payload(url: url, text: text, receivedAt: at)
    }
}
