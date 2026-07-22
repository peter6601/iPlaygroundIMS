import SwiftUI

/// 現場全覽：選一個時段，看到那個時間點所有職務各有誰。
struct RosterView: View {
    let state: AppState
    var onPickPerson: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var day = DayInfo.defaultDay()
    @State private var selectedStart: String?

    private var slots: [RosterSlot] { RosterBuilder.slots(day: day, in: state.schedule) }
    private var current: RosterSlot? {
        slots.first { $0.start == selectedStart } ?? slots.first
    }
    private var groups: [RosterGroup] {
        guard let c = current else { return [] }
        return RosterBuilder.roster(day: day, start: c.start, in: state.schedule)
    }

    private let chipCols = [GridItem(.adaptive(minimum: 84), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            header
            dayTabs
            slotStrip
            Divider().overlay(Theme.rule)
            rosterList
        }
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("現場全覽").font(.system(size: 22, weight: .heavy)).foregroundStyle(Theme.accent)
                Text("選時段看各職務有誰").font(.mono(11)).foregroundStyle(Theme.ink3)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundStyle(Theme.ink3)
            }
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)
    }

    private var dayTabs: some View {
        HStack(spacing: 8) {
            ForEach(DayInfo.all, id: \.self) { value in
                let active = value == day
                Button { day = value; selectedStart = nil } label: {
                    Text(DayInfo.label(value))
                        .font(.mono(13, active ? .bold : .regular))
                        .foregroundStyle(active ? Theme.bg : Theme.ink2)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(active ? Theme.accent : Theme.surface, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.bottom, 10)
    }

    private var slotStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slots) { slot in
                    let active = slot.start == (current?.start)
                    Button { selectedStart = slot.start } label: {
                        Text(slot.label)
                            .font(.mono(12, active ? .bold : .regular))
                            .foregroundStyle(active ? Theme.bg : Theme.ink2)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(active ? Theme.accent : Theme.surface,
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var rosterList: some View {
        if let c = current {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !c.title.isEmpty {
                        Text(c.title).font(.system(size: 14)).foregroundStyle(Theme.ink3)
                            .padding(.horizontal, 20).padding(.top, 12)
                    }
                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.category)
                                .font(.mono(12, .heavy)).foregroundStyle(Theme.accent).kerning(1)
                            LazyVGrid(columns: chipCols, alignment: .leading, spacing: 8) {
                                ForEach(group.people, id: \.self) { person in
                                    Button {
                                        onPickPerson(person)
                                        dismiss()
                                    } label: {
                                        Text(person)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Theme.ink)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8).padding(.horizontal, 6)
                                            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    if groups.isEmpty {
                        Text("這個時段沒有排定職務。")
                            .font(.mono(13)).foregroundStyle(Theme.ink3)
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    }
                    Color.clear.frame(height: 24)
                }
            }
        } else {
            Text("這天沒有時段資料。")
                .font(.mono(13)).foregroundStyle(Theme.ink3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
