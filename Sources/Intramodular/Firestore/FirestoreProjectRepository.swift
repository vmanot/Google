//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

open class FirestoreProjectRepository: HTTPRepository {
    @Published public var token: GoogleServiceTokenProvider.Token?
    @Published public var projectID: String
    
    public var interface: FirestoreInterface {
        .init(token: token, projectID: projectID)
    }
    
    @Resource(get: \.listLocations) public var locations
    @Resource(get: \.listCollections) public var collections
    
    public init(projectID: String) {
        self.projectID = projectID
        
        collections = nil
    }
    
    @discardableResult
    public func resolveToken(from credentials: GoogleServiceAccountKey) -> some Task {
        GoogleServiceTokenProvider(serviceAccountCredentials: credentials)
            .requestToken(scopes: [
                "https://www.googleapis.com/auth/datastore",
                "https://www.googleapis.com/auth/cloud-platform"
            ])
            .receiveOnMainQueue()
            .discardError()
            .publish(to: \.token, on: self)
            .then {
                self.objectWillChange.send()
            }
            .convertToTask()
            .store(in: session.cancellables)
            .then {
                $0.start()
            }
    }
}

extension FirestoreProjectRepository {
    public func collectionList(for document: FirestoreDocument) -> AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.CollectionList> {
        .init(RESTfulResource(repository: self, get: \.listCollectionsInDocument, from: document))
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
