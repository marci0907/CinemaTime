//  Created by Marcell Magyar on 02.12.22.

import XCTest

protocol HTTPClient {}

final class RemoteMovieLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
}

final class RemoteMovieLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteMovieLoader(client: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private class HTTPClientSpy: HTTPClient {
        private(set) var requestedURLs = [URL]()
    }
}
