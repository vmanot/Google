//
// Copyright (c) Vatsal Manot
//

import NetworkKit
import Swallow

public struct FirestoreInterface: RESTfulHTTPInterface {
    public struct Schema { }
    
    public var host: URL {
        URL(string: "https://firestore.googleapis.com/v1/projects/\(projectID)")!
    }
    
    let token: GoogleServiceTokenProvider.Token?
    let projectID: String
    
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
    @Path({ "databases/(default)/documents/\($0):listCollectionIds" })
    public var listCollections = Endpoint<String, Schema.CollectionList>()
    
    @GET
    @Path({ "databases/(default)/documents/\($1.name?.dropPrefixIfPresent("projects/\($0.projectID)/databases/(default)/documents/") ?? ""):listCollectionIds" })
    public var listCollectionsInDocument = Endpoint<FirestoreDocument, Schema.CollectionList>()
    
    @GET
    @Path({ "databases/(default)/documents/\($0)" })
    public var listDocumentsInCollection = Endpoint<String, Schema.DocumentList>()
    
    @GET
    @Path("locations")
    public var listLocations = Endpoint<Void, Schema.LocationList>()
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
    public final class Endpoint<Input, Output: Decodable>: GenericEndpoint<Input, Output> {
        override public func buildRequestBase(
            from input: Input,
            context: BuildRequestContext
        ) throws -> HTTPRequest {
            try super.buildRequestBase(from: input, context: context)
                .header(.authorization(.bearer, try (context.root.token?.accessToken).unwrap()))
                .header(.contentType(.json))
        }
        
        override public func decodeOutput(
            from response: Request.Response,
            context: DecodeOutputContext
        ) throws -> Output {
            try response.validate()
            
            return try response.decodeJSON(Output.self)
        }
    }
}
