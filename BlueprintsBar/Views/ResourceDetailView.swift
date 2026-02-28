import SwiftUI

struct ResourceDetailView: View {
    let resource: Resource

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.name)
                        .font(.headline)
                    Text(resource.type)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                sectionHeader("Parameters")
                codeBlock(resource.parameters.prettyPrinted())

                if !resource.providerMetadata.isEmpty {
                    sectionHeader("Provider Metadata")
                    codeBlock(resource.providerMetadata.prettyPrinted())
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    metadataRow("Created", resource.createdAt.dateTime)
                    metadataRow("Updated", resource.updatedAt.dateTime)
                    if let externalId = resource.externalId {
                        metadataRow("External ID", externalId)
                    }
                    metadataRow("Resource ID", resource.id)
                    metadataRow("Operation ID", resource.operationId)
                }
            }
            .padding(12)
        }
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
