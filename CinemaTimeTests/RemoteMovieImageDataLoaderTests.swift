//  Created by Marcell Magyar on 10.12.22.

import XCTest
import CinemaTime

final class RemoteMovieImageDataLoader {
    private let baseURL: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case invalidData
    }
    
    private struct Task: MovieImageDataLoaderTask {
        func cancel() {}
    }
    
    init(baseURL: URL, client: HTTPClient) {
        self.baseURL = baseURL
        self.client = client
    }
    
    func load(from imagePath: String, completion: @escaping (MovieImageDataLoader.Result) -> Void) -> MovieImageDataLoaderTask {
        let fullImageURL = baseURL.appendingPathComponent(imagePath)
        client.get(from: fullImageURL) { result in
            switch result {
            case let .success((data, response)):
                completion(RemoteImageDataMapper.map(data, response: response))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
        return Task()
    }
}

private class RemoteImageDataMapper {
    private init() {}
    
    static func map(_ data: Data, response: HTTPURLResponse) -> MovieImageDataLoader.Result {
        return .failure(RemoteMovieImageDataLoader.Error.invalidData)
    }
}

final class RemoteMovieImageDataLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestImageFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadFromImagePath_requestImageDataFromURL() {
        let imagePath = "/any.jpg"
        let (sut , client) = makeSUT()
        
        _ = sut.load(from: imagePath) { _ in }
        
        let imageURL = URL(string: baseImageURL().absoluteString + imagePath)!
        XCTAssertEqual(client.requestedURLs, [imageURL])
    }
    
    func test_loadFromImagePath_deliversErrorOnClientError() {
        let error = anyNSError()
        let (sut , client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(error), when: {
            client.complete(with: error)
        })
    }
    
    func test_loadFromImagePath_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let error = RemoteMovieImageDataLoader.Error.invalidData
        let (sut , client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(error), when: {
                client.complete(with: anyData(), statusCode: code, at: index)
            })
        }
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
        toCompleteWith expectedResult: MovieImageDataLoader.Result,
        when action: @escaping () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        _ = sut.load(from: anyImagePath()) { receivedResult in
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
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func baseImageURL() -> URL {
        URL(string: "https://base-url.com")!
    }
    
    private func anyImagePath() -> String {
        "/any.jpg"
    }
}
