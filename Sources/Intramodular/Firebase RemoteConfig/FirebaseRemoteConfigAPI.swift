//
// Copyright (c) Vatsal Manot
//

import Data
import NetworkKit
import Swallow

public struct FirebaseRemoteConfigAPI: RESTfulHTTPInterface {
    public var accessToken: String? = nil
    public let projectID: String
    
    public let host: URL = URL(string: "https://firebaseremoteconfig.googleapis.com/v1/")!
    
    public var id: some Hashable {
        accessToken
    }
    
    @GET
    @Path({ context in "projects/\(context.root.projectID)/remoteConfig" })
    public var getRemoteConfig = Endpoint<Void, JSON, Void>()
    
    @PUT
    @Header({ context in
        HTTPHeaderField.contentType(.json)
        HTTPHeaderField.custom(key: context.input.etag ?? "*", value: "If-Match")
    })
    @Path({ context in "projects/\(context.root.projectID)/remoteConfig" })
    @Body(json: \.input.remoteConfig)
    public var overrideRemoteConfig = Endpoint<(remoteConfig: JSON, etag: String?), Swallow.None, Void>()
}

extension FirebaseRemoteConfigAPI {
    public final class Endpoint<Input, Output, Options>: BaseHTTPEndpoint<FirebaseRemoteConfigAPI, Input, Output, Options> {
        override public func buildRequestBase(
            from input: Input,
            context: BuildRequestContext
        ) throws -> HTTPRequest {
            try super.buildRequestBase(from: input, context: context)
                .header(.authorization(.bearer, context.root.accessToken.unwrap()))
                .header(.contentType(.json))
                .header(.custom(key: "Accept-Encoding", value: "gzip"))
        }
        
        override public func decodeOutputBase(
            from response: Request.Response,
            context: DecodeOutputContext
        ) throws -> Output {
            try response.validate()
            
            return try response.decode(Output.self, using: JSONDecoder())
        }
    }
}
