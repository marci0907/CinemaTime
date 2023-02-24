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
        store.retrieve { result in
            if case let .failure(error) = result {
                completion(.failure(error))
            } else {
                completion(.success([]))
            }
        }
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
        
        func complete(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }
    }
}
