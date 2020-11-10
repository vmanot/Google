//
// Copyright (c) Vatsal Manot
//

import FoundationX
import NetworkKit
import Swift

public struct GoogleServiceTokenProvider {
    let session = HTTPSession()
    let serviceAccountCredentials: GoogleServiceAccountKey
    
    public init(serviceAccountCredentials: GoogleServiceAccountKey) {
        self.serviceAccountCredentials = serviceAccountCredentials
    }
    
    public struct Token: Decodable, Hashable {
        public enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
        
        public let accessToken: String
        public let expiresIn: Int
        public let tokenType: String
        
        public let receiptDate = Date()
        
        public var isExpired: Bool {
            receiptDate + TimeInterval(expiresIn) < Date()
        }
    }
    
    public func requestToken(scopes: [String]) -> AnyPublisher<Token, Error> {
        do {
            let request = try HTTPRequest(url: serviceAccountCredentials.tokenURI)
                .unwrap()
                .method(.post)
                .header(.contentType(.json))
                .jsonBody(["grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": try JWT.create(using: self.serviceAccountCredentials, for: scopes)])
            
            return session
                .task(with: request)
                .successPublisher
                .map(\.data)
                .decode(type: Token.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
        } catch {
            return .failure(error)
        }
    }
}
