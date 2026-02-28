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
                HStack(spacing: 6) {
                    Text("Operation: \(operation.id)")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                    StatusIndicator(status: operation.status, size: 6)
                    Text(operation.status.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    if let completed = operation.completedAt {
                        let duration = completed.timeIntervalSince(operation.createdAt)
                        Text("\(Int(duration))s")
                            .fontWeight(.medium)
                    }
                    Text("Created: \(operation.createdAt.dateTime)")
                    if let completed = operation.completedAt {
                        Text("Completed: \(completed.dateTime)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
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
                List(logs) { log in
                    LogRowView(log: log)
                }
                .listStyle(.plain)
            }
        }
        .task { await loadLogs() }
    }

    private func loadLogs() async {
        do { logs = try await appState.client.listLogs(operationID: operation.id) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}
