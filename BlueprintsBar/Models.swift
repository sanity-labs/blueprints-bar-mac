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

struct Stack: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let scopeType: String
    let scopeId: String
    let blueprintId: String
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

struct Operation: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let stackId: String
    let blueprintId: String
    let status: String
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
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
    /// "2026-02-27 08:15"
    var dateTime: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute())
    }

    /// "2026-02-27 08:15:30"
    var dateTimeSeconds: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute().second())
    }
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
