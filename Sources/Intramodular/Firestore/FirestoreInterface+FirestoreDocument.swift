//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

public struct FirestorePatchDocumentOptions: Hashable {
    public var updateMask: FirestoreDocumentMask
    public var mask: FirestoreDocumentMask?
    public var currentDocument: FirestoreDocumentPrecondition?
    
    public var asQueryString: String {
        var queryString = ""
        if let mask = self.mask {
            queryString += mask.asJsonString()
        }
        if let currentDocument = self.currentDocument {
            queryString += (queryString.isEmpty ? "" : "&") + currentDocument.asQueryString
        }
        
        for fieldPath in updateMask.fieldPaths {
            queryString += (queryString.isEmpty ? "" : "&") + "updateMask.fieldPaths=\(fieldPath)"
        }
        
        return queryString
    }
    
    public init(updateMask: FirestoreDocumentMask) {
        self.updateMask = updateMask
    }
}

public struct FirestoreDocumentMask: Codable, Hashable {
    public let fieldPaths: [String]
    
    func asJsonString() -> String {
        let jsonData = try? JSONEncoder().encode(self)
        guard let jsonString = jsonData.flatMap({ String(data: $0, encoding: .ascii) }) else {
            fatalError("ERROR - Cannot encode mask property into JSON string")
        }
        return jsonString
    }
    
    public var asQueryString: String {
        return "mask=\(asJsonString())"
    }
    
    public static func allFieldKeys(of document: FirestoreDocument) -> FirestoreDocumentMask {
        return FirestoreDocumentMask(fieldPaths: document.allFlattenedKeys)
    }
}

public enum FirestoreDocumentPrecondition: Hashable {
    case exists(Bool)
    case updateTime(Date)
    
    public var asQueryString: String {
        switch self {
            case .exists(let exists):
                return "exists=\(exists)"
            case .updateTime(let updateTime):
                return "updateTime=\(FirestoreDocument.serialize(date: updateTime))"
        }
    }
}
