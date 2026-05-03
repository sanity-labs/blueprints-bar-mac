import SwiftUI

struct ResourceDetailView: View {
    @Environment(AppState.self) private var appState
    let stackID: String
    let resource: Resource

    @State private var fullResource: Resource?
    @State private var isLoading = true
    @State private var error: String?
    @State private var functionLogs: [FunctionLog] = []
    @State private var loadingLogs = true
    @State private var logsError: String?

    private var displayResource: Resource { fullResource ?? resource }
    private var isFunction: Bool {
        displayResource.type.hasPrefix("sanity.function.") && displayResource.externalId != nil
    }

    var body: some View {
        if isLoading {
            VStack { Spacer(); ProgressView("Loading resource…"); Spacer() }
                .frame(maxWidth: .infinity)
                .task { await loadResource() }
        } else {
            resourceContent
        }
    }

    private var resourceContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayResource.name)
                        .font(.headline)
                    Text(displayResource.type)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                sectionHeader("Parameters")
                codeBlock(displayResource.parameters.prettyPrinted())

                if let resolved = displayResource.resolvedParameters, !resolved.isEmpty {
                    DisclosureGroup {
                        codeBlock(resolved.prettyPrinted())
                            .padding(.top, 4)
                    } label: {
                        sectionHeader("Resolved Parameters")
                    }
                }

                if !displayResource.providerMetadata.isEmpty {
                    sectionHeader("Provider Metadata")
                    codeBlock(displayResource.providerMetadata.prettyPrinted())
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    metadataRow("Created", displayResource.createdAt.dateTime)
                    metadataRow("Updated", displayResource.updatedAt.dateTime)
                    if let externalId = displayResource.externalId {
                        metadataRow("External ID", externalId)
                    }
                    metadataRow("Resource ID", displayResource.id)
                    metadataRow("Operation ID", displayResource.operationId)
                }

                if isFunction {
                    Divider()
                    HStack {
                        sectionHeader("Recent Logs")
                        Spacer()
                        if !functionLogs.isEmpty {
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(formattedLogs, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("Copy logs")
                        }
                        Button {
                            Task { await loadFunctionLogs() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Reload logs")
                        .disabled(loadingLogs)
                    }
                    functionLogsSection
                }
            }
            .padding(12)
        }
    }

    private var functionLogsSection: some View {
        Group {
            if loadingLogs {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 40)
            } else if let logsError {
                Text(logsError)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if functionLogs.isEmpty {
                Text("No recent logs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(formattedLogs)
                        .font(.system(.caption, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: false)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.fill.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .task(id: displayResource.externalId) { await loadFunctionLogs() }
    }

    private var formattedLogs: String {
        functionLogs.map { log in
            "\(log.time.dateTimeSeconds) \(log.level.uppercased()) \(log.message)"
        }.joined(separator: "\n")
    }

    private func loadFunctionLogs() async {
        guard let externalId = displayResource.externalId else { return }
        loadingLogs = true
        logsError = nil
        do { functionLogs = try await appState.functionsClient.listLogs(functionID: externalId) }
        catch { logsError = error.localizedDescription }
        loadingLogs = false
    }

    private func loadResource() async {
        do { fullResource = try await appState.client.getResource(stackID: stackID, resourceID: resource.id) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }

    private func codeBlock(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.fill.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .textSelection(.enabled)
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}
