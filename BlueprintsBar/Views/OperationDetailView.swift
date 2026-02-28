import SwiftUI

struct OperationDetailView: View {
    @Environment(AppState.self) private var appState
    let stackID: String
    let operation: Operation

    @State private var logs: [LogEntry] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor(operation.status))
                        .frame(width: 8, height: 8)
                    Text(operation.status.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor(operation.status))
                }
                HStack(spacing: 12) {
                    Text("Created: \(operation.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    if let completed = operation.completedAt {
                        Text("Completed: \(completed.formatted(date: .abbreviated, time: .shortened))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)

                Text(operation.id)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
            .padding(12)

            Divider()

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
                List(logs.reversed()) { log in
                    HStack(alignment: .top, spacing: 8) {
                        Text(log.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 70, alignment: .leading)
                        if let level = log.level {
                            Text(level.uppercased())
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(logLevelColor(level))
                                .frame(width: 40, alignment: .leading)
                        }
                        Text(log.message)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                }
                .listStyle(.plain)
            }
        }
        .task { await loadLogs() }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "success", "completed": .green
        case "failed": .red
        case "in progress", "in_progress": .orange
        case "queued": .blue
        default: .gray
        }
    }

    private func logLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "error": .red
        case "warn", "warning": .orange
        case "info": .blue
        case "debug": .gray
        default: .primary
        }
    }

    private func loadLogs() async {
        do { logs = try await appState.client.listLogs(operationID: operation.id) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
