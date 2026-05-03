import SwiftUI

struct StackListView: View {
    @Environment(AppState.self) private var appState
    @State private var stacks: [Stack] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error {
                errorView(error)
            } else if stacks.isEmpty {
                emptyView
            } else {
                stackList
            }
        }
        .task { await loadStacks() }
    }

    private var stackList: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            List(filteredStacks) { stack in
                Button {
                    appState.navigationPath.append(.stackDetail(stack))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stack.name)
                            HStack(spacing: 6) {
                                Text(stack.id)
                                if let count = stack.displayResourceCount {
                                    Text("·")
                                    Text("\(count) resource\(count == 1 ? "" : "s")")
                                }
                                if let opTime = stack.recentOperation?.createdAt {
                                    Text("·")
                                    Text(opTime.dateTime)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        if let op = stack.recentOperation {
                            if let completed = op.completedAt {
                                Text("\(Int(completed.timeIntervalSince(op.createdAt)))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            StatusIndicator(status: op.status, size: 6)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.quaternary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter stacks…", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var filteredStacks: [Stack] {
        let sorted = stacks.sorted { lhs, rhs in
            let lTime = lhs.recentOperation?.createdAt ?? lhs.createdAt
            let rTime = rhs.recentOperation?.createdAt ?? rhs.createdAt
            return lTime > rTime
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.id.localizedCaseInsensitiveContains(searchText)
            || $0.blueprintId.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadStacks() async {
        isLoading = true
        error = nil
        do {
            stacks = try await appState.client.listStacks()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading stacks…")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadStacks() }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "square.stack.3d.up.slash")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No stacks found")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
