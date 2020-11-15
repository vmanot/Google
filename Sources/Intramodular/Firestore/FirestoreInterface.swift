//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

public struct FirestoreInterface: RESTfulHTTPInterface {
    public struct Schema { }
    
    public var host: URL {
        URL(string: "https://firestore.googleapis.com/\(version)")!
    }
    
    public var baseURL: URL {
        host.appendingPathComponent("projects/\(projectID)")
    }
    
    public let version: String = "v1"
    public let token: GoogleServiceTokenProvider.Token?
    public let projectID: String
    
    public var id: some Hashable {
        ManyHashable(token, projectID)
    }
    
    public init(
        token: GoogleServiceTokenProvider.Token?,
        projectID: String
    ) {
        self.token = token
        self.projectID = projectID
    }
    
    @GET
    @Path({ "databases/(default)/documents/\($0.input):listCollectionIds" })
    public var listCollections = Endpoint<String, Schema.CollectionList>()
    
    @GET
    @AbsolutePath({ context in
        context.root.host.appendingPathComponent(try context.input.name.unwrap())
    })
    public var listCollectionsInDocument = Endpoint<FirestoreDocument, Schema.CollectionList>()
    
    @GET
    @Path({ context in
        "databases/(default)/documents/\(context.input)"
    })
    public var listDocumentsInCollection = Endpoint<String, Schema.DocumentList>()
    
    @GET
    @Path("locations")
    public var listLocations = Endpoint<Void, Schema.LocationList>()
    
    @GET
    @AbsolutePath({ context in
        context.root.host.appendingPathComponent(context.root.documentName(forDocumentPath: context.input))
    })
    public var getDocumentAtPath = Endpoint<String, FirestoreDocument>()
    
    @PATCH
    @AbsolutePath({ context in
        context.root.host.appendingPathComponent(try context.input.document.name.unwrap())
    })
    @Query(\.options.queryItems)
    @Body(json: \.document)
    public var patchDocument = Endpoint<(document: FirestoreDocument, options: FirestorePatchDocumentOptions), Schema.LocationList>()
}

extension FirestoreInterface {
    func documentName(forDocumentPath path: String) -> String {
        let prefix = "projects/\(projectID)/databases/(default)/documents"
        let path = String(path.dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
        
        return prefix + "/" + String(path.dropPrefixIfPresent(prefix).dropPrefixIfPresent("/").dropSuffixIfPresent("/"))
    }
}

extension FirestoreInterface.Schema {
    public struct LocationList: Decodable, Hashable {
        public struct Location: Decodable, Hashable {
            public let name: String
            public let locationId: String
            public let displayName: String
            public let labels: [String: String]
        }
        
        public let locations: [Location]?
    }
    
    public struct CollectionList: Decodable {
        public let collectionIds: [String]?
        public let nextPageToken: String?
    }
    
    public struct DocumentList: Decodable {
        public let documents: [FirestoreDocument]?
        public let nextPageToken: String?
    }
}

extension FirestoreInterface {
    public final class Endpoint<Input, Output: Decodable>: BaseHTTPEndpoint<FirestoreInterface, Input, Output> {
        override public func buildRequestBase(
            from input: Input,
            context: BuildRequestContext
        ) throws -> HTTPRequest {
            if let token = context.root.token?.accessToken {
                return try super.buildRequestBase(from: input, context: context)
                    .header(.authorization(.bearer, token))
                    .header(.contentType(.json))
            } else {
                return try super.buildRequestBase(from: input, context: context)
                    .header(.contentType(.json))
            }
        }
        
        override public func decodeOutputBase(
            from response: Request.Response,
            context: DecodeOutputContext
        ) throws -> Output {
            try response.validate()
            
            return try response.decodeJSON(Output.self)
        }
    }
}
