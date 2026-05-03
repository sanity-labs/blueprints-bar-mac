import SwiftUI

struct OperationDetailView: View {
    @Environment(AppState.self) private var appState
    let stackID: String
    let operation: Operation

    @State private var fullOperation: Operation?
    @State private var logs: [LogEntry] = []
    @State private var isLoading = true
    @State private var error: String?

    private var displayOperation: Operation { fullOperation ?? operation }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Operation: \(displayOperation.id)")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                    StatusIndicator(status: displayOperation.status, size: 6)
                    Text(displayOperation.status.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    if let bp = displayOperation.blueprintId {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                        Text(bp)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                HStack(spacing: 8) {
                    if let completed = displayOperation.completedAt {
                        let duration = completed.timeIntervalSince(displayOperation.createdAt)
                        Text("\(Int(duration))s")
                            .fontWeight(.medium)
                    }
                    Text("Created: \(displayOperation.createdAt.dateTime)")
                    if let completed = displayOperation.completedAt {
                        Text("Completed: \(completed.dateTime)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(12)

            Divider()

            messagesSection

            Text("Logs")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if isLoading {
                VStack { Spacer(); ProgressView("Loading logs…"); Spacer() }
                    .frame(maxWidth: .infinity)
            } else if logs.isEmpty {
                VStack { Spacer(); Text("No logs available").font(.callout).foregroundStyle(.secondary); Spacer() }
                    .frame(maxWidth: .infinity)
            } else {
                List(logs) { log in
                    LogRowView(log: log)
                }
                .listStyle(.plain)
            }
        }
        .task { await loadOperation() }
        .task { await loadLogs() }
    }

    @ViewBuilder
    private var messagesSection: some View {
        let system = displayOperation.systemMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = displayOperation.userMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSystem = !(system ?? "").isEmpty
        let hasUser = !(user ?? "").isEmpty

        if hasSystem || hasUser {
            VStack(alignment: .leading, spacing: 8) {
                if hasUser, let user {
                    sectionHeader("Message")
                    Text(user)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                if hasSystem, let system {
                    sectionHeader("System Message")
                    Text(system)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Divider()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }

    private func loadOperation() async {
        do { fullOperation = try await appState.client.getOperation(stackID: stackID, operationID: operation.id) }
        catch { /* keep list-derived data on failure */ }
    }

    private func loadLogs() async {
        do { logs = try await appState.client.listLogs(operationID: operation.id) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
