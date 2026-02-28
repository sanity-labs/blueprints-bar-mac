import SwiftUI

struct ScopePickerView: View {
    @Environment(AppState.self) private var appState
    @State private var organizations: [Organization] = []
    @State private var projects: [Project] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error {
                errorView(error)
            } else {
                scopeList
            }
        }
        .task(id: appState.environment) { await loadScopes() }
    }

    private var scopeList: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            List {
                ForEach(filteredOrganizations, id: \.id) { org in
                    Section {
                        Button {
                            appState.selectScope(.organization(org))
                        } label: {
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(org.name)
                                    Text("\(projectsForOrg(org.id).count) projects")
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

                        ForEach(filteredProjects(for: org.id), id: \.id) { project in
                            Button {
                                appState.selectScope(.project(project))
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundStyle(.secondary)
                                    Text(project.displayName)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.quaternary)
                                        .font(.caption)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter organizations and projects…", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var filteredOrganizations: [Organization] {
        guard !searchText.isEmpty else { return organizations }
        return organizations.filter { org in
            org.name.localizedCaseInsensitiveContains(searchText)
            || projectsForOrg(org.id).contains { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func filteredProjects(for orgID: String) -> [Project] {
        let orgProjects = projectsForOrg(orgID)
        guard !searchText.isEmpty else { return orgProjects }
        if organizations.first(where: { $0.id == orgID })?.name
            .localizedCaseInsensitiveContains(searchText) == true {
            return orgProjects
        }
        return orgProjects.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    private func projectsForOrg(_ orgID: String) -> [Project] {
        projects
            .filter { $0.organizationId == orgID }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func loadScopes() async {
        isLoading = true
        error = nil
        do {
            async let orgs = appState.client.listOrganizations()
            async let projs = appState.client.listProjects()
            organizations = try await orgs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            projects = try await projs
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading organizations…")
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
                Task { await loadScopes() }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
