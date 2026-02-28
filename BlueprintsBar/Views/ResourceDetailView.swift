import SwiftUI

struct ResourceDetailView: View {
    @Environment(AppState.self) private var appState
    let stackID: String
    let resource: Resource

    @State private var fullResource: Resource?
    @State private var isLoading = true
    @State private var error: String?

    private var displayResource: Resource { fullResource ?? resource }

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
            }
            .padding(12)
        }
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
