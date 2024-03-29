//  Created by Marcell Magyar on 24.02.23.

import Foundation

public final class LocalMovieLoader {
    private let store: MovieStore
    private let currentDate: () -> Date
    
    public init(store: MovieStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalMovieLoader: MovieLoader {
    public typealias LoadResult = MovieLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .success(.some(cache)) where MovieCachePolicy.validate(cache.timestamp, against: self.currentDate()):
                completion(.success(cache.movies.toModels()))
                
            case .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalMovieLoader {
    public typealias SaveResult = Swift.Result<Void, Error>
    
    public func save(_ movies: [Movie], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedMovies { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.cache(movies.toLocals(), completion: completion)
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func cache(_ movies: [LocalMovie], completion: @escaping (SaveResult) -> Void) {
        store.insert(movies, timestamp: currentDate(), completion: { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success:
                completion(.success(()))
                
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }
}

extension LocalMovieLoader {
    public typealias ValidationResult = Swift.Result<Void, Error>
    
    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCachedMovies(completion: completion)
                
            case let .success(.some(cache)) where !MovieCachePolicy.validate(cache.timestamp, against: self.currentDate()):
                self.store.deleteCachedMovies(completion: completion)
                
            case .success:
                completion(.success(()))
            }
        }
    }
}

private extension Array where Element == LocalMovie {
    func toModels() -> [Movie] {
        map { Movie(
            id: $0.id,
            title: $0.title,
            imagePath: $0.imagePath,
            overview: $0.overview,
            releaseDate: $0.releaseDate,
            rating: $0.rating) }
    }
}

private extension Array where Element == Movie {
    func toLocals() -> [LocalMovie] {
        map { LocalMovie(
            id: $0.id,
            title: $0.title,
            imagePath: $0.imagePath,
            overview: $0.overview,
            releaseDate: $0.releaseDate,
            rating: $0.rating) }
    }
}
