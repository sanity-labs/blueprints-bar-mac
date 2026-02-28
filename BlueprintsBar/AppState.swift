import SwiftUI

@MainActor @Observable
final class AppState {
    var environment: APIEnvironment = .production
    var client: BlueprintsClient
    var selectedScope: Scope?
    var navigationPath: [Route] = []
    var isDetached = false

    init() {
        self.client = BlueprintsClient(environment: .production)
    }

    func switchEnvironment(_ env: APIEnvironment) {
        environment = env
        client = BlueprintsClient(environment: env)
        selectedScope = nil
        navigationPath = []
    }

    func selectScope(_ scope: Scope) {
        selectedScope = scope
        client = client.withScope(scope)
        navigationPath = []
    }

    func clearScope() {
        selectedScope = nil
        client = BlueprintsClient(environment: environment)
        navigationPath = []
    }
}

enum Route: Hashable {
    case stackDetail(Stack)
    case resourceDetail(Resource)
    case operationDetail(stackID: String, Operation)
}

enum Scope: Hashable {
    case organization(Organization)
    case project(Project)

    var label: String {
        switch self {
        case .organization(let org): org.name
        case .project(let proj): proj.displayName
        }
    }

    var scopeType: String {
        switch self {
        case .organization: "organization"
        case .project: "project"
        }
    }

    var scopeID: String {
        switch self {
        case .organization(let org): org.id
        case .project(let proj): proj.id
        }
    }
}
