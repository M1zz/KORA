import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractContent { [weak self] sourceURL, candidates, imageData in
            self?.embedRootView(sourceURL: sourceURL, captionCandidates: candidates, imageData: imageData)
        }
    }

    // MARK: - Embed SwiftUI root

    private func embedRootView(sourceURL: String?, captionCandidates: [String], imageData: Data?) {
        let rootView = ExtensionRootView(
            sourceURL: sourceURL,
            captionCandidates: captionCandidates,
            imageData: imageData,
            onDismiss: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        )
        let hostVC = UIHostingController(rootView: rootView)
        addChild(hostVC)
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostVC.view)
        NSLayoutConstraint.activate([
            hostVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostVC.didMove(toParent: self)
    }

    // MARK: - Content extraction

    private func extractContent(completion: @escaping (String?, [String], Data?) -> Void) {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let group = DispatchGroup()
        var foundURL: String?
        var captionText: String?
        var imageData: Data?

        for item in items {
            if let attrText = item.attributedContentText?.string, !attrText.isEmpty {
                if foundURL == nil { foundURL = Self.firstURL(in: attrText) }
                if captionText == nil { captionText = attrText }
            }
            for provider in item.attachments ?? [] {
                // Image (screenshots shared from Photos)
                if imageData == nil && provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                        defer { group.leave() }
                        if imageData == nil { imageData = data }
                    }
                }

                // URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { result, _ in
                        defer { group.leave() }
                        if let u = result as? URL, foundURL == nil { foundURL = u.absoluteString }
                        else if let s = result as? String, foundURL == nil { foundURL = s }
                    }
                }

                // Plain text
                let textTypes = [UTType.plainText.identifier, "public.text", "com.apple.social.mention"]
                for type in textTypes {
                    if provider.hasItemConformingToTypeIdentifier(type) {
                        group.enter()
                        provider.loadItem(forTypeIdentifier: type, options: nil) { result, _ in
                            defer { group.leave() }
                            let s: String?
                            if let str = result as? String { s = str }
                            else if let data = result as? Data { s = String(data: data, encoding: .utf8) }
                            else { s = nil }
                            if let s, !s.isEmpty {
                                if foundURL == nil { foundURL = Self.firstURL(in: s) }
                                if captionText == nil { captionText = s }
                            }
                        }
                        break
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            // When an image is shared, skip text candidates — OCR will provide them
            let candidates = imageData != nil ? [] : self.placeCandidates(from: captionText)
            completion(foundURL, candidates, imageData)
        }
    }

    private func placeCandidates(from text: String?) -> [String] {
        guard let text, !text.isEmpty else { return [] }
        let lines: [String] = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let filtered: [String] = lines.filter { line in
            guard line.count >= 2, line.count <= 40 else { return false }
            guard !line.hasPrefix("http"), !line.hasPrefix("#"), !line.hasPrefix("@") else { return false }
            return line.rangeOfCharacter(from: .letters) != nil
        }
        return Array(filtered.prefix(5))
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
