import SwiftUI

enum DetailTab: String, CaseIterable {
    case resources = "Resources"
    case operations = "Operations"
    case logs = "Logs"
}

struct StackDetailView: View {
    @Environment(AppState.self) private var appState
    let stack: Stack

    @State private var fullStack: Stack?
    @State private var selectedTab: DetailTab = .resources
    @State private var resources: [Resource] = []
    @State private var operations: [Operation] = []
    @State private var logs: [LogEntry] = []
    @State private var loadingStack = true
    @State private var loadingResources = true
    @State private var loadingOperations = true
    @State private var loadingLogs = true
    @State private var error: String?

    private var displayStack: Stack { fullStack ?? stack }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabPicker
            Divider()

            if loadingStack {
                placeholder("Loading stack…")
            } else if let error {
                errorPlaceholder(error)
            } else {
                switch selectedTab {
                case .resources: resourcesTab
                case .operations: operationsTab
                case .logs: logsTab
                }
            }
        }
        .task { await loadStack() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stack: \(displayStack.name)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(displayStack.id)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                    if let count = displayStack.displayResourceCount {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text("\(count) resource\(count == 1 ? "" : "s")")
                            .foregroundStyle(.tertiary)
                    }
                    if let latest = displayStack.recentOperation {
                        StatusIndicator(status: latest.status, size: 6)
                        Text(latest.id)
                            .foregroundStyle(.tertiary)
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(latest.createdAt.dateTime)
                            .foregroundStyle(.tertiary)
                        if let completed = latest.completedAt {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text("\(Int(completed.timeIntervalSince(latest.createdAt)))s")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .font(.caption)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Tabs

    private var resourcesTab: some View {
        Group {
            if loadingResources {
                placeholder("Loading resources…")
            } else if resources.isEmpty {
                placeholder("No resources", icon: "cube.transparent")
            } else {
                List(resources) { resource in
                    Button {
                        appState.navigationPath.append(.resourceDetail(stackID: stack.id, resource))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(resource.name)
                                HStack(spacing: 6) {
                                    Text(resource.id)
                                        .font(.system(.caption, design: .monospaced))
                                    Text("·")
                                    Text(resource.type)
                                }
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
        .task { await loadResources() }
    }

    private var operationsTab: some View {
        Group {
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
                                operationTitle(op)
                                HStack(spacing: 6) {
                                    Text(op.id)
                                        .font(.system(.caption, design: .monospaced))
                                    Text("·")
                                    Text(op.createdAt.dateTime)
                                }
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if let completed = op.completedAt {
                                Text("\(Int(completed.timeIntervalSince(op.createdAt)))s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
        .task { await loadOperations() }
    }

    private var logsTab: some View {
        Group {
            if loadingLogs {
                placeholder("Loading logs…")
            } else if logs.isEmpty {
                placeholder("No logs", icon: "text.alignleft")
            } else {
                List(logs) { log in
                    LogRowView(log: log)
                }
                .listStyle(.plain)
            }
        }
        .task { await loadLogs() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func operationTitle(_ op: Operation) -> some View {
        let user = op.userMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let system = op.systemMessage?
            .split(whereSeparator: \.isNewline)
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        if let user, !user.isEmpty {
            Text(user).lineLimit(1)
        } else if let system, !system.isEmpty {
            Text(system).lineLimit(1)
        } else {
            Text("No message")
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private func errorPlaceholder(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                error = nil
                Task { await loadStack() }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
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

    private func loadStack() async {
        do { fullStack = try await appState.client.getStack(stack.id) }
        catch { self.error = error.localizedDescription }
        loadingStack = false
    }

    private func loadResources() async {
        loadingResources = true
        do { resources = try await appState.client.listResources(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingResources = false
    }

    private func loadOperations() async {
        loadingOperations = true
        do { operations = try await appState.client.listOperations(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingOperations = false
    }

    private func loadLogs() async {
        loadingLogs = true
        do { logs = try await appState.client.listLogs(stackID: stack.id) }
        catch { self.error = error.localizedDescription }
        loadingLogs = false
    }
}
