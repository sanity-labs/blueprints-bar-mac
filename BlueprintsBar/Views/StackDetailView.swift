import SwiftUI

enum DetailTab: String, CaseIterable {
    case resources = "Resources"
    case operations = "Operations"
    case logs = "Logs"
}

struct StackDetailView: View {
    @Environment(AppState.self) private var appState
    let stack: Stack

    @State private var selectedTab: DetailTab = .resources
    @State private var resources: [Resource] = []
    @State private var operations: [Operation] = []
    @State private var logs: [LogEntry] = []
    @State private var loadingResources = true
    @State private var loadingOperations = true
    @State private var loadingLogs = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stack: \(stack.name)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(stack.id)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                            .textSelection(.enabled)
                        if let latest = latestOperation {
                            StatusIndicator(status: latest.status, size: 6)
                            Text(latest.id)
                                .foregroundStyle(.tertiary)
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(latest.createdAt.dateTime)
                                .foregroundStyle(.tertiary)
                        }
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(stack.blueprintId)
                            .foregroundStyle(.quaternary)
                    }
                    .font(.caption)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            switch selectedTab {
            case .resources: resourcesTab
            case .operations: operationsTab
            case .logs: logsTab
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Tabs

    @ViewBuilder
    private var resourcesTab: some View {
        if loadingResources {
            placeholder("Loading resources…")
        } else if resources.isEmpty {
            placeholder("No resources", icon: "cube.transparent")
        } else {
            List(resources) { resource in
                Button {
                    appState.navigationPath.append(.resourceDetail(resource))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resource.name)
                            Text(resource.type)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
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

    @ViewBuilder
    private var operationsTab: some View {
        if loadingOperations {
            placeholder("Loading operations…")
        } else if operations.isEmpty {
            placeholder("No operations", icon: "gearshape")
        } else {
            List(operations) { op in
                Button {
                    appState.navigationPath.append(.operationDetail(stackID: stack.id, op))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(op.id)
                                .font(.system(.body, design: .monospaced))
                            Text(op.createdAt.dateTime)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        StatusIndicator(status: op.status, size: 6)
                        Text(op.status.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
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

    @ViewBuilder
    private var logsTab: some View {
        if loadingLogs {
            placeholder("Loading logs…")
        } else if logs.isEmpty {
            placeholder("No logs", icon: "text.alignleft")
        } else {
            List(logs.reversed()) { log in
                LogRowView(log: log)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var latestOperation: Operation? {
        operations.first
    }

    private func placeholder(_ text: String, icon: String? = nil) -> some View {
        VStack(spacing: 8) {
            Spacer()
            if let icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func loadAll() async {
        async let r: () = loadResources()
        async let o: () = loadOperations()
        async let l: () = loadLogs()
        _ = await (r, o, l)
    }

    private func loadResources() async {
        do { resources = try await appState.client.listResources(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingResources = false
    }

    private func loadOperations() async {
        do { operations = try await appState.client.listOperations(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingOperations = false
    }

    private func loadLogs() async {
        do { logs = try await appState.client.listLogs(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingLogs = false
    }
}
