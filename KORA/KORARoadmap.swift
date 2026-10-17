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
        func item(_ id: String, _ title: NavLoc, _ detail: NavLoc) -> LeeoRoadmapItem {
            .init(id: id, status: .planned, title: title.resolved(lang), detail: detail.resolved(lang))
        }
        return [
            // MARK: 다음에 만들어요
            item("autosave", .roadmapResume, .roadmapResumeDetail),
            item("onboarding", .roadmapOnboarding, .roadmapOnboardingDetail),
            item("whatsnew", .roadmapWhatsNew, .roadmapWhatsNewDetail),
            item("feedback.inapp", .roadmapFeedback, .roadmapFeedbackDetail),
            item("feedback.reply", .roadmapFeedbackReply, .roadmapFeedbackReplyDetail),
            item("about.version", .roadmapVersion, .roadmapVersionDetail),
            item("a11y.voiceover", .roadmapVoiceOver, .roadmapVoiceOverDetail),
            item("a11y.largetext", .roadmapLargeText, .roadmapLargeTextDetail),
            item("a11y.contrast", .roadmapContrast, .roadmapContrastDetail),
            item("a11y.motion", .roadmapMotion, .roadmapMotionDetail),
            item("a11y.keyboard", .roadmapKeyboard, .roadmapKeyboardDetail),
            item("fold", .roadmapFold, .roadmapFoldDetail),
        ]
    }

    /// 앱 안에서 고른 언어(언어 시트). 비어 있으면 기기 언어를 따른다 — 화면의 나머지와 같은 규칙.
    private static var roadmapLanguage: StationLanguage {
        let pref = UserDefaults.standard.string(forKey: "kora.display_language") ?? ""
        return StationLanguage(rawValue: pref) ?? StationLanguage.resolveFromSystemLocale()
    }
}

// MARK: - 화면

/// 언어 시트 ▸ 앞으로 만들 기능. 앱 안 피드백 창이 아직 없어 제안 단추는 두지 않는다.
struct RoadmapScreen: View {
    var body: some View {
        LeeoRoadmapView<KORASpec>()
    }
}
