import SwiftUI

/// A location-search sheet: type a place name, pick a geocoded result to add.
/// Adding is gated by the free/pro location limit.
struct SearchView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var requestPaywall: () -> Void

    @State private var query = ""
    @State private var results: [SavedLocation] = []
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?

    private var theme: AppTheme { model.settings.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Add location").font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search a city…", text: $query)
                    .textFieldStyle(.plain)
                    .onSubmit { runSearch() }
                    .onChange(of: query) { _ in runSearch() }
                if searching { ProgressView().controlSize(.small) }
            }
            .padding(.vertical, 7).padding(.horizontal, 10)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            if !model.canAddLocation {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill").font(.system(size: 10)).foregroundStyle(theme.accent)
                    Text("Free plan tracks 1 location. Upgrade for unlimited.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            if results.isEmpty {
                Text(query.trimmingCharacters(in: .whitespaces).isEmpty
                     ? "Type a city name to search."
                     : (searching ? "Searching…" : "No matches found."))
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(results) { r in
                            Button { tryAdd(r) } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill").foregroundStyle(theme.accent)
                                    Text(r.name).font(.system(size: 13)).lineLimit(1)
                                    Spacer()
                                    Image(systemName: "plus.circle").foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6).padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.primary.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func runSearch() {
        searchTask?.cancel()
        let q = query
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            searching = false
            return
        }
        searching = true
        searchTask = Task {
            let found = await model.weather.search(q)
            if Task.isCancelled { return }
            await MainActor.run {
                results = found
                searching = false
            }
        }
    }

    private func tryAdd(_ location: SavedLocation) {
        if model.canAddLocation {
            model.weather.add(location)
            dismiss()
        } else {
            dismiss()
            requestPaywall()
        }
    }
}
