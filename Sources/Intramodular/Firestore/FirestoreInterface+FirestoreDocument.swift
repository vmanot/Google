//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

public struct FirestoreCreateDocumentOptions: Hashable {
    public var documentID: String?
    public var mask: FirestoreDocumentMask?
    
    public var queryItems: [URLQueryItem] {
        []
        + (documentID.map({ [URLQueryItem(name: "documentId", value: $0)] }) ?? [])
        + (mask?.queryItems ?? [])
    }
    
    public init(documentID: String?, mask: FirestoreDocumentMask?) {
        self.documentID = documentID
        self.mask = mask
    }
}

public struct FirestorePatchDocumentOptions: Hashable {
    public var updateMask: FirestoreDocumentMask
    public var mask: FirestoreDocumentMask?
    public var currentDocument: FirestoreDocumentPrecondition?
    
    public var queryItems: [URLQueryItem] {
        [URLQueryItem]()
            .appending(contentsOf: mask?.queryItems ?? [])
            .appending(contentsOf: currentDocument?.queryItems ?? [])
            .appending(contentsOf: updateMask.fieldPaths.map({ URLQueryItem(name: "updateMask.fieldPaths", value: $0) }))
    }
    
    public init(updateMask: FirestoreDocumentMask) {
        self.updateMask = updateMask
    }
}

public struct FirestoreDocumentMask: Codable, Hashable {
    public let fieldPaths: [String]
    
    public var queryItems: [URLQueryItem] {
        [.init(name: "mask", value: String(data: try! JSONEncoder().encode(self), encoding: .ascii))]
    }
    
    public static func allFieldKeys(of document: FirestoreDocument) -> FirestoreDocumentMask {
        return FirestoreDocumentMask(fieldPaths: document.allFlattenedKeys)
    }
}

public enum FirestoreDocumentPrecondition: Hashable {
    case exists(Bool)
    case updateTime(Date)
    
    public var queryItems: [URLQueryItem] {
        switch self {
            case .exists(let exists):
                return [.init(name: "exists", value: "\(exists)")]
            case .updateTime(let updateTime):
                return [.init(name: "updateTime", value: FirestoreDocument.serialize(date: updateTime))]
        }
    }
}
