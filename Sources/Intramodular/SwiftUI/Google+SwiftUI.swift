//
// Copyright (c) Vatsal Manot
//

import API
import Combine
import SwiftUIX

public struct FirestoreDocumentFieldView: View {
    public let document: FirestoreDocument
    
    public init(document: FirestoreDocument) {
        self.document = document
    }
    
    public var body: some View {
        Form {
            ForEach(Array(document.fields.keysAndValues).sorted(by: { $0.key < $1.key }), id: \.key) { (key, value) in
                Labeled(key) {
                    Text(String(describing: value))
                }
            }
        }
    }
}

public struct FirestoreDocumentList<RowContent: View>: View {
    @StateObject private var data: AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.DocumentList>
    
    private let rowContent: (FirestoreDocument) -> RowContent
    
    public init(
        _ data: @autoclosure @escaping () -> AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.DocumentList>,
        _ rowContent: @escaping (FirestoreDocument) -> RowContent
    ) {
        self._data = .init(wrappedValue: data())
        self.rowContent = rowContent
    }
    
    public var body: some View {
        List(data.latestValue?.documents ?? [], id: \.self) { document in
            rowContent(document)
        }
        .onAppear {
            data.fetchIfNecessary()
        }
    }
}

public struct FirestoreCollectionList: View {
    public let data: AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.CollectionList>
    
    public init(_ data: AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.CollectionList>) {
        self.data = data
    }
    
    public var body: some View {
        List(data.latestValue?.collectionIds ?? [], id: \.self) { collectionId in
            NavigationLink(collectionId) {
                Text(collectionId)
            }
        }
        .onAppear {
            data.fetchIfNecessary()
        }
    }
}
