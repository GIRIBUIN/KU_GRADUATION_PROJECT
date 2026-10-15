import AppIntents
import SwiftUI
import WidgetKit

enum KuWidgetTheme: String, AppEnum {
    case light, dark, gray, glass
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "테마"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .light: "밝게", .dark: "어둡게", .gray: "회색", .glass: "반투명"
    ]
    var surface: Color { switch self { case .dark: return Color(red: 0.11, green: 0.15, blue: 0.21)
        case .gray: return Color(red: 0.91, green: 0.92, blue: 0.94)
        case .glass: return Color.white.opacity(0.7)
        default: return .white } }
    var text: Color { self == .dark ? .white : Color(red: 0.09, green: 0.13, blue: 0.20) }
}
struct KuWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "KU Todo 위젯 설정"
    @Parameter(title: "테마", default: .light) var theme: KuWidgetTheme
    @Parameter(title: "완료된 일정 표시", default: false) var showCompleted: Bool
    @Parameter(title: "빠른 추가 제목", default: "새 일정") var quickTitle: String
    @Parameter(title: "삭제 버튼 표시", default: false) var showDelete: Bool
}

struct ToggleKuTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "일정 완료 전환"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    @Parameter(title: "일정 ID") var taskId: String
    init() {}
    init(_ taskId: String) { self.taskId = taskId }
    func perform() async throws -> some IntentResult {
        try KuWidgetStore.changeStatus(id: taskId)
        return .result()
    }
}

struct DeleteKuTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "일정을 삭제 목록으로 이동"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    @Parameter(title: "일정 ID") var taskId: String
    init() {}
    init(_ taskId: String) { self.taskId = taskId }
    func perform() async throws -> some IntentResult {
        try KuWidgetStore.changeStatus(id: taskId, delete: true)
        return .result()
    }
}

struct QuickAddKuTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "정해진 제목으로 일정 빠른 추가"
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    @Parameter(title: "제목") var taskTitle: String
    @Parameter(title: "날짜") var day: String
    init() {}
    init(title: String, day: String) { self.taskTitle = title; self.day = day }
    func perform() async throws -> some IntentResult {
        try KuWidgetStore.quickAdd(title: taskTitle, day: day)
        return .result()
    }
}
