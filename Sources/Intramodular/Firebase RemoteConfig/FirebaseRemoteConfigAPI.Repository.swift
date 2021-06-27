//
// Copyright (c) Vatsal Manot
//

import Data
import NetworkKit
import Swallow

extension FirebaseRemoteConfigAPI {
    open class Repository: CancellablesHolder, HTTPRepository {
        public let key: GoogleServiceAccountKey
        
        @Published var accessToken: String?
        
        public var interface: FirebaseRemoteConfigAPI {
            .init(accessToken: accessToken, projectID: key.projectID)
        }
        
        public init(key: GoogleServiceAccountKey) {
            self.key = key
        }
        
        public func resolve() -> some Task {
            let task = GoogleServiceTokenProvider(serviceAccountCredentials: key)
                .requestToken(scopes: [
                    "https://www.googleapis.com/auth/cloud-platform",
                    "https://www.googleapis.com/auth/firebase.remoteconfig"
                ])
                .receiveOnMainQueue()
                .discardError()
                .handleOutput {
                    self.accessToken = $0.accessToken
                }
                .convertToTask()
            
            task.start()
            
            return task
        }
    }
}
