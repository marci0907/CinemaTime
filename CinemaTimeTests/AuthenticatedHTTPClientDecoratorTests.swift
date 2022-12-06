//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class AuthenticatedHTTPClientDecorator: HTTPClient {
    private let decoratee: HTTPClient
    private let apiKey: String
    
    init(decoratee: HTTPClient, apiKey: String) {
        self.decoratee = decoratee
        self.apiKey = apiKey
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        let signedURL = signedURL(from: url)
        
        decoratee.get(from: signedURL, completion: completion)
    }
    
    private func signedURL(from url: URL) -> URL {
        var urlComponents = URLComponents(string: url.absoluteString)!
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + [URLQueryItem(name: "api_key", value: apiKey)]
        
        return urlComponents.url!
    }
}

final class AuthenticatedHTTPClientDecoratorTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_get_signsRequestWithApiKey() {
        let apiKey = "someApiKey"
        let url = anyURL()
        let (sut, client) = makeSUT(with: apiKey)
        
        sut.get(from: url) { _ in }
        
        let signedURL = signedURL(for: url, apiKey: apiKey)
        XCTAssertEqual(client.requestedURLs, [signedURL])
    }
    
    func test_get_signsRequestWithApiKeyWhenOtherQueryItemsArePresent() {
        let apiKey = "someApiKey"
        let url = URL(string: "https://any-url.com?page=1")!
        let (sut, client) = makeSUT(with: apiKey)
        
        sut.get(from: url) { _ in }
        
        let signedURL = signedURLWithQueries(for: url, apiKey: apiKey)
        XCTAssertEqual(client.requestedURLs, [signedURL])
    }
    
    func test_get_deliversErrorOnClientError() {
        let error = anyNSError()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(error), when: {
            client.complete(with: error)
        })
    }
    
    func test_get_deliversDataAndResponseOnClientSuccess() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success((data, response)), when: {
            client.complete(with: data, statusCode: 200)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        with apiKey: String = "someKey",
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut: AuthenticatedHTTPClientDecorator, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client, apiKey: apiKey)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: AuthenticatedHTTPClientDecorator,
        toCompleteWith expectedResult: HTTPClient.Result,
        when action: @escaping () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        sut.get(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success((receivedData, receivedResponse)), .success((expectedData, expectedResponse))):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
                XCTAssertEqual(receivedResponse.statusCode, expectedResponse.statusCode, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
                XCTAssertEqual(receivedError.domain, expectedError.domain, file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func signedURL(for url: URL, apiKey: String) -> URL {
        URL(string: url.absoluteString + "?api_key=\(apiKey)")!
    }
    
    private func signedURLWithQueries(for url: URL, apiKey: String) -> URL {
        URL(string: url.absoluteString + "&api_key=\(apiKey)")!
    }
}
