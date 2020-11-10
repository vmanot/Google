//
// Copyright (c) Vatsal Manot
//

import Swift

public struct GoogleServiceAccountKey: Decodable {
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case projectId = "project_id"
        case privateKeyId = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientId = "client_id"
        case authURI = "auth_uri"
        case tokenURI = "token_uri"
        case authProviderX509CertURL = "auth_provider_x509_cert_url"
        case clientX509CertURL = "client_x509_cert_url"
    }
    
    public let type: String
    public let projectId: String
    public let privateKeyId: String
    public let privateKey: String
    public let clientEmail: String
    public let clientId: String
    public let authURI: String
    public let tokenURI: String
    public let authProviderX509CertURL: String
    public let clientX509CertURL: String
}
