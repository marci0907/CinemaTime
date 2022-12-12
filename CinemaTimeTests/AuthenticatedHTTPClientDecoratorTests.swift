//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class AuthenticatedHTTPClientDecoratorTests: XCTestCase, HTTPClientTest {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_get_signsRequestWithApiKey() {
        let apiKey = "someApiKey"
        let url = anyURL()
        let (sut, client) = makeSUT(with: apiKey)
        
        _ = sut.get(from: url) { _ in }
        
        let signedURL = signedURL(for: url, apiKey: apiKey)
        XCTAssertEqual(client.requestedURLs, [signedURL])
    }
    
    func test_get_signsRequestWithApiKeyWhenOtherQueryItemsArePresent() {
        let apiKey = "someApiKey"
        let url = URL(string: "https://any-url.com?page=1")!
        let (sut, client) = makeSUT(with: apiKey)
        
        _ = sut.get(from: url) { _ in }
        
        let signedURL = signedURLWithQueries(for: url, apiKey: apiKey)
        XCTAssertEqual(client.requestedURLs, [signedURL])
    }
    
    func test_get_deliversErrorOnClientError() {
        let error = anyNSError()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(error), when: { _ in
            client.complete(with: error)
        })
    }
    
    func test_get_deliversDataAndResponseOnClientSuccess() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success((data, response)), when: { _ in
            client.complete(with: data, statusCode: 200)
        })
    }
    
    func test_cancelingTask_cancelsClientTask() {
        let (sut, client) = makeSUT()
        let url = anyURL()
        let task = sut.get(from: url) { _ in }
        
        task.cancel()
        
        XCTAssertEqual(client.cancelledURLs, [signedURL(for: url)])
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
    
    private func signedURL(for url: URL, apiKey: String = "someKey") -> URL {
        URL(string: url.absoluteString + "?api_key=\(apiKey)")!
    }
    
    private func signedURLWithQueries(for url: URL, apiKey: String) -> URL {
        URL(string: url.absoluteString + "&api_key=\(apiKey)")!
    }
}
