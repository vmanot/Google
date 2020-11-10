//
// Copyright (c) Vatsal Manot
//

import API
import Combine
import SwiftUIX

public struct FirestoreDocumentFieldView: View {
    public let document: FirestoreDocument
    
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

public struct FirestoreDocumentList: View {
    @StateObject var data: AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.DocumentList>
    
    public init(_ data: @autoclosure @escaping () -> AnyRepositoryResource<FirestoreProjectRepository, FirestoreInterface.Schema.DocumentList>) {
        self._data = .init(wrappedValue: data())
    }
    
    public var body: some View {
        List(data.latestValue?.documents ?? [], id: \.self) { document in
            NavigationLink(
                destination: VStack {
                    FirestoreDocumentFieldView(document: document)
                    
                    Button("Patch") {
                        data.repository.patch(.init(fields: ["calories": .integerValue("20")]), at: document.name!)
                    }
                    
                    FirestoreCollectionList(data.repository.collectionList(for: document))
                }
            ) {
                Text(document.title)
                    .fixedSize()
            }
        }
        .onAppear {
            data.beginResolutionIfNecessary()
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
            data.beginResolutionIfNecessary()
        }
    }
}
