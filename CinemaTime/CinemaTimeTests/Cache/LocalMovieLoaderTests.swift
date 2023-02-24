//  Created by Marcell Magyar on 24.02.23.

import XCTest
import CinemaTime

final class LocalMovieLoaderTests: XCTestCase {
    
    // MARK: - Load
    
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
        
        expect(sut, toFinishLoadingWith: .failure(expectedError), when: {
            store.complete(with: expectedError)
        })
    }
    
    func test_load_deliversZeroMoviesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toFinishLoadingWith: .success([]), when: {
            store.completeWithEmptyCache()
        })
    }
    
    func test_load_deliversMoviesOnNonEmptyNonExpiredCache() {
        let movies = uniqueMovies()
        let currentDate = Date.now
        let nonExpiredTimestamp = currentDate.minusCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toFinishLoadingWith: .success(movies.models), when: {
            store.complete(with: movies.locals, timestamp: nonExpiredTimestamp)
        })
    }
    
    func test_load_deliversZeroMoviesOnCacheExpiration() {
        let movies = uniqueMovies()
        let currentDate = Date.now
        let expirationTimestamp = currentDate.minusCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toFinishLoadingWith: .success([]), when: {
            store.complete(with: movies.locals, timestamp: expirationTimestamp)
        })
    }
    
    func test_load_deliversZeroMoviesOnExpiredCache() {
        let movies = uniqueMovies()
        let currentDate = Date.now
        let expiredTimestamp = currentDate.minusCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        
        expect(sut, toFinishLoadingWith: .success([]), when: {
            store.complete(with: movies.locals, timestamp: expiredTimestamp)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = MovieStoreSpy()
        var sut: LocalMovieLoader? = LocalMovieLoader(store: store, currentDate: Date.init)
        
        var loadCallCount = 0
        sut?.load { _ in loadCallCount += 1 }
        
        sut = nil
        
        store.completeWithEmptyCache()
        
        XCTAssertEqual(loadCallCount, 0)
    }
    
    // MARK: - Save
    
    func test_save_requestsCacheDeletion() {
        let (sut, repo) = makeSUT()
        
        sut.save([]) { _ in }
        
        XCTAssertEqual(repo.messages, [.deleteCachedMovies])
    }
    
    func test_save_doesNotRequestInsertionOnStoreDeletionError() {
        let (sut, repo) = makeSUT()
        
        sut.save([]) { _ in }
        repo.completeDeletion(with: anyNSError())
        
        XCTAssertEqual(repo.messages, [.deleteCachedMovies])
    }
    
    func test_save_requestsInsertionOnSuccessfulCacheDeletion() {
        let movies = uniqueMovies()
        let currentDate = Date.now
        let (sut, repo) = makeSUT(currentDate: { currentDate })
        
        sut.save(movies.models) { _ in }
        repo.completeDeletionSuccessfully()
        
        XCTAssertEqual(repo.messages, [.deleteCachedMovies, .insert(movies.locals, currentDate)])
    }
    
    func test_save_deliversErrorOnDeletionError() {
        let expectedError = anyNSError()
        let (sut, repo) = makeSUT()
        
        expect(sut, toFinishSavingWith: .failure(expectedError), when: {
            repo.completeDeletion(with: expectedError)
        })
    }
    
    func test_save_doesNotDeliverDeletionResultAfterSUTHasBeenDeallocated() {
        let store = MovieStoreSpy()
        var sut: LocalMovieLoader? = LocalMovieLoader(store: store, currentDate: Date.init)
        
        var loadCallCount = 0
        sut?.save([]) { _ in loadCallCount += 1 }
        
        sut = nil
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(loadCallCount, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        currentDate: @escaping () -> Date = { .now },
        file: StaticString = #file,
        line: UInt = #line
    ) -> (LocalMovieLoader, MovieStoreSpy) {
        let spy = MovieStoreSpy()
        let sut = LocalMovieLoader(store: spy, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, spy)
    }
    
    private func expect(
        _ sut: LocalMovieLoader,
        toFinishLoadingWith expectedResult: MovieLoader.Result,
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
    
    private func expect(
        _ sut: LocalMovieLoader,
        toFinishSavingWith expectedResult: LocalMovieLoader.SaveResult,
        when action: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        sut.save(uniqueMovies().models) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, file: file, line: line)
                
            case (.success, .success): break
                
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
        enum Message: Equatable {
            case retrieve
            case insert([LocalMovie], Date)
            case deleteCachedMovies
        }
        
        private(set) var messages = [Message]()
        private var retrievalCompletions = [MovieStore.RetrievalCompletion]()
        private var deletionCompletions = [MovieStore.DeletionCompletion]()
        private var insertionCompletions = [MovieStore.InsertionCompletion]()
        
        // MARK: - Retrieve
        
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
        
        // MARK: - Delete
        
        func deleteCachedMovies(completion: @escaping DeletionCompletion) {
            messages.append(.deleteCachedMovies)
            deletionCompletions.append(completion)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](.success(()))
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](.failure(error))
        }
        
        // MARK: - Insert
        
        func insert(_ movies: [LocalMovie], timestamp: Date, completion: @escaping InsertionCompletion) {
            messages.append(.insert(movies, timestamp))
            insertionCompletions.append(completion)
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
