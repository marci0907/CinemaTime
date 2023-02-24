//  Created by Marcell Magyar on 24.02.23.

import XCTest
import CinemaTime

protocol MovieStore {
    func retrieve()
}

final class LocalMovieLoader: MovieLoader {
    private let store: MovieStore
    
    init(store: MovieStore) {
        self.store = store
    }
    
    func load(completion: @escaping (MovieLoader.Result) -> Void) {
        store.retrieve()
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
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (MovieLoader, MovieStoreSpy) {
        let spy = MovieStoreSpy()
        let sut = LocalMovieLoader(store: spy)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private class MovieStoreSpy: MovieStore {
        enum Message {
            case retrieve
        }
        
        private(set) var messages = [Message]()
        
        func retrieve() {
            messages.append(.retrieve)
        }
    }
}
