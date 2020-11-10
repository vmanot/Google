//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

public struct FirestoreDocument: Hashable {
    public let name: String?
    public let fields: [String: Value]
    public let createTime: Date
    public let updateTime: Date
    
    public var title: String {
        name?.components(separatedBy: "/").last ?? name ?? ""
    }
    
    public init(name: String? = .none, fields: [String: Value]) {
        self.name = name
        self.fields = fields
        self.createTime = Date()
        self.updateTime = Date()
    }
}

extension FirestoreDocument {
    public indirect enum Value: Codable, Hashable {
        enum CodingKeys: CodingKey {
            case nullValue
            case booleanValue
            case integerValue
            case doubleValue
            case timestampValue
            case stringValue
            case bytesValue
            case referenceValue
            case geoPointValue
            case arrayValue
            case mapValue
        }
        
        case nullValue
        case booleanValue(Bool)
        case integerValue(String)
        case doubleValue(Double)
        case timestampValue(String)
        case stringValue(String)
        case bytesValue(String)
        case referenceValue(String)
        case geoPointValue(GeoPoint)
        case arrayValue(ArrayValue)
        case mapValue(MapValue)
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if container.contains(.nullValue) {
                self = .nullValue
            } else if let value = try container.decodeIfPresent(Bool.self, forKey: .booleanValue) {
                self = .booleanValue(value)
            } else if let value = try container.decodeIfPresent(String.self, forKey: .integerValue) {
                self = .integerValue(value)
            } else if let value = try container.decodeIfPresent(Double.self, forKey: .doubleValue) {
                self = .doubleValue(value)
            } else if let value = try container.decodeIfPresent(String.self, forKey: .timestampValue) {
                self = .timestampValue(value)
            } else if let value = try container.decodeIfPresent(String.self, forKey: .stringValue) {
                self = .stringValue(value)
            } else if let value = try container.decodeIfPresent(String.self, forKey: .bytesValue) {
                self = .bytesValue(value)
            } else if let value = try container.decodeIfPresent(String.self, forKey: .referenceValue) {
                self = .referenceValue(value)
            } else if let value = try container.decodeIfPresent(GeoPoint.self, forKey: .geoPointValue) {
                self = .geoPointValue(value)
            } else if let value = try container.decodeIfPresent(ArrayValue.self, forKey: .arrayValue) {
                self = .arrayValue(value)
            } else if let value = try container.decodeIfPresent(MapValue.self, forKey: .mapValue) {
                self = .mapValue(value)
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath))
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
                case .nullValue:
                    try container.encode(Optional<String>.none, forKey: .nullValue)
                case .booleanValue(let value):
                    try container.encode(value, forKey: .booleanValue)
                case .integerValue(let value):
                    try container.encode(value, forKey: .integerValue)
                case .doubleValue(let value):
                    try container.encode(value, forKey: .doubleValue)
                case .timestampValue(let value):
                    try container.encode(value, forKey: .timestampValue)
                case .stringValue(let value):
                    try container.encode(value, forKey: .stringValue)
                case .bytesValue(let value):
                    try container.encode(value, forKey: .bytesValue)
                case .referenceValue(let value):
                    try container.encode(value, forKey: .referenceValue)
                case .geoPointValue(let value):
                    try container.encode(value, forKey: .geoPointValue)
                case .arrayValue(let value):
                    try container.encode(value, forKey: .arrayValue)
                case .mapValue(let value):
                    try container.encode(value, forKey: .mapValue)
            }
        }
    }
    
    public struct GeoPoint: Codable, Hashable {
        public let latitude: Double
        public let longitude: Double
        
        public init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    public struct ArrayValue: Codable, Hashable {
        public let values: [Value]?
        
        init(_ values: [Value]) {
            self.values = values
        }
        
        init<SequenceType: Sequence>(_ values: SequenceType) where SequenceType.Element == Value {
            self.values = Array(values)
        }
    }
    
    public struct MapValue: Codable, Hashable {
        public let fields: [String: Value]?
        
        public init(fields: [String: Value]) {
            self.fields = fields
        }
        
        func flattenFieldKeys(prefix: String = "") -> [String] {
            return fields?.flatMap { pair -> [String] in
                if case .mapValue(let map) = pair.value {
                    return map.flattenFieldKeys(prefix: pair.key)
                } else {
                    return ["\(prefix).\(pair.key)"]
                }
            } ?? []
        }
    }
}

