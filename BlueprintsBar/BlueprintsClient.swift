import Foundation

struct APIError: Decodable, Sendable {
    let statusCode: Int?
    let error: String?
    let message: String?
}

final class BlueprintsClient: Sendable {
    private let environment: APIEnvironment
    private let token: String
    private let session: URLSession
    private let scopeType: String
    private let scopeID: String

    init(environment: APIEnvironment, scopeType: String = "", scopeID: String = "") {
        self.environment = environment
        self.token = Self.readToken(environment: environment)
        self.session = .shared
        self.scopeType = scopeType
        self.scopeID = scopeID
    }

    func withScope(_ scope: Scope) -> BlueprintsClient {
        BlueprintsClient(
            environment: environment,
            scopeType: scope.scopeType,
            scopeID: scope.scopeID
        )
    }

    var hasToken: Bool { !token.isEmpty }

    // MARK: - Management API (no scope headers)

    func listOrganizations() async throws -> [Organization] {
        try await getManagement("/v2021-06-07/organizations")
    }

    func listProjects() async throws -> [Project] {
        try await getManagement("/v2021-06-07/projects")
    }

    // MARK: - Blueprints API

    func listStacks() async throws -> [Stack] {
        try await get("/stacks")
    }

    func getStack(_ id: String) async throws -> Stack {
        try await get("/stacks/\(id)")
    }

    func listResources(stackID: String) async throws -> [Resource] {
        try await get("/stacks/\(stackID)/resources")
    }

    func getResource(stackID: String, resourceID: String) async throws -> Resource {
        try await get("/stacks/\(stackID)/resources/\(resourceID)")
    }

    func listOperations(stackID: String, status: String? = nil, limit: Int? = nil) async throws -> [Operation] {
        var params: [(String, String)] = []
        if let status { params.append(("status", status)) }
        if let limit { params.append(("limit", String(limit))) }
        return try await get("/stacks/\(stackID)/operations", params: params)
    }

    func getOperation(stackID: String, operationID: String) async throws -> Operation {
        try await get("/stacks/\(stackID)/operations/\(operationID)")
    }

    func listLogs(
        stackID: String? = nil,
        operationID: String? = nil,
        resourceID: String? = nil,
        limit: Int? = nil
    ) async throws -> [LogEntry] {
        var params: [(String, String)] = []
        if let stackID { params.append(("stackId", stackID)) }
        if let operationID { params.append(("operationId", operationID)) }
        if let resourceID { params.append(("resourceId", resourceID)) }
        if let limit { params.append(("limit", String(limit))) }
        return try await get("/logs", params: params)
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String, params: [(String, String)] = []) async throws -> T {
        var components = URLComponents(string: environment.blueprintsURL + path)!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        }

        var request = URLRequest(url: components.url!)
        request.setValue(scopeType, forHTTPHeaderField: "x-sanity-scope-type")
        request.setValue(scopeID, forHTTPHeaderField: "x-sanity-scope-id")
        return try await perform(request)
    }

    private func getManagement<T: Decodable>(_ path: String) async throws -> T {
        let request = URLRequest(url: URL(string: environment.baseURL + path)!)
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode == 200 else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data),
               let message = apiError.message {
                throw ClientError.api(statusCode: httpResponse.statusCode, message: message)
            }
            throw ClientError.api(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Token

    private static func readToken(environment: APIEnvironment) -> String {
        // Check environment variable first
        if let envToken = ProcessInfo.processInfo.environment["SANITY_AUTH_TOKEN"], !envToken.isEmpty {
            return envToken
        }

        // Read from ~/.config/sanity/config.json or ~/.config/sanity-staging/config.json
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configPath = home
            .appendingPathComponent(".config")
            .appendingPathComponent(environment.configDirectory)
            .appendingPathComponent("config.json")

        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["authToken"] as? String else {
            return ""
        }
        return token
    }
}

enum ClientError: LocalizedError {
    case api(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .api(let code, let message): "API error \(code): \(message)"
        }
    }
}
