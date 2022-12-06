//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class AuthenticatedHTTPClientDecorator {
    private let decoratee: HTTPClient
    private let apiKey: String
    
    init(decoratee: HTTPClient, apiKey: String) {
        self.decoratee = decoratee
        self.apiKey = apiKey
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        let signedURL = signedURL(from: url)
        
        decoratee.get(from: signedURL) { _ in }
    }
    
    private func signedURL(from url: URL) -> URL {
        var urlComponents = URLComponents(string: url.absoluteString)!
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        
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
    
    private func signedURL(for url: URL, apiKey: String) -> URL {
        URL(string: url.absoluteString + "?api_key=\(apiKey)")!
    }
}