fileprivate extension FirestoreDocument {
    private enum DecodeError: Error {
        case invalidDate(date: String, format: String, key: CodingKeys)
        case unsupportedValueType
        case cannotDeserializeTimestamp(String)
    }
    
    static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    
    static func serialize(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = FirestoreDocument.dateFormat
        return formatter.string(from:date)
    }
    
    static func deserialize(date serializedDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = FirestoreDocument.dateFormat
        if let date = formatter.date(from: serializedDate) {
            return date
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter.date(from: serializedDate)
        }
    }
    
    static func decodeDate(forKey key: CodingKeys, container: KeyedDecodingContainer<CodingKeys>) throws -> Date {
        let dateString = try container.decode(String.self, forKey: key)
        
        guard let date = FirestoreDocument.deserialize(date: dateString) else {
            throw DecodeError.invalidDate(date: dateString, format: dateFormat, key: key)
        }
        
        return date
    }
    
    static func filterSkipFields(_ skipFields: Set<String>, property: String) -> Set<String> {
        return Set(
            skipFields
                .filter({ !$0.starts(with: "\(property).") })
                .map({ String($0.dropFirst("\(property).".count)) })
        )
    }
}

// MARK: - Protocol Implementations -

extension FirestoreDocument: Codable {
    enum CodingKeys: CodingKey {
        case name
        case fields
        case createTime
        case updateTime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.fields = try container.decode([String: Value].self, forKey: .fields)
        
        if container.contains(.createTime) {
            self.createTime = try FirestoreDocument.decodeDate(forKey: .createTime, container: container)
        } else {
            self.createTime = Date()
        }
        
        if container.contains(.updateTime) {
            self.updateTime = try FirestoreDocument.decodeDate(forKey: .updateTime, container: container)
        } else {
            self.updateTime = Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let name = self.name {
            try container.encode(name, forKey: .name)
        }
        
        try container.encode(fields, forKey: .fields)
    }
}

extension FirestoreDocument: CustomReflectable {
    public var customMirror: Mirror {
        .init(self, children: .init(fields), displayStyle: .struct)
    }
}

extension FirestoreDocument.Value: CustomReflectable {
    public var customMirror: Mirror {
        switch self {
            case .nullValue:
                return Optional<String>.none.customMirror
            case .booleanValue(let value):
                return .init(reflecting: value)
            case .integerValue(let value):
                return .init(reflecting: value)
            case .doubleValue(let value):
                return .init(reflecting: value)
            case .timestampValue(let value):
                return .init(reflecting: value)
            case .stringValue(let value):
                return .init(reflecting: value)
            case .bytesValue(let value):
                return .init(reflecting: value)
            case .referenceValue(let value):
                return .init(reflecting: value)
            case .geoPointValue(let value):
                return .init(reflecting: value)
            case .arrayValue(let value):
                return .init(value, unlabeledChildren: value.values ?? [])
            case .mapValue(let value):
                return .init(value, children: .init(value.fields ?? [:]))
        }
    }
}

extension FirestoreDocument.Value: CustomStringConvertible {
    public var description: String {
        switch self {
            case .nullValue:
                return "null"
            case .booleanValue(let value):
                return value.description
            case .integerValue(let value):
                return value.description
            case .doubleValue(let value):
                return value.description
            case .timestampValue(let value):
                return value.description
            case .stringValue(let value):
                return value.description
            case .bytesValue(let value):
                return value.description
            case .referenceValue(let value):
                return value.description
            case .geoPointValue(let value):
                return String(describing: value)
            case .arrayValue(let value):
                return (value.values ?? []).description
            case .mapValue(let value):
                return (value.fields ?? [:]).description
        }
    }
}
