import AppIntents
import SwiftUI
import WidgetKit

enum KuWidgetScope: String { case today, week, calendar
    var title: String { switch self { case .today: return "오늘 할 일정"; case .week: return "이번 주 일정"; case .calendar: return "캘린더" } }
}

struct KuTimelineEntry: TimelineEntry {
    let date: Date
    let configuration: KuWidgetConfiguration
    let scope: KuWidgetScope
    let tasks: [KuWidgetTask]
    let failure: String?
}

struct KuTimelineProvider: AppIntentTimelineProvider {
    let scope: KuWidgetScope
    func placeholder(in context: Context) -> KuTimelineEntry {
        KuTimelineEntry(date: Date(), configuration: KuWidgetConfiguration(), scope: scope,
            tasks: [KuWidgetTask(id: "preview", title: "프로젝트 미팅", due: Date(), status: "active", origin: "personal")], failure: nil)
    }
    func snapshot(for configuration: KuWidgetConfiguration, in context: Context) async -> KuTimelineEntry { entry(configuration) }
    func timeline(for configuration: KuWidgetConfiguration, in context: Context) async -> Timeline<KuTimelineEntry> {
        Timeline(entries: [entry(configuration)], policy: .after(Date().addingTimeInterval(900)))
    }
    private func entry(_ configuration: KuWidgetConfiguration) -> KuTimelineEntry {
        do {
            let calendar = Calendar.current
            let now = Date()
            let day = calendar.startOfDay(for: now)
            var weekCalendar = calendar
            weekCalendar.firstWeekday = 2 // Match the app's Monday–Sunday selection.
            let week = weekCalendar.dateInterval(of: .weekOfYear, for: day)!
            let tasks = try KuWidgetStore.tasks().filter { task in
                if task.completed && !configuration.showCompleted { return false }
                if scope == .calendar { return true }
                guard let due = task.due else { return false }
                return scope == .today ? calendar.isDate(due, inSameDayAs: now) : (due >= week.start && due < week.end)
            }
            return KuTimelineEntry(date: now, configuration: configuration, scope: scope, tasks: tasks, failure: nil)
        } catch { return KuTimelineEntry(date: Date(), configuration: configuration, scope: scope, tasks: [], failure: error.localizedDescription) }
    }
}

private func dayString(_ date: Date) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
}

private func editURL(scope: KuWidgetScope, task: String? = nil, day: Date? = nil) -> URL {
    var components = URLComponents()
    components.scheme = "kutodo"; components.host = task == nil ? "calendar" : "edit"
    components.queryItems = [URLQueryItem(name: "kind", value: scope.rawValue)]
    if let task = task { components.queryItems!.append(URLQueryItem(name: "id", value: task)) }
    if let day = day { components.queryItems!.append(URLQueryItem(name: "date", value: dayString(day))) }
    return components.url!
}

