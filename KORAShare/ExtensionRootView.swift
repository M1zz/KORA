import SwiftUI
import UniformTypeIdentifiers
import Vision

// MARK: - Root View

struct ExtensionRootView: View {
    let sourceURL: String?
    let imageData: Data?
    var onDismiss: () -> Void

    @State private var captionCandidates: [String]
    @State private var nameInput: String
    @State private var locationInput: String = ""
    @State private var savedName: String? = nil
    @State private var showSearch = false
    @State private var fillTarget: FillTarget = .name
    @FocusState private var nameFocused: Bool
    @FocusState private var locationFocused: Bool

    private enum FillTarget { case name, location }

    init(sourceURL: String?, captionCandidates: [String], imageData: Data? = nil, onDismiss: @escaping () -> Void) {
        self.sourceURL = sourceURL
        self.imageData = imageData
        self.onDismiss = onDismiss
        _captionCandidates = State(initialValue: captionCandidates)
        _nameInput = State(initialValue: captionCandidates.first ?? "")
    }

    var body: some View {
        NavigationStack {
            Group {
                if let saved = savedName {
                    savedConfirmation(name: saved)
                } else {
                    mainBody
                }
            }
            .navigationTitle("KORA에 저장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { onDismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            if imageData != nil {
                Task { await runOCR() }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    nameFocused = true
                }
            }
        }
    }

    // MARK: - Main body

    private var mainBody: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Quick-save card
                quickSaveCard

                // OCR chips or caption chips
                if !captionCandidates.isEmpty {
                    candidateChips
                }

                // Expandable Kakao search
                searchToggleButton

                if showSearch {
                    KakaoSearchPanel(sourceURL: sourceURL, onSaved: { name in
                        withAnimation(.spring(response: 0.4)) { savedName = name }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onDismiss() }
                    })
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 32)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .animation(.spring(response: 0.3), value: showSearch)
    }

    // MARK: - Quick save card

    private var quickSaveCard: some View {
        VStack(spacing: 12) {
            // URL preview
            if let url = sourceURL, !url.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Name field
            inputField(
                icon: "mappin",
                placeholder: "장소 이름 (선택)",
                text: $nameInput,
                focus: $nameFocused,
                target: .name
            )

            // Location field
            inputField(
                icon: "location",
                placeholder: "위치 · 주소 (선택)",
                text: $locationInput,
                focus: $locationFocused,
                target: .location
            )

            // Save button
            Button(action: quickSave) {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                    Text("저장")
                        .fontWeight(.semibold)
                }
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        focus: FocusState<Bool>.Binding,
        target: FillTarget
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(fillTarget == target ? Color.accentColor : .secondary)
            TextField(placeholder, text: text)
                .focused(focus)
                .submitLabel(.next)
                .onChange(of: focus.wrappedValue) { _, isFocused in
                    if isFocused { fillTarget = target }
                }
            if !text.wrappedValue.isEmpty {
                Button { text.wrappedValue = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(fillTarget == target ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture { fillTarget = target }
    }

    private func quickSave() {
        let name = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = locationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        AppGroupStore.saveLink(
            name: name.isEmpty ? "Instagram" : name,
            address: location,
            sourceURL: sourceURL
        )
        withAnimation(.spring(response: 0.4)) { savedName = name.isEmpty ? "Instagram" : name }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onDismiss() }
    }

    // MARK: - Candidate list (OCR / caption)

    private var candidateChips: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(imageData != nil ? "인식된 텍스트" : "캡션에서 감지됨")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text("—")
                    .font(.caption).foregroundStyle(.secondary)
                Text(fillTarget == .name ? "장소 이름 칸에 입력 중" : "위치 칸에 입력 중")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(captionCandidates, id: \.self) { c in
                    let isSelected = (fillTarget == .name ? nameInput : locationInput) == c
                    Button {
                        if fillTarget == .name { nameInput = c }
                        else { locationInput = c }
                    } label: {
                        HStack(spacing: 10) {
                            Text(c)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if c != captionCandidates.last {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Search toggle

    private var searchToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { showSearch.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showSearch ? "chevron.up" : "magnifyingglass")
                    .font(.caption).fontWeight(.semibold)
                Text(showSearch ? "검색 닫기" : "장소 검색해서 좌표까지 저장")
                    .font(.subheadline).fontWeight(.medium)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Saved confirmation

    private func savedConfirmation(name: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            Text("저장되었습니다")
                .font(.title2).fontWeight(.bold)
            Text(name)
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - OCR

    private func runOCR() async {
        guard let data = imageData else { return }
        let candidates = await Task.detached(priority: .userInitiated) {
            guard let uiImage = UIImage(data: data), let cgImage = uiImage.cgImage else { return [String]() }
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["ko-KR", "ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            guard (try? handler.perform([request])) != nil,
                  let observations = request.results else { return [String]() }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            return ocrFilterCandidates(lines)
        }.value
        captionCandidates = candidates
        if candidates.isEmpty { nameFocused = true }
    }

}

// No actor isolation — safe to call from Task.detached
private func ocrFilterCandidates(_ lines: [String]) -> [String] {
    var seen = Set<String>()
    var result: [String] = []
    for raw in lines {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        // Drop hashtags, mentions, URLs before cleaning
        guard !trimmed.hasPrefix("#"), !trimmed.hasPrefix("@"), !trimmed.hasPrefix("http") else { continue }
        // Strip everything except Korean/Japanese/CJK, Latin letters, digits, spaces, and - & ( )
        let cleaned = trimmed.unicodeScalars
            .filter { ocrAllowedScalar($0) }
            .reduce(into: "") { $0.append(Character($1)) }
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard cleaned.count >= 2, cleaned.count <= 40 else { continue }
        guard cleaned.rangeOfCharacter(from: .letters) != nil else { continue }
        guard seen.insert(cleaned).inserted else { continue }
        result.append(cleaned)
        if result.count == 20 { break }
    }
    return result
}

private func ocrAllowedScalar(_ s: Unicode.Scalar) -> Bool {
    let v = s.value
    if v >= 0xAC00 && v <= 0xD7A3 { return true } // 한글 음절
    if v >= 0x3130 && v <= 0x318F { return true } // 한글 자모
    if v >= 0x3040 && v <= 0x30FF { return true } // 히라가나·카타카나
    if v >= 0x4E00 && v <= 0x9FFF { return true } // CJK 한자
    if (v >= 65 && v <= 90) || (v >= 97 && v <= 122) { return true } // A-Z a-z
    if v >= 48 && v <= 57 { return true }          // 0-9
    if v == 32 { return true }                      // 공백
    if v == 45 || v == 38 || v == 40 || v == 41 { return true } // - & ( )
    return false
}

// MARK: - Kakao Search Panel (inline, expands on demand)

private struct KakaoSearchPanel: View {
    let sourceURL: String?
    let onSaved: (String) -> Void

    @State private var query = ""
    @State private var results: [KDoc] = []
    @State private var isSearching = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("장소 이름 검색...", text: $query)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
                if isSearching {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button { Task { await search() } } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(query.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    }
                    .disabled(query.isEmpty)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Results
            if !results.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(results) { doc in
                        resultRow(doc)
                        if doc.id != results.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if !isSearching && !query.isEmpty {
                Text("검색 결과가 없습니다")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focused = true }
        }
    }

    @ViewBuilder
    private func resultRow(_ doc: KDoc) -> some View {
        Button {
            AppGroupStore.save(doc, sourceURL: sourceURL)
            onSaved(doc.placeName)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: doc.categoryIcon)
                    .font(.body).foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.placeName).font(.body).fontWeight(.semibold).foregroundStyle(.primary)
                    Text(doc.displayAddress).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isSearching = true; results = []
        defer { isSearching = false }
        results = await KakaoSearch.search(query: q)
    }
}

// MARK: - Kakao Search

struct KDoc: Identifiable {
    let id = UUID()
    let placeName: String
    let addressName: String
    let roadAddressName: String
    let categoryGroupCode: String
    let lat: Double
    let lon: Double

    var displayAddress: String { roadAddressName.isEmpty ? addressName : roadAddressName }

    var categoryIcon: String {
        switch categoryGroupCode {
        case "FD6": return "fork.knife"
        case "CE7": return "cup.and.saucer.fill"
        case "MT1", "CS2": return "bag.fill"
        case "AT4": return "camera.fill"
        case "CT1": return "music.note"
        case "HP8", "PM9": return "cross.fill"
        case "BK9": return "building.columns.fill"
        case "OL7": return "car.fill"
        case "SW8": return "tram.fill"
        case "AG2": return "house.fill"
        default: return "mappin.circle.fill"
        }
    }
}

enum KakaoSearch {
    static func search(query: String) async -> [KDoc] {
        guard var comps = URLComponents(string: "https://dapi.kakao.com/v2/local/search/keyword.json") else { return [] }
        comps.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "size", value: "10")
        ]
        guard let url = comps.url else { return [] }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("KakaoAK f3f1851b0e08e1220c3cd3ed23b7462e", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return [] }
        struct Resp: Decodable {
            struct Doc: Decodable {
                let place_name: String
                let address_name: String
                let road_address_name: String
                let category_group_code: String
                let x: String
                let y: String
            }
            let documents: [Doc]
        }
        guard let r = try? JSONDecoder().decode(Resp.self, from: data) else { return [] }
        return r.documents.map {
            KDoc(placeName: $0.place_name, addressName: $0.address_name,
                 roadAddressName: $0.road_address_name,
                 categoryGroupCode: $0.category_group_code,
                 lat: Double($0.y) ?? 0, lon: Double($0.x) ?? 0)
        }
    }
}

// MARK: - App Group Store

enum AppGroupStore {
    private static let appGroupID = "group.com.kora.leeo"
    private static let queueFile  = "pending_places.json"

    /// Quick-save: URL bookmark with optional name and address, no coordinates.
    static func saveLink(name: String, address: String = "", sourceURL: String?) {
        var dict: [String: Any] = [
            "id":             UUID().uuidString.lowercased(),
            "name":           name,
            "nameJP":         name,
            "category":       "attraction",
            "address":        address,
            "addressJP":      address,
            "coordinate":     ["latitude": 0.0, "longitude": 0.0],
            "priceRange":     "moderate",
            "nearestStation": "",
            "tags":           [String](),
            "isOpen":         true,
            "savedAt":        Date().timeIntervalSinceReferenceDate
        ]
        if let url = sourceURL, !url.isEmpty { dict["sourceURL"] = url }
        appendToQueue(dict)
    }

    /// Full save from Kakao search result, with coordinates.
    static func save(_ doc: KDoc, sourceURL: String?) {
        let category = mapCategory(doc.categoryGroupCode)
        var dict: [String: Any] = [
            "id":             UUID().uuidString.lowercased(),
            "name":           doc.placeName,
            "nameJP":         doc.placeName,
            "category":       category,
            "address":        doc.displayAddress,
            "addressJP":      doc.displayAddress,
            "coordinate":     ["latitude": doc.lat, "longitude": doc.lon],
            "priceRange":     "moderate",
            "nearestStation": "",
            "tags":           [String](),
            "isOpen":         true,
            "savedAt":        Date().timeIntervalSinceReferenceDate
        ]
        if let url = sourceURL, !url.isEmpty { dict["sourceURL"] = url }
        appendToQueue(dict)
    }

    private static func appendToQueue(_ dict: [String: Any]) {
        guard let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return }
        let fileURL = dir.appendingPathComponent(queueFile)
        var queue: [[String: Any]] = []
        if let existing = try? Data(contentsOf: fileURL),
           let arr = try? JSONSerialization.jsonObject(with: existing) as? [[String: Any]] {
            queue = arr
        }
        queue.insert(dict, at: 0)
        if let data = try? JSONSerialization.data(withJSONObject: queue) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private static func mapCategory(_ code: String) -> String {
        switch code {
        case "FD6":        return "restaurant"
        case "CE7":        return "cafe"
        case "MT1", "CS2": return "shopping"
        case "AT4":        return "attraction"
        case "CT1":        return "entertainment"
        default:           return "attraction"
        }
    }
}
