//  Created by Marcell Magyar on 02.12.22.

import XCTest
import CinemaTime

protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

final class RemoteMovieLoader {
    private let url: URL
    private let client: HTTPClient
    
    enum Error: Swift.Error {
        case invalidData
    }
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping (MovieLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.failure(Error.invalidData))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

final class RemoteMovieLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_ , client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_requestsDataTwiceFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut , client) = makeSUT(with: url)
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
        
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let expectedError = NSError(domain: "a domain", code: 0)
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: expectedError, when: {
            client.complete(with: expectedError)
        })
    }
    
    func test_load_deliversInvalidDataErrorOnInvalidData() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: RemoteMovieLoader.Error.invalidData, when: {
            client.complete(with: Data("".utf8), statusCode: 200)
        })
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPURLResponse() {
        let (sut, client) = makeSUT()
        
        let invalidStatusCodes = [199, 201, 300, 400, 500]
        
        invalidStatusCodes.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithError: RemoteMovieLoader.Error.invalidData, when: {
                client.complete(with: Data("".utf8), statusCode: statusCode, at: index)
            })
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with url: URL = URL(string: "https://any-url.com")!) -> (RemoteMovieLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteMovieLoader,
        toCompleteWithError expectedError: Error,
        when action: @escaping () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedError) {
            case let (.failure(receivedError as RemoteMovieLoader.Error), (expectedError as RemoteMovieLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            case let (.failure(receivedError as NSError), (expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected failure with \(expectedError), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
        typealias Message = (url: URL, completion: (HTTPClient.Result) -> Void)
        
        var requestedURLs: [URL] { receivedMessages.map { $0.url } }
        
        private(set) var receivedMessages = [Message]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            receivedMessages.append((url, completion))
        }
        
        func complete(with data: Data, statusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            receivedMessages[index].completion(.success((data, response)))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            receivedMessages[index].completion(.failure(error))
        }
    }
}
