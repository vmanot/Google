//
// Copyright (c) Vatsal Manot
//

import Compute
import Data
import NetworkKit
import Swallow

public struct FirestoreInterface: RESTfulHTTPInterface {
    public struct Schema {
        
    }
    
    public var host: URL {
        URL(string: "https://firestore.googleapis.com/\(version)")!
    }
    
    public var baseURL: URL {
        host.appendingPathComponent("projects/\(projectID)")
    }
    
    public let version: String = "v1beta1"
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
    public var listCollections = Endpoint<String, Schema.CollectionList, (Void)>()
    
    @GET
    @AbsolutePath(fromContext: { context in
        context.root.host.appendingPathComponent(try context.input.name.unwrap())
    })
    public var listCollectionsInDocument = Endpoint<FirestoreDocument, Schema.CollectionList, Void>()
    
    public struct ListDocumentsInCollectionOptions: CursorPaginated, Initiable {
        public var paginationCursor: PaginationCursor?
        
        public init() {
            
        }
    }
    
    @GET
    @Path({ context in
        "databases/(default)/documents/\(context.input)"
    })
    @Query("pageToken", fromContext: \.options.paginationCursor?.stringValue)
    public var listDocumentsInCollection = Endpoint<String, Schema.DocumentList, ListDocumentsInCollectionOptions>()
    
    @GET(Schema.LocationList.self)
    @Path("locations")
    public var listLocations = Endpoint()
    
    // MARK: Document
    
    @POST
    @AbsolutePath(fromContext: { context in
        context.root.host
            .appendingPathComponent("projects/\(context.root.projectID)/databases/(default)")
            .appendingPathComponent("documents")
            .appendingPathComponent(context.input.collectionID)
    })
    @Query(\.options.queryItems)
    @Body(json: \.document)
    public var createDocument = Endpoint<(collectionID: String, document: FirestoreDocument, options: FirestoreCreateDocumentOptions), JSON, Void>()
    
    @GET
    @AbsolutePath(fromContext: { context in
        context.root.host.appendingPathComponent(context.root.documentName(forDocumentPath: context.input))
    })
    public var getDocumentAtPath = Endpoint<String, FirestoreDocument, Void>()
    
    @PATCH
    @AbsolutePath(fromContext: { context in
        context.root.host.appendingPathComponent(context.root.documentName(forDocumentPath: try context.input.document.name.unwrap()))
    })
    @Query(\.options.queryItems)
    @Body(json: \.document)
    public var patchDocument = Endpoint<(document: FirestoreDocument, options: FirestorePatchDocumentOptions), Schema.LocationList, Void>()
}

extension FirestoreInterface {
    func documentName(forDocumentPath path: String) -> String {
        let prefix = "projects/\(projectID)/databases/(default)/documents"
        let path = path
            .trim(prefix: "/", suffix: "/")
            .dropPrefixIfPresent(prefix)
        
        return prefix + "/" + String(String(path).trim(prefix: "/", suffix: "/"))
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
    
    public struct CollectionList: Decodable, PaginatedResponse {
        public var collectionIds: [String]?
        public var nextPageToken: String?
        
        public func convert() throws -> PartialOf<CursorPaginatedList<String>> {
            .init(.init(items: collectionIds, nextCursor: nextPageToken.map(PaginationCursor.string)))
        }
    }
    
    public struct DocumentList: Decodable, PaginatedResponse {
        public var documents: [FirestoreDocument]?
        public var nextPageToken: String?
        
        public func convert() throws -> PartialOf<CursorPaginatedList<FirestoreDocument>> {
            .init(.init(items: documents, nextCursor: nextPageToken.map(PaginationCursor.string)))
        }
    }
}

extension FirestoreInterface {
    public final class Endpoint<Input, Output: Decodable, Options>: BaseHTTPEndpoint<FirestoreInterface, Input, Output, Options> {
        override public func buildRequestBase(
            from input: Input,
            context: BuildRequestContext
        ) throws -> HTTPRequest {
            try super.buildRequestBase(from: input, context: context)
                .header(.authorization(.bearer, context.root.token.unwrap().accessToken))
                .header(.contentType(.json))
        }
        
        override public func decodeOutputBase(
            from response: Request.Response,
            context: DecodeOutputContext
        ) throws -> Output {
            do {
                try response.validate()
            } catch {
                print(context.request.url)
                print(response)
            }
            
            return try response.decode(Output.self, using: JSONDecoder())
        }
    }
}
