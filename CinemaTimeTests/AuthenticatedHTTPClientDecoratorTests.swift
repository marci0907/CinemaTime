//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class AuthenticatedHTTPClientDecorator {
    private let decoratee: HTTPClient
    
    init(decoratee: HTTPClient) {
        self.decoratee = decoratee
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        decoratee.get(from: url) { _ in }
    }
}

final class AuthenticatedHTTPClientDecoratorTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = AuthenticatedHTTPClientDecorator(decoratee: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_get_requestsDataFromURL() {
        let url = anyURL()
        let client = HTTPClientSpy()
        let sut = AuthenticatedHTTPClientDecorator(decoratee: client)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
}
