//  Created by Marcell Magyar on 24.02.23.

import XCTest
import CinemaTime

public struct LocalMovie: Equatable {
    public let id: Int
    public let title: String
    public let imagePath: String?
    public let overview: String?
    public let releaseDate: Date?
    public let rating: Double?
    
    public init(id: Int, title: String, imagePath: String?, overview: String?, releaseDate: Date?, rating: Double?) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
        self.overview = overview
        self.releaseDate = releaseDate
        self.rating = rating
    }
}

struct CachedMovies {
    let movies: [LocalMovie]
    let timestamp: Date
}

protocol MovieStore {
    typealias RetrievalCompletion = (Result<CachedMovies?, Error>) -> Void
    
    func retrieve(completion: @escaping RetrievalCompletion)
}

final class LocalMovieLoader: MovieLoader {
    private let store: MovieStore
    
    init(store: MovieStore) {
        self.store = store
    }
    
    func load(completion: @escaping (MovieLoader.Result) -> Void) {
        store.retrieve { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .success(.some(cache)) where cache.timestamp > Date.now.addingTimeInterval(-7*24*60*60):
                completion(.success(cache.movies.toModels()))
                
            case .success:
                completion(.success([]))
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

final class LocalMovieLoaderTests: XCTestCase {
    
    func test_init_doesNotCallStore() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.messages.isEmpty)
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load() { _ in }
        
        XCTAssertEqual(store.messages, [.retrieve])
    }
    
    func test_load_deliversErrorOnStoreError() {
        let expectedError = anyNSError()
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishWith: .failure(expectedError), when: {
            store.complete(with: expectedError)
        })
    }
    
    func test_load_deliversZeroMoviesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishWith: .success([]), when: {
            store.completeWithEmptyCache()
        })
    }
    
    func test_load_deliversMoviesOnNonEmptyNonExpiredCache() {
        let movies = uniqueMovies()
        let nonExpiredTimestamp = Date.now.minusCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishWith: .success(movies.models), when: {
            store.complete(with: movies.locals, timestamp: nonExpiredTimestamp)
        })
    }
    
    func test_load_deliversZeroMoviesOnCacheExpiration() {
        let movies = uniqueMovies()
        let expirationTimestamp = Date.now.minusCacheMaxAge()
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishWith: .success([]), when: {
            store.complete(with: movies.locals, timestamp: expirationTimestamp)
        })
    }
    
    func test_load_deliversZeroMoviesOnExpiredCache() {
        let movies = uniqueMovies()
        let expiredTimestamp = Date.now.minusCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishWith: .success([]), when: {
            store.complete(with: movies.locals, timestamp: expiredTimestamp)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = MovieStoreSpy()
        var sut: LocalMovieLoader? = LocalMovieLoader(store: store)
        
        var loadCallCount = 0
        sut?.load { _ in loadCallCount += 1 }
        
        sut = nil
        
        store.completeWithEmptyCache()
        
        XCTAssertEqual(loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (MovieLoader, MovieStoreSpy) {
        let spy = MovieStoreSpy()
        let sut = LocalMovieLoader(store: spy)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private func expect(
        _ sut: MovieLoader,
        toFinishWith expectedResult: MovieLoader.Result,
        when action: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedMovies), .success(expectedMovies)):
                XCTAssertEqual(receivedMovies, expectedMovies, file: file, line: line)
                
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func uniqueMovie() -> Movie {
        Movie(
            id: (0...100000).randomElement()!,
            title: "any title",
            imagePath: nil,
            overview: nil,
            releaseDate: nil,
            rating: nil)
    }
    
    private func uniqueMovies() -> (models: [Movie], locals: [LocalMovie]) {
        let models = [uniqueMovie(), uniqueMovie(), uniqueMovie()]
        let locals = models.map { LocalMovie(
            id: $0.id,
            title: $0.title,
            imagePath: $0.imagePath,
            overview: $0.overview,
            releaseDate: $0.releaseDate,
            rating: $0.rating) }
        return (models, locals)
    }
    
    private class MovieStoreSpy: MovieStore {
        enum Message {
            case retrieve
        }
        
        private(set) var messages = [Message]()
        private var retrievalCompletions = [MovieStore.RetrievalCompletion]()
        
        func retrieve(completion: @escaping MovieStore.RetrievalCompletion) {
            messages.append(.retrieve)
            retrievalCompletions.append(completion)
        }
        
        func completeWithEmptyCache(at index: Int = 0) {
            retrievalCompletions[index](.success(.none))
        }
        
        func complete(with movies: [LocalMovie], timestamp: Date, at index: Int = 0) {
            retrievalCompletions[index](.success(.some(CachedMovies(movies: movies, timestamp: timestamp))))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }
    }
}

private extension Date {
    var moviesCacheMaxAgeInDays: Int { 7 }
    
    func minusCacheMaxAge() -> Date {
        adding(days: -moviesCacheMaxAgeInDays)
    }
    
    func adding(seconds: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .second, value: seconds, to: self)!
    }
    
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}
