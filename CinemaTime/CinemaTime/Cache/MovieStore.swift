//  Created by Marcell Magyar on 24.02.23.

import Foundation

public struct CachedMovies {
    public let movies: [LocalMovie]
    public let timestamp: Date
    
    public init(movies: [LocalMovie], timestamp: Date) {
        self.movies = movies
        self.timestamp = timestamp
    }
}

public protocol MovieStore {
    typealias RetrievalCompletion = (Result<CachedMovies?, Error>) -> Void
    
    func retrieve(completion: @escaping RetrievalCompletion)
    
    typealias DeletionResult = Result<Void, Error>
    typealias DeletionCompletion = (DeletionResult) -> Void
    func deleteCachedMovies(completion: @escaping DeletionCompletion)
}
