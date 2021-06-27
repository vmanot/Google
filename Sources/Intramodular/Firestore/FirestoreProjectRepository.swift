//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

open class FirestoreProjectRepository: HTTPRepository {
    @Published private var token: GoogleServiceTokenProvider.Token?
    @Published private var projectID: String
    @Published private var tokenProvider: GoogleServiceTokenProvider?
    
    public var interface: FirestoreInterface {
        .init(token: token, projectID: projectID)
    }
    
    public init(projectID: String) {
        self.projectID = projectID
    }
    
    @discardableResult
    public func resolveToken(from credentials: GoogleServiceAccountKey) -> some Task {
        self.tokenProvider = GoogleServiceTokenProvider(serviceAccountCredentials: credentials)
        
        return tokenProvider!
            .requestToken(scopes: [
                "https://www.googleapis.com/auth/datastore",
                "https://www.googleapis.com/auth/cloud-platform"
            ])
            .receiveOnMainQueue()
            .handleOutput {
                self.token = $0
            }
            .convertToTask()
    }
}

extension FirestoreProjectRepository {
    public func collectionList(for document: FirestoreDocument) -> AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.CollectionList> {
        .init(RESTfulResource(repository: self, get: \.listCollectionsInDocument, from: document))
    }
    
    public func createDocumentWithName(_ name: String, at path: String, withFields fields: [String: String]) -> some Task {
        let document = FirestoreDocument(name: nil, fields: fields.mapValues({ .stringValue($0) }))
        
        return self.createDocument((path, document, .init(documentID: name, mask: nil)))
    }
    
    @discardableResult
    public func patch(_ document: FirestoreDocument) -> some Task {
        return self.patchDocument((document, .init(updateMask: .allFieldKeys(of: document))))
    }
    
    @discardableResult
    public func patch(_ document: FirestoreDocument, at path: String) -> some Task {
        var document = document
        
        let prefix = "projects/\(interface.projectID)/databases/(default)/documents"
        let path = String(path.dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
        
        document.name = prefix + "/" + String(path.dropPrefixIfPresent(prefix).dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
        
        return self.patchDocument((document, .init(updateMask: .allFieldKeys(of: document))))
    }
}
