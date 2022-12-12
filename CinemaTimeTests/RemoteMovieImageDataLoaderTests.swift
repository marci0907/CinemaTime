//  Created by Marcell Magyar on 10.12.22.

import XCTest
import CinemaTime

final class RemoteMovieImageDataLoader: MovieImageDataLoader {
    private let baseURL: URL
    private let client: HTTPClient
    
    public typealias Result = MovieImageDataLoader.Result
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    private class HTTPClientTaskWrapper: MovieImageDataLoaderTask {
        var completion: ((HTTPClient.Result) -> Void)?
        
        var wrapped: HTTPClientTask?
        
        init(_ completion: @escaping (HTTPClient.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: HTTPClient.Result) {
            completion?(result)
        }
        
        func cancel() {
            completion = nil
            wrapped?.cancel()
        }
    }
    
    init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }
    
    func load(from imagePath: String, completion: @escaping (Result) -> Void) -> MovieImageDataLoaderTask {
        let task = HTTPClientTaskWrapper { result in
            switch result {
            case let .success((data, response)):
                completion(RemoteImageDataMapper.map(data, response: response))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
        
        let fullImageURL = baseURL.appendingPathComponent(imagePath)
        task.wrapped = client.get(from: fullImageURL) { [weak self] result in
            guard self != nil else { return }
            
            task.complete(with: result)
        }
        
        return task
    }
}

private class RemoteImageDataMapper {
    private init() {}
    
    static func map(_ data: Data, response: HTTPURLResponse) -> RemoteMovieImageDataLoader.Result {
        guard response.statusCode == 200 else {
            return .failure(RemoteMovieImageDataLoader.Error.invalidData)
        }
        
        return .success(data)
    }
}

final class RemoteMovieImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestImageFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadFromImagePath_requestImageDataFromURL() {
        let imagePath = "/any.jpg"
        let (sut, client) = makeSUT()
        
        _ = sut.load(from: imagePath) { _ in }
        
        let imageURL = URL(string: baseImageURL().absoluteString + imagePath)!
        XCTAssertEqual(client.requestedURLs, [imageURL])
    }
    
    func test_loadFromImagePath_deliversErrorOnClientError() {
        let error = anyNSError()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(error), when: { _ in
            client.complete(with: error)
        })
    }
    
    func test_loadFromImagePath_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let error = RemoteMovieImageDataLoader.Error.invalidData
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(error), when: { _ in
                client.complete(with: anyData(), statusCode: code, at: index)
            })
        }
    }
    
    func test_loadFromImagePath_deliversImageDataOn200HTTPReponse() {
        let data = anyData()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success(data), when: { _ in
            client.complete(with: data, statusCode: 200)
        })
    }
    
    func test_cancelingTask_cancelsImageDataLoading() {
        let imagePath = anyImagePath()
        let (sut, client) = makeSUT()
        
        let task = sut.load(from: imagePath) { _ in }
        XCTAssertTrue(client.cancelledURLs.isEmpty)
        
        task.cancel()
        let imageURL = URL(string: baseImageURL().absoluteString + imagePath)!
        XCTAssertEqual(client.cancelledURLs, [imageURL])
    }
    
    func test_cancelingTask_doesNotDeliverImageLoaderResult() {
        let (sut, client) = makeSUT()
        var results = [RemoteMovieImageDataLoader.Result]()
        let task = sut.load(from: anyImagePath()) { results.append($0) }
        
        task.cancel()
        client.complete(with: anyData(), statusCode: 200)
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_loadFromImagePath_doesNotDeliverResultAfterSutHasBeenDeallocated() {
        let client = HTTPClientSpy()
        var sut: RemoteMovieImageDataLoader? = RemoteMovieImageDataLoader(baseURL: baseImageURL(), client: client)
        var results = [RemoteMovieImageDataLoader.Result]()
        _ = sut?.load(from: anyImagePath()) { results.append($0) }
        sut = nil
        
        client.complete(with: anyData(), statusCode: 200)
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with baseURL: URL = URL(string: "https://base-url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (RemoteMovieImageDataLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieImageDataLoader(baseURL: baseURL, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteMovieImageDataLoader,
        toCompleteWith expectedResult: RemoteMovieImageDataLoader.Result,
        when action: @escaping (MovieImageDataLoaderTask) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        let task = sut.load(from: anyImagePath()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action(task)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func baseImageURL() -> URL {
        URL(string: "https://base-url.com")!
    }
    
    private func anyImagePath() -> String {
        "/any.jpg"
    }
}
