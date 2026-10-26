//
//  KORARoadmap.swift
//  KORA
//
//  **앞으로 만들 것**의 원본. 언어 시트 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.1.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 번역은 이 앱의 방식대로
//       `scripts/i18n/navloc.json` 에 23개 언어를 다 넣고 `python3 scripts/i18n/gen_navloc.py` 로 만든다.
//       (앱 안에서 고른 언어를 따르므로 NSLocalizedString 이 아니라 NavLoc 이다)
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension KORASpec {
    static var roadmap: [LeeoRoadmapItem] {
        let lang = roadmapLanguage
        func item(_ id: String, _ title: NavLoc, _ detail: NavLoc,
                  _ status: LeeoRoadmapItem.Status = .planned) -> LeeoRoadmapItem {
            .init(id: id, status: status, title: title.resolved(lang), detail: detail.resolved(lang))
        }
        return [
            // MARK: 다음에 만들어요
            item("autosave", .roadmapResume, .roadmapResumeDetail),
            item("a11y.voiceover", .roadmapVoiceOver, .roadmapVoiceOverDetail),
            item("a11y.largetext", .roadmapLargeText, .roadmapLargeTextDetail),
            item("a11y.keyboard", .roadmapKeyboard, .roadmapKeyboardDetail),
            item("fold", .roadmapFold, .roadmapFoldDetail),

            // MARK: 내보냈어요
            item("places", .roadmapPlaces, .roadmapPlacesDetail, .shipped("1.0.10")),
            item("express", .roadmapExpress, .roadmapExpressDetail, .shipped("1.0.9")),
            item("onboarding", .roadmapOnboarding, .roadmapOnboardingDetail, .shipped("1.0.9")),
            item("whatsnew", .roadmapWhatsNew, .roadmapWhatsNewDetail, .shipped("1.0.9")),
            item("feedback.inapp", .roadmapFeedback, .roadmapFeedbackDetail, .shipped("1.0.9")),
            item("feedback.reply", .roadmapFeedbackReply, .roadmapFeedbackReplyDetail, .shipped("1.0.9")),
            item("about.version", .roadmapVersion, .roadmapVersionDetail, .shipped("1.0.9")),
            item("a11y.contrast", .roadmapContrast, .roadmapContrastDetail, .shipped("1.0.9")),
            item("a11y.motion", .roadmapMotion, .roadmapMotionDetail, .shipped("1.0.9")),
        ]
    }

    /// 앱 안에서 고른 언어(언어 시트). 비어 있으면 기기 언어를 따른다 — 화면의 나머지와 같은 규칙.
    private static var roadmapLanguage: StationLanguage { .inAppChoice }
}

// MARK: - 화면

/// 언어 시트 ▸ 앞으로 만들 기능. 바라는 기능은 앱 안 피드백 창(기능 제안)으로 바로 보낸다.
struct RoadmapScreen: View {
    @State private var showSuggest = false

    var body: some View {
        LeeoRoadmapView<KORASpec>(onSuggest: { showSuggest = true })
            .sheet(isPresented: $showSuggest) {
                NavigationStack {
                    LeeoFeedbackView<KORASpec>(initialType: .feature)
                }
            }
    }
}
