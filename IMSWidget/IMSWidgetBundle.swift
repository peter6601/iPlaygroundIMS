import WidgetKit
import SwiftUI

@main
struct IMSWidgetBundle: WidgetBundle {
    var body: some Widget {
        MissionWidget()
    }
}

struct MissionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MissionWidget", provider: PlaceholderProvider()) { _ in
            Text("IMS")
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("任務")
        .description("顯示當下與下一個任務")
        .supportedFamilies([.systemSmall])
    }
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date())], policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
