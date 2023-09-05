//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

open class FirestoreProjectRepository: HTTPClient {
    @Published private var token: GoogleServiceTokenProvider.Token?
    @Published private var projectID: String
    @Published private var tokenProvider: GoogleServiceTokenProvider?
    
    public var interface: FirestoreInterface {
        .init(token: token, projectID: projectID)
    }
    
    public init(projectID: String) {
        self.projectID = projectID
    }
    
    public func resolveToken(from credentials: GoogleServiceAccountKey) async throws {
        await MainActor.run {
            self.tokenProvider = GoogleServiceTokenProvider(serviceAccountCredentials: credentials)
        }
        
        let token = try await tokenProvider!.requestToken(scopes: [
            "https://www.googleapis.com/auth/datastore",
            "https://www.googleapis.com/auth/cloud-platform"
        ])
        
        await MainActor.run {
            self.token = token
        }
    }
}

extension FirestoreProjectRepository {
    public func createDocumentWithName(_ name: String, at path: String, withFields fields: [String: String]) -> some ObservableTask {
        let document = FirestoreDocument(name: nil, fields: fields.mapValues({ .stringValue($0) }))
        
        return run(\.createDocument, with: (path, document, .init(documentID: name, mask: nil)))
    }
    
    @discardableResult
    public func patch(_ document: FirestoreDocument) -> some ObservableTask {
        return run(\.patchDocument, with: (document, .init(updateMask: .allFieldKeys(of: document))))
    }
    
    @discardableResult
    public func patch(_ document: FirestoreDocument, at path: String) -> some ObservableTask {
        var document = document
        
        let prefix = "projects/\(interface.projectID)/databases/(default)/documents"
        let path = String(path.dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
        
        document.name = prefix + "/" + String(path.dropPrefixIfPresent(prefix).dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
        
        let patchOptions = FirestorePatchDocumentOptions(updateMask: .allFieldKeys(of: document))
        
        return self.run(\.patchDocument, with: (document, patchOptions))
    }
}
