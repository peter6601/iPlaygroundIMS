import SwiftUI

/// 首頁：選擇自己的名字。黑底黃字、日系科技感。
struct PersonPickerView: View {
    let state: AppState
    @State private var query = ""

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return state.people }
        return state.people.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                searchField
                if filtered.isEmpty {
                    Text("找不到符合「\(query)」的人員")
                        .font(.mono(14))
                        .foregroundStyle(Theme.ink3)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filtered, id: \.self) { person in
                            personCard(person)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("IMS")
                .font(.mono(48, .heavy))
                .foregroundStyle(Theme.accent)
                .kerning(2)
            Text("iPlayground Mission System")
                .font(.mono(12, .medium))
                .foregroundStyle(Theme.ink2)
                .textCase(.uppercase)
                .kerning(1)
            Text("選擇你的名字，查看任務與提醒")
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink3)
                .padding(.top, 2)
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.ink3)
            TextField("", text: $query, prompt: Text("搜尋姓名，例如 Hokila").foregroundColor(Theme.ink3))
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.ink3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.rule, lineWidth: 1))
    }

    private func personCard(_ person: String) -> some View {
        let count = BlockBuilder.blocks(for: person, in: state.schedule.schedule).count
        return Button {
            state.select(person)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(person)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(count) 段任務")
                        .font(.mono(11))
                        .foregroundStyle(Theme.ink3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
