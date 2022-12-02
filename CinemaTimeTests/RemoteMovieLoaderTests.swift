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
        
        let exp = expectation(description: "Wait for completion")
        sut.load { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(expectedError, receivedError)
                
            case .success:
                XCTFail("Expected failure with \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        client.complete(with: expectedError)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversInvalidDataErrorOnInvalidData() {
        let expectedError = RemoteMovieLoader.Error.invalidData
        let (sut, client) = makeSUT()
        
        let exp = expectation(description: "Wait for completion")
        sut.load { result in
            switch result {
            case let .failure(receivedError as RemoteMovieLoader.Error):
                XCTAssertEqual(expectedError, receivedError)
                
            default:
                XCTFail("Expected failure with \(expectedError), got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        client.complete(with: Data("".utf8), statusCode: 200)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversInvalidDataErrorOnNon200HTTPURLResponse() {
        let expectedError = RemoteMovieLoader.Error.invalidData
        let (sut, client) = makeSUT()
        
        let invalidStatusCodes = [199, 201, 300, 400, 500]
        
        invalidStatusCodes.enumerated().forEach { index, errorCode in
            let exp = expectation(description: "Wait for completion")
            
            sut.load { result in
                switch result {
                case let .failure(receivedError as RemoteMovieLoader.Error):
                    XCTAssertEqual(expectedError, receivedError)
                    
                default:
                    XCTFail("Expected failure with \(expectedError), got \(result) instead")
                }
                
                exp.fulfill()
            }
            
            client.complete(with: Data("".utf8), statusCode: errorCode, at: index)
            
            wait(for: [exp], timeout: 1.0)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with url: URL = URL(string: "https://any-url.com")!) -> (RemoteMovieLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMovieLoader(url: url, client: client)
        return (sut, client)
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
