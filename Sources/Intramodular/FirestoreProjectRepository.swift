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
            .publish(to: \.token, on: self)
            .then {
                self.objectWillChange.send()
            }
            .eraseToTask()
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
}
