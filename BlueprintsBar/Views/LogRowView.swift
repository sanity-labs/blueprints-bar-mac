import SwiftUI

struct LogRowView: View {
    let log: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(log.timestamp.dateTimeSeconds)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                if let level = log.level, level.lowercased() != "info" {
                    Text(level.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(levelColor(level))
                }
            }
            Text(log.message)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "error": .red
        case "fatal": .pink
        case "warn", "warning": .orange
        case "debug": .gray
        default: .primary
        }
    }
}