struct KuWidgetView: View {
    let entry: KuTimelineEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.scope == .calendar ? entry.date.formatted(.dateTime.year().month(.wide)) : entry.scope.title).font(.headline)
                Spacer(minLength: 4)
                Button(intent: QuickAddKuTaskIntent(title: entry.configuration.quickTitle, day: dayString(entry.date))) {
                    Image(systemName: "plus").font(.body)
                }.buttonStyle(.plain).accessibilityLabel("\(entry.configuration.quickTitle) 빠른 추가")
            }
            if let failure = entry.failure {
                Text(failure).font(.caption).widgetURL(URL(string: "kutodo://calendar?kind=\(entry.scope.rawValue)"))
            } else if entry.scope == .calendar {
                calendar
            } else {
                if entry.tasks.isEmpty { Text("등록된 일정이 없습니다.").font(.caption).foregroundStyle(.secondary) }
                ForEach(Array(entry.tasks.prefix(family == .systemSmall ? 3 : family == .systemMedium ? 4 : 8))) { task in
                    HStack(spacing: 7) {
                        Button(intent: ToggleKuTaskIntent(task.id)) { Image(systemName: task.completed ? "checkmark.circle.fill" : "circle") }
                            .buttonStyle(.plain).accessibilityLabel("\(task.title) 완료 상태 전환")
                        Link(destination: editURL(scope: entry.scope, task: task.id)) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title).lineLimit(1).font(.subheadline)
                                if let due = task.due { Text(due, style: .time).font(.caption2).foregroundStyle(.secondary) }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if entry.configuration.showDelete {
                            Button(intent: DeleteKuTaskIntent(task.id)) { Image(systemName: "trash").font(.caption) }
                                .buttonStyle(.plain).accessibilityLabel("\(task.title) 삭제 목록으로 이동")
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(entry.configuration.theme.text)
        .containerBackground(for: .widget) { entry.configuration.theme.surface }
        .widgetURL(editURL(scope: entry.scope, day: entry.date))
    }

    private var calendar: some View {
        GeometryReader { geometry in
            let calendar = Calendar.current
            let first = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date))!
            let leading = (calendar.component(.weekday, from: first) + 6) % 7
            let start = calendar.date(byAdding: .day, value: -leading, to: first)!
            let total = (leading + calendar.range(of: .day, in: .month, for: first)!.count + 6) / 7
            let weeks = family == .systemSmall ? 1 : family == .systemMedium ? min(2, total) : total
            let current = calendar.dateComponents([.day], from: start, to: entry.date).day! / 7
            let offset = min(max(current - (weeks - 1) / 2, 0), total - weeks)
            VStack(spacing: 2) {
                HStack(spacing: 0) { ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { Text($0).font(.system(size: 10)).frame(maxWidth: .infinity) } }
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<7, id: \.self) { weekday in
                            let date = calendar.date(byAdding: .day, value: (offset + week) * 7 + weekday, to: start)!
                            let tasks = entry.tasks.filter { $0.due.map { calendar.isDate($0, inSameDayAs: date) } ?? false }
                            let today = calendar.isDateInToday(date)
                            Link(destination: editURL(scope: .calendar, day: date)) {
                                VStack(spacing: 1) {
                                    Text("\(calendar.component(.day, from: date))").font(.system(size: 12))
                                        .frame(width: 24, height: 24).background(today ? Color.blue : Color.clear, in: Circle())
                                        .foregroundStyle(today ? .white : weekday == 0 ? .red : entry.configuration.theme.text)
                                    if let task = tasks.first {
                                        if geometry.size.width >= 280 && geometry.size.height / CGFloat(weeks) >= 44 {
                                            Text(task.title).font(.system(size: 8)).lineLimit(1)
                                            if tasks.count > 1 { Text("+\(tasks.count - 1)").font(.system(size: 7)) }
                                        } else { Circle().fill(Color.blue).frame(width: 3, height: 3) }
                                    }
                                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            }
                        }
                    }.frame(maxHeight: .infinity)
                }
            }
        }
    }
}

struct KuTodayWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "KuTodayWidget", intent: KuWidgetConfiguration.self, provider: KuTimelineProvider(scope: .today)) { KuWidgetView(entry: $0) }
            .configurationDisplayName("오늘 할 일정").description("오늘 일정 확인·완료·빠른 추가")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
struct KuWeekWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "KuWeekWidget", intent: KuWidgetConfiguration.self, provider: KuTimelineProvider(scope: .week)) { KuWidgetView(entry: $0) }
            .configurationDisplayName("이번 주 일정").description("이번 주 일정 확인·완료·빠른 추가")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
struct KuCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "KuCalendarWidget", intent: KuWidgetConfiguration.self, provider: KuTimelineProvider(scope: .calendar)) { KuWidgetView(entry: $0) }
            .configurationDisplayName("캘린더").description("한 주부터 월간 달력까지")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
@main struct KuTodoWidgetBundle: WidgetBundle {
    var body: some Widget { KuTodayWidget(); KuWeekWidget(); KuCalendarWidget() }
}
