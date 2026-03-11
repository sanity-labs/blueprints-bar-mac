import Foundation

final class FunctionsClient: Sendable {
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

    func withScope(_ scope: Scope) -> FunctionsClient {
        FunctionsClient(
            environment: environment,
            scopeType: scope.scopeType,
            scopeID: scope.scopeID
        )
    }

    // MARK: - Functions API

    func listLogs(functionID: String, limit: Int = 25) async throws -> [FunctionLog] {
        var components = URLComponents(string: environment.baseURL + "/v2025-07-30/functions/\(functionID)/logs")!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        var request = URLRequest(url: components.url!)
        request.setValue(scopeType, forHTTPHeaderField: "x-sanity-scope-type")
        request.setValue(scopeID, forHTTPHeaderField: "x-sanity-scope-id")

        let response: FunctionLogsResponse = try await perform(request)
        return response.logs
    }

    // MARK: - HTTP

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
        if let envToken = ProcessInfo.processInfo.environment["SANITY_AUTH_TOKEN"], !envToken.isEmpty {
            return envToken
        }

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

// MARK: - Response wrappers

private struct FunctionLogsResponse: Decodable {
    let logs: [FunctionLog]
}
