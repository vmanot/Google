//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

enum JWT {
    enum KeyError: Error {
        case unableToDecode(from: String)
    }
    
    struct Header: Encodable {
        enum CodingKeys: String, CodingKey {
            case type = "typ"
            case algorithm = "alg"
        }
        
        let type: String
        let algorithm: String
    }
    
    struct Payload: Encodable {
        enum CodingKeys: String, CodingKey {
            case issuer = "iss"
            case audience = "aud"
            case expiration = "exp"
            case issuedAt = "iat"
            case scope = "scope"
        }
        
        let issuer: String
        let audience: String
        let expiration: Int
        let issuedAt: Int
        let scope: String
    }
}

extension JWT {
    public static func create(
        using key: GoogleServiceAccountKey,
        for scopes: [String]
    ) throws -> String {
        let header = Header(type: "JWT", algorithm: "RS256")
        let now = Date()
        let payload = Payload(
            issuer: key.clientEmail,
            audience: key.tokenURI,
            expiration: Int(now.addingTimeInterval(3600).timeIntervalSince1970),
            issuedAt: Int(now.timeIntervalSince1970),
            scope: scopes.joined(separator: " ")
        )
        
        let encoder = JSONEncoder()
        
        let encodedHeader = try encoder.encode(header).base64URLEncodedString()
        let encodedPayload = try encoder.encode(payload).base64URLEncodedString()
        
        let privateKey = try self.key(from: key.privateKey)
        let signature = try sign(Data("\(encodedHeader).\(encodedPayload)".utf8), with: privateKey)
        let encodedSignature = signature.base64URLEncodedString()
        
        return "\(encodedHeader).\(encodedPayload).\(encodedSignature)"
    }
    
    private static func key(from pem: String) throws -> Data {
        let unwrappedPEM = pem
            .split(separator: "\n")
            .filter({ !$0.contains("PRIVATE KEY") })
            .joined()
        
        let headerLength = 26
        
        guard let der = Data(base64Encoded: unwrappedPEM), der.count > headerLength else {
            throw KeyError.unableToDecode(from: pem)
        }
        
        return der[headerLength...]
    }
    
    private static func sign(_ data: Data, with key: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits: 256
        ] as CFDictionary
        
        guard let privateKey = SecKeyCreateWithData(key as CFData, attributes, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        guard let signature = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return signature
    }
}

fileprivate extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
