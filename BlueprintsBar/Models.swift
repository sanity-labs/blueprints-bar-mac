import Foundation

enum APIEnvironment: String, CaseIterable {
    case production
    case staging

    var baseURL: String {
        switch self {
        case .production: "https://api.sanity.io"
        case .staging: "https://api.sanity.work"
        }
    }

    var blueprintsURL: String {
        baseURL + "/vX/blueprints"
    }

    var configDirectory: String {
        switch self {
        case .production: "sanity"
        case .staging: "sanity-staging"
        }
    }

    var label: String {
        switch self {
        case .production: "sanity.io"
        case .staging: "sanity.work"
        }
    }

    var configExists: Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home.appendingPathComponent(".config").appendingPathComponent(configDirectory)
        return FileManager.default.fileExists(atPath: path.path)
    }

    static var available: [APIEnvironment] {
        allCases.filter(\.configExists)
    }
}

struct Organization: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
}

struct Project: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let organizationId: String
}

struct Stack: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let scopeType: String
    let scopeId: String
    let blueprintId: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
    let recentOperation: Operation?
    let resources: [Resource]?
    let resourceCount: Int?

    /// Prefer the full array count when available, fall back to the summary count
    var displayResourceCount: Int? {
        resources?.count ?? resourceCount
    }

    enum CodingKeys: String, CodingKey {
        case id, scopeType, scopeId, blueprintId, name, createdAt, updatedAt
        case recentOperation, resources, resourceCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        scopeType = try c.decode(String.self, forKey: .scopeType)
        scopeId = try c.decode(String.self, forKey: .scopeId)
        blueprintId = try c.decode(String.self, forKey: .blueprintId)
        name = try c.decode(String.self, forKey: .name)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        recentOperation = try? c.decode(Operation.self, forKey: .recentOperation)
        resources = try? c.decode([Resource].self, forKey: .resources)
        resourceCount = try? c.decode(Int.self, forKey: .resourceCount)
    }
}

struct Operation: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let stackId: String?
    let blueprintId: String?
    let status: String
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    // The API returns camelCase from dedicated endpoints but snake_case
    // in objects nested within other responses (e.g. stacks list).
    // This decoder handles both conventions.
    private enum CodingKeys: String, CodingKey {
        case id, status
        case stackId, stack_id
        case blueprintId, blueprint_id
        case completedAt, completed_at
        case createdAt, created_at
        case updatedAt, updated_at
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        status = try c.decode(String.self, forKey: .status)

        // Optional fields: try camelCase first, fall back to snake_case
        stackId = (try? c.decode(String.self, forKey: .stackId))
            ?? (try? c.decode(String.self, forKey: .stack_id))
        blueprintId = (try? c.decode(String.self, forKey: .blueprintId))
            ?? (try? c.decode(String.self, forKey: .blueprint_id))
        completedAt = (try? c.decode(Date.self, forKey: .completedAt))
            ?? (try? c.decode(Date.self, forKey: .completed_at))

        // Required fields: try camelCase, throw on snake_case failure
        if let date = try? c.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = try c.decode(Date.self, forKey: .created_at)
        }
        if let date = try? c.decode(Date.self, forKey: .updatedAt) {
            updatedAt = date
        } else {
            updatedAt = try c.decode(Date.self, forKey: .updated_at)
        }
    }
}

struct Resource: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let stackId: String
    let operationId: String
    let blueprintId: String?
    let externalId: String?
    let type: String
    let parameters: [String: AnyCodable]
    let providerMetadata: [String: AnyCodable]
    let createdAt: Date
    let updatedAt: Date
}

struct FunctionLog: Decodable, Identifiable, Hashable, Sendable {
    let id: UUID
    let time: Date
    let requestId: String
    let level: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case time, requestId, level, message
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        time = try c.decode(Date.self, forKey: .time)
        requestId = try c.decode(String.self, forKey: .requestId)
        level = try c.decode(String.self, forKey: .level)
        message = try c.decode(String.self, forKey: .message)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: FunctionLog, rhs: FunctionLog) -> Bool { lhs.id == rhs.id }
}

struct LogEntry: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let timestamp: Date
    let level: String?
    let message: String
    let duration: Int?
    let blueprintId: String?
    let stackId: String?
    let operationId: String?
    let resourceId: String?
    let requestId: String?
}

// MARK: - AnyCodable for arbitrary JSON values

struct AnyCodable: Codable, Hashable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        String(describing: lhs.value) == String(describing: rhs.value)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: value))
    }
}

// MARK: - Date formatting

extension Date {
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private static let dateTimeSecondsFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    /// "2026-02-27 08:15"
    var dateTime: String { Self.dateTimeFormatter.string(from: self) }

    /// "2026-02-27 08:15:30"
    var dateTimeSeconds: String { Self.dateTimeSecondsFormatter.string(from: self) }
}

// Pretty-print JSON-like dictionaries
extension Dictionary where Key == String, Value == AnyCodable {
    func prettyPrinted() -> String {
        guard !isEmpty else { return "(empty)" }
        guard let data = try? JSONSerialization.data(
            withJSONObject: mapValues(\.value),
            options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        ),
        let string = String(data: data, encoding: .utf8) else {
            return String(describing: self)
        }
        return string
    }
}
