//  Created by Marcell Magyar on 06.12.22.

import XCTest
import CinemaTime

final class AuthenticatedHTTPClientDecorator {
    private let decoratee: HTTPClient
    
    init(decoratee: HTTPClient) {
        self.decoratee = decoratee
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        
    }
}

final class AuthenticatedHTTPClientDecoratorTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = AuthenticatedHTTPClientDecorator(decoratee: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
}
